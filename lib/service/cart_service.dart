import 'dart:async';
import 'dart:convert';
import 'package:app_neaker/constants/config.dart';
import 'package:app_neaker/models/carts_model.dart';
import 'package:app_neaker/models/products_model.dart';
import 'package:app_neaker/service/product_service.dart';
import 'package:http/http.dart' as http;

class CartService {
  // Sử dụng từ AppConfig
  String get _baseUrl => AppConfig.baseUrl;
  Duration get _timeout => Duration(seconds: AppConfig.apiTimeout);

  final ProductService _productService;
  final http.Client _client;

  // Constructor với dependency injection
  CartService({
    ProductService? productService,
    http.Client? client,
  })  : _productService = productService ?? ProductService(),
        _client = client ?? http.Client();

  // Getter để truy cập baseUrl từ bên ngoài nếu cần
  String get baseUrl => _baseUrl;

  // Headers chung
  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
      };

  // Normalize ID
  String normalizeId(String id) {
    return id.replaceAll('"', '').trim();
  }

  // Helper method để parse price
  double parsePrice(String price) {
    String cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');
    return double.parse(cleanPrice);
  }

  // -------------------------
  //  Generic Request Handler
  // -------------------------
  Future<T> _handleRequest<T>({
    required Future<http.Response> Function() request,
    required T Function(http.Response response) parser,
    required String operation,
  }) async {
    try {
      final response = await request().timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return parser(response);
      }

      throw CartServiceException(
        message: 'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
        operation: operation,
      );
    } on TimeoutException {
      throw CartServiceException(
        message: 'Request timeout',
        operation: operation,
      );
    } on http.ClientException catch (e) {
      throw CartServiceException(
        message: 'Network error: $e',
        operation: operation,
      );
    } catch (e) {
      if (e is CartServiceException) rethrow;
      throw CartServiceException(
        message: e.toString(),
        operation: operation,
      );
    }
  }

  // -------------------------
  //  Add Cart Item
  // -------------------------
  Future<void> addCartItem(String userId, CartItem cartItem) async {
    try {
      final products = await _productService.fetchProducts();
      final product = products.firstWhere(
        (p) => p.id == cartItem.productId,
        orElse: () => throw CartServiceException(
          message: 'Product not found for ID: ${cartItem.productId}',
          operation: 'addCartItem',
        ),
      );

      final imageUrl = product.image.isNotEmpty ? product.image[0] : '';

      await _handleRequest(
        request: () => _client.post(
          Uri.parse('$_baseUrl/api/cart'),
          headers: _jsonHeaders,
          body: json.encode({
            ...cartItem.toJson(),
            'userId': normalizeId(userId),
            'image': imageUrl,
          }),
        ),
        parser: (_) => null,
        operation: 'addCartItem',
      );
    } catch (e) {
      if (e is CartServiceException) rethrow;
      throw CartServiceException(
        message: 'Failed to add cart item: $e',
        operation: 'addCartItem',
      );
    }
  }

  // Thêm method này trong class CartService
  Future<T> _handleAsyncRequest<T>({
    required Future<http.Response> Function() request,
    required Future<T> Function(http.Response response)
        parser, // Thay đổi ở đây
    required String operation,
  }) async {
    try {
      final response = await request().timeout(_timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return await parser(response); // Thêm await ở đây
      }

      throw CartServiceException(
        message: 'HTTP ${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
        operation: operation,
      );
    } on TimeoutException {
      throw CartServiceException(
        message: 'Request timeout',
        operation: operation,
      );
    } on http.ClientException catch (e) {
      throw CartServiceException(
        message: 'Network error: $e',
        operation: operation,
      );
    } catch (e) {
      if (e is CartServiceException) rethrow;
      throw CartServiceException(
        message: e.toString(),
        operation: operation,
      );
    }
  }

// Cập nhật fetchCartItems sử dụng method mới
  Future<List<CartItem>> fetchCartItems(String userId) async {
    return await _handleAsyncRequest<List<CartItem>>(
      request: () => _client.get(
        Uri.parse('$_baseUrl/api/cart/${normalizeId(userId)}'),
      ),
      parser: (response) async {
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
      },
      operation: 'fetchCartItems',
    );
  }

  // -------------------------
  //  Remove Cart Item
  // -------------------------
  Future<void> removeCartItem(String userId, String itemId) async {
    final normalizedUserId = normalizeId(userId);
    final normalizedItemId = normalizeId(itemId);

    await _handleRequest(
      request: () => _client.delete(
        Uri.parse('$_baseUrl/api/cart/$normalizedUserId/$normalizedItemId'),
      ),
      parser: (_) => null,
      operation: 'removeCartItem',
    );
  }

  // -------------------------
  //  Update Cart Item Quantity
  // -------------------------
  Future<void> updateCartItemQuantity(
    String userId,
    String itemId,
    int newQuantity,
  ) async {
    final normalizedUserId = normalizeId(userId);
    final normalizedItemId = normalizeId(itemId);

    await _handleRequest(
      request: () => _client.put(
        Uri.parse('$_baseUrl/api/cart/$normalizedUserId/$normalizedItemId'),
        headers: _jsonHeaders,
        body: json.encode({'quantity': newQuantity}),
      ),
      parser: (_) => null,
      operation: 'updateCartItemQuantity',
    );
  }

  // -------------------------
  //  Process Payment (Multiple Items)
  // -------------------------
  Future<bool> processPayment(
    String userId,
    List<CartItem> items,
    double totalAmount,
    String phone,
    String address,
  ) async {
    final normalizedUserId = normalizeId(userId);

    return _handleRequest<bool>(
      request: () => _client.post(
        Uri.parse('$_baseUrl/api/orders/process-payment/$normalizedUserId'),
        headers: _jsonHeaders,
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
      ),
      parser: (_) => true,
      operation: 'processPayment',
    );
  }

  // -------------------------
  //  Process Single Item Payment
  // -------------------------
  Future<bool> processSingleItemPayment(
    String userId,
    CartItem item,
    String phone,
    String address,
  ) async {
    final normalizedUserId = normalizeId(userId);

    return _handleRequest<bool>(
      request: () => _client.post(
        Uri.parse(
            '$_baseUrl/api/orders/process-single-payment/$normalizedUserId'),
        headers: _jsonHeaders,
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
      ),
      parser: (_) => true,
      operation: 'processSingleItemPayment',
    );
  }

  // -------------------------
  //  Clean Up
  // -------------------------
  void dispose() {
    _client.close();
    _productService.dispose();
  }
}

// -------------------------
//  Custom Exception Class
// -------------------------
class CartServiceException implements Exception {
  final String message;
  final int? statusCode;
  final String operation;

  CartServiceException({
    required this.message,
    this.statusCode,
    required this.operation,
  });

  @override
  String toString() =>
      'CartServiceException($operation): $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
