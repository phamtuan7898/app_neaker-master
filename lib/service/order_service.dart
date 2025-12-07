import 'dart:async';
import 'dart:convert';
import 'package:app_neaker/constants/config.dart';
import 'package:app_neaker/models/order_model.dart';
import 'package:http/http.dart' as http;

class OrderService {
  final http.Client _client;
  // Sử dụng từ AppConfig
  String get _baseUrl => AppConfig.baseUrl;
  Duration get _timeout => Duration(seconds: AppConfig.apiTimeout);

  OrderService({http.Client? client}) : _client = client ?? http.Client();

  // Fetch list orders
  Future<List<Order>> fetchOrders(String userId) async {
    final endpoint = '$_baseUrl/api/orders/$userId';

    return _handleRequest(
      request: () => _client.get(Uri.parse(endpoint)).timeout(_timeout),
      parser: (responseBody) {
        final List jsonResponse = json.decode(responseBody);
        return jsonResponse.map((e) => Order.fromJson(e)).toList();
      },
      errorMessage: 'Failed to load orders',
    );
  }

  // Fetch single order
  Future<Order> fetchOrderDetails(String userId, String orderId) async {
    final endpoint = '$_baseUrl/api/orders/$userId/$orderId';

    return _handleRequest(
      request: () => _client.get(Uri.parse(endpoint)).timeout(_timeout),
      parser: (responseBody) => Order.fromJson(json.decode(responseBody)),
      errorMessage: 'Failed to load order details',
    );
  }

  // Generic Request Handler
  Future<T> _handleRequest<T>({
    required Future<http.Response> Function() request,
    required T Function(String responseBody) parser,
    required String errorMessage,
  }) async {
    try {
      final response = await request();

      if (response.statusCode == 200) {
        return parser(response.body);
      } else {
        throw HttpException(
          statusCode: response.statusCode,
          message: '${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      throw ApiTimeoutException('Request timeout: $e');
    } on FormatException catch (e) {
      throw JsonParseException('Invalid JSON format: $e');
    } on http.ClientException catch (e) {
      throw NetworkException('Client error: $e');
    } catch (e) {
      throw Exception('$errorMessage: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

// Exceptions

class HttpException implements Exception {
  final int statusCode;
  final String message;

  HttpException({required this.statusCode, required this.message});

  @override
  String toString() => 'HttpException(status: $statusCode, message: $message)';
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
