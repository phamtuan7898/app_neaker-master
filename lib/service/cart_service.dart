import 'dart:async';
import 'dart:convert';
import 'package:app_neaker/models/carts_model.dart';
import 'package:app_neaker/models/products_model.dart';
import 'package:app_neaker/service/product_service.dart';
import 'package:http/http.dart' as http;

class CartService {
  static const String apiUrl = 'http://192.168.1.16:5002';
  static const Duration timeoutDuration = Duration(seconds: 30);

  final ProductService _productService = ProductService();

  String normalizeId(String id) {
    return id.replaceAll('"', '').trim();
  }

  Future<void> addCartItem(String userId, CartItem cartItem) async {
    try {
      final products = await _productService.fetchProducts();
      final product = products.firstWhere(
        (p) => p.id == cartItem.productId,
        orElse: () =>
            throw Exception('Product not found for ID: ${cartItem.productId}'),
      );

      final imageUrl = product.image.isNotEmpty ? product.image[0] : '';

      final response = await http
          .post(
            Uri.parse('$apiUrl/api/cart'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              ...cartItem.toJson(),
              'userId': normalizeId(userId),
              'image': imageUrl,
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw HttpException(
            'Failed to add cart item', response.statusCode, response.body);
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: $e');
    } catch (e) {
      throw Exception('Failed to add cart item: $e');
    }
  }

  Future<List<CartItem>> fetchCartItems(String userId) async {
    try {
      final normalizedUserId = normalizeId(userId);
      final response = await http
          .get(
            Uri.parse('$apiUrl/api/cart/$normalizedUserId'),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        final products = await _productService.fetchProducts();

        final cartItems = <CartItem>[];

        for (final item in jsonResponse) {
          try {
            final product = products.firstWhere(
              (p) => p.id == item['productId'],
              orElse: () => ProductModel(
                id: '',
                productName: '',
                shoeType: '',
                image: [],
                price: '0',
                rating: 0,
                description: '',
                color: [],
                size: [],
              ),
            );

            final imageUrl = product.image.isNotEmpty ? product.image[0] : '';
            final cartItem = CartItem.fromJson({
              ...item,
              'image': imageUrl,
            });
            cartItems.add(cartItem);
          } catch (e) {
            print(
                'Warning: Failed to process cart item ${item['productId']}: $e');
            continue;
          }
        }

        return cartItems;
      } else {
        throw HttpException(
            'Failed to load cart items', response.statusCode, response.body);
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: $e');
    } catch (e) {
      throw Exception('Failed to load cart items: $e');
    }
  }

  Future<void> removeCartItem(String userId, String itemId) async {
    try {
      final normalizedUserId = normalizeId(userId);
      final normalizedItemId = normalizeId(itemId);

      final response = await http
          .delete(
            Uri.parse('$apiUrl/api/cart/$normalizedUserId/$normalizedItemId'),
          )
          .timeout(timeoutDuration);

      if (response.statusCode != 200) {
        throw HttpException(
            'Failed to delete cart item', response.statusCode, response.body);
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: $e');
    } catch (e) {
      throw Exception('Failed to delete cart item: $e');
    }
  }

  Future<void> updateCartItemQuantity(
    String userId,
    String itemId,
    int newQuantity,
  ) async {
    try {
      final normalizedUserId = normalizeId(userId);
      final normalizedItemId = normalizeId(itemId);

      final response = await http
          .put(
            Uri.parse('$apiUrl/api/cart/$normalizedUserId/$normalizedItemId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'quantity': newQuantity}),
          )
          .timeout(timeoutDuration);

      if (response.statusCode != 200) {
        throw HttpException('Failed to update cart item quantity',
            response.statusCode, response.body);
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: $e');
    } on TimeoutException catch (e) {
      throw Exception('Request timeout: $e');
    } catch (e) {
      throw Exception('Failed to update cart item quantity: $e');
    }
  }

  Future<bool> processPayment(
    String userId,
    List<CartItem> items,
    double totalAmount,
    String phone,
    String address,
  ) async {
    try {
      final normalizedUserId = normalizeId(userId);

      final response = await http
          .post(
            Uri.parse('$apiUrl/api/orders/process-payment/$normalizedUserId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'items': items
                  .map((item) => {
                        'productId': item.productId,
                        'productName': item.productName,
                        'price': item.price,
                        'quantity': item.quantity,
                        'size': item.size,
                        'color': item.color,
                        'image': item.image,
                      })
                  .toList(),
              'totalAmount': totalAmount,
              'phone': phone.trim(),
              'address': address.trim(),
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw HttpException(
            'Payment failed', response.statusCode, response.body);
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error during payment: $e');
    } on TimeoutException catch (e) {
      throw Exception('Payment request timeout: $e');
    } catch (e) {
      throw Exception('Payment processing failed: $e');
    }
  }

  // THÊM: Phương thức thanh toán từng sản phẩm
  Future<bool> processSingleItemPayment(
    String userId,
    CartItem item,
    String phone,
    String address,
  ) async {
    try {
      final normalizedUserId = normalizeId(userId);

      final response = await http
          .post(
            Uri.parse(
                '$apiUrl/api/orders/process-single-payment/$normalizedUserId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'item': {
                'productId': item.productId,
                'productName': item.productName,
                'price': item.price,
                'quantity': item.quantity,
                'size': item.size,
                'color': item.color,
                'image': item.image,
              },
              'totalAmount': parsePrice(item.price) * item.quantity,
              'phone': phone.trim(),
              'address': address.trim(),
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw HttpException(
            'Single item payment failed', response.statusCode, response.body);
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error during single item payment: $e');
    } on TimeoutException catch (e) {
      throw Exception('Single item payment request timeout: $e');
    } catch (e) {
      throw Exception('Single item payment processing failed: $e');
    }
  }

  // Helper method để parse price
  double parsePrice(String price) {
    String cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');
    return double.parse(cleanPrice);
  }

  // Thêm getter để truy cập apiUrl từ bên ngoài nếu cần
  String get baseUrl => apiUrl;
}

class HttpException implements Exception {
  final String message;
  final int statusCode;
  final String responseBody;

  HttpException(this.message, this.statusCode, this.responseBody);

  @override
  String toString() {
    return '$message (Status: $statusCode) - Response: $responseBody';
  }
}
