import 'dart:async';
import 'dart:convert';
import 'package:app_neaker/models/order_model.dart';
import 'package:http/http.dart' as http;

class OrderService {
  static const String _baseUrl = 'http://192.168.1.16:5002';
  static const String _apiPath = 'api/orders';
  static const Duration _timeoutDuration = Duration(seconds: 30);

  final http.Client _client;

  // Dependency injection để dễ dàng testing
  OrderService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Order>> fetchOrders(String userId) async {
    return _handleRequest(
      request: () => _client
          .get(
            Uri.parse('$_baseUrl/$_apiPath/$userId'),
          )
          .timeout(_timeoutDuration),
      successMessage: 'Fetched Orders successfully',
      errorMessage: 'Failed to load orders',
      parser: (responseBody) {
        final List<dynamic> jsonResponse = json.decode(responseBody);
        return jsonResponse.map((order) => Order.fromJson(order)).toList();
      },
    );
  }

  Future<Order> fetchOrderDetails(String userId, String orderId) async {
    return _handleRequest(
      request: () => _client
          .get(
            Uri.parse('$_baseUrl/$_apiPath/$userId/$orderId'),
          )
          .timeout(_timeoutDuration),
      successMessage: 'Fetched Order details successfully',
      errorMessage: 'Failed to load order details',
      parser: (responseBody) => Order.fromJson(json.decode(responseBody)),
    );
  }

  // Generic request handler để tránh code trùng lặp
  Future<T> _handleRequest<T>({
    required Future<http.Response> Function() request,
    required String errorMessage,
    required T Function(String responseBody) parser,
    String? successMessage,
  }) async {
    try {
      final response = await request();

      if (response.statusCode == 200) {
        _printIfNotNull(successMessage);
        return parser(response.body);
      } else {
        throw HttpException(
          statusCode: response.statusCode,
          message: '$errorMessage: ${response.body}',
        );
      }
    } on http.ClientException catch (e) {
      print('Network error: $e');
      throw NetworkException('Network error occurred: $e');
    } on TimeoutException catch (e) {
      print('Request timeout: $e');
      throw ApiTimeoutException('Request timeout occurred: $e');
    } on FormatException catch (e) {
      print('JSON parsing error: $e');
      throw JsonParseException('Invalid JSON format: $e');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('$errorMessage: $e');
    }
  }

  // Helper method để in thông báo nếu không null
  void _printIfNotNull(String? message) {
    if (message != null) {
      print(message);
    }
  }

  // Đóng client khi không cần thiết
  void dispose() {
    _client.close();
  }
}

// Custom exceptions cho xử lý lỗi chi tiết hơn
class HttpException implements Exception {
  final int statusCode;
  final String message;

  HttpException({required this.statusCode, required this.message});

  @override
  String toString() =>
      'HttpException(statusCode: $statusCode, message: $message)';
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ApiTimeoutException implements Exception {
  final String message;

  ApiTimeoutException(this.message);

  @override
  String toString() => 'ApiTimeoutException: $message';
}

class JsonParseException implements Exception {
  final String message;

  JsonParseException(this.message);

  @override
  String toString() => 'JsonParseException: $message';
}
