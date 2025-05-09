import 'dart:convert';
import 'package:app_neaker/models/carts_model.dart';
import 'package:app_neaker/models/products_model.dart';
import 'package:app_neaker/service/product_service.dart';
import 'package:http/http.dart' as http;

class CartService {
  final String apiUrl = 'http://192.168.1.11:5002';
  final ProductService _productService = ProductService();

  // Helper method to handle MongoDB ObjectId conversion
  String normalizeId(String id) {
    return id.replaceAll('"', '').trim();
  }

  Future<void> addCartItem(String userId, CartItem cartItem) async {
    try {
      // Lấy thông tin sản phẩm từ ProductService để lấy mảng image
      final products = await _productService.fetchProducts();
      final product = products.firstWhere(
        (p) => p.id == cartItem.productId,
        orElse: () =>
            throw Exception('Product not found for ID: ${cartItem.productId}'),
      );

      // Lấy URL hình ảnh đầu tiên từ mảng image
      final imageUrl = product.image.isNotEmpty ? product.image[0] : '';

      final response = await http.post(
        Uri.parse('$apiUrl/cart'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          ...cartItem.toJson(),
          'userId': normalizeId(userId),
          'image': imageUrl, // Gửi URL hình ảnh đầu tiên
        }),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to add cart item: ${response.body}');
      }
    } catch (e) {
      print('Error adding cart item: $e');
      throw Exception('Failed to add cart item');
    }
  }

  Future<List<CartItem>> fetchCartItems(String userId) async {
    try {
      final normalizedUserId = normalizeId(userId);
      final response = await http.get(
        Uri.parse('$apiUrl/cart/$normalizedUserId'),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        // Lấy danh sách sản phẩm từ ProductService
        final products = await _productService.fetchProducts();

        return jsonResponse.map((item) {
          // Tìm sản phẩm tương ứng với productId
          final product = products.firstWhere(
            (p) => p.id == item['productId'],
            orElse: () => ProductModel(
              id: '',
              productName: '',
              shoeType: '',
              image: [], // Mảng rỗng nếu không tìm thấy
              price: '0',
              rating: 0,
              description: '',
              color: [],
              size: [],
            ),
          );

          // Thêm URL hình ảnh đầu tiên từ mảng image của sản phẩm
          final imageUrl = product.image.isNotEmpty ? product.image[0] : '';
          return CartItem.fromJson({
            ...item,
            'image': imageUrl, // Gán URL hình ảnh
          });
        }).toList();
      } else {
        throw Exception('Failed to load cart items: ${response.body}');
      }
    } catch (e) {
      print('Error fetching cart items: $e');
      throw Exception('Failed to load cart items');
    }
  }

  Future<void> removeCartItem(String userId, String itemId) async {
    try {
      final response = await http.delete(
        Uri.parse('$apiUrl/cart/$userId/$itemId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete cart item: ${response.body}');
      }
    } catch (e) {
      print('Error deleting cart item: $e');
      throw Exception('Failed to delete cart item');
    }
  }

  Future<void> updateCartItemQuantity(
    String userId,
    String itemId,
    int newQuantity,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$apiUrl/cart/$userId/$itemId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quantity': newQuantity}),
      );

      if (response.statusCode != 200) {
        print('Server response: ${response.body}');
        throw Exception(
            'Failed to update cart item quantity: ${response.body}');
      }
    } catch (e) {
      print('Error updating cart item quantity: $e');
      throw Exception('Failed to update cart item quantity');
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
      final response = await http.post(
        Uri.parse('$apiUrl/process-payment/$userId'),
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
                    'image': item.image, // Gửi URL hình ảnh
                  })
              .toList(),
          'totalAmount': totalAmount,
          'phone': phone,
          'address': address,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Payment failed: ${response.body}');
      }
    } catch (e) {
      print('Error processing payment: $e');
      throw Exception('Payment processing failed');
    }
  }
}
