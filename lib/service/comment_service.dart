import 'dart:async';
import 'dart:convert';
import 'package:app_neaker/constants/config.dart';
import 'package:app_neaker/models/comment_model.dart';
import 'package:http/http.dart' as http;

class CommentService {
  // Sử dụng từ AppConfig
  String get _baseUrl => AppConfig.baseUrl;
  Duration get _timeout => Duration(seconds: AppConfig.apiTimeout);

  static const String _commentsEndpoint = 'api/comments';

  final http.Client _client;

  // Dependency injection với khởi tạo từ .env
  CommentService({http.Client? client}) : _client = client ?? http.Client();

  // Đóng client khi không cần thiết
  void close() {
    _client.close();
  }

  Future<CommentModel> addComment({
    required String productId,
    required String userId,
    required String username,
    required String comment,
    required double rating,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/$_commentsEndpoint'),
            headers: _headers,
            body: _encodeRequestBody({
              'productId': productId,
              'userId': userId,
              'username': username,
              'comment': comment,
              'rating': rating,
            }),
          )
          .timeout(_timeout);

      return _handleResponse(
        response,
        successCallback: () => CommentModel.fromJson(_decodeResponse(response)),
        errorMessage: 'Failed to add comment',
      );
    } on TimeoutException {
      throw HttpException(
        message: 'Request timeout while adding comment',
        statusCode: 408,
      );
    } catch (e) {
      _logError('Adding comment', e);
      throw _createException('Failed to add comment', e);
    }
  }

  Future<List<CommentModel>> getComments(String productId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/$_commentsEndpoint/$productId'),
          )
          .timeout(_timeout);

      return _handleResponse(
        response,
        successCallback: () {
          final List<dynamic> jsonResponse = _decodeResponse(response);
          return jsonResponse
              .map((comment) => CommentModel.fromJson(comment))
              .toList();
        },
        errorMessage: 'Failed to load comments',
      );
    } on TimeoutException {
      throw HttpException(
        message: 'Request timeout while fetching comments',
        statusCode: 408,
      );
    } catch (e) {
      _logError('Fetching comments', e);
      throw _createException('Failed to load comments', e);
    }
  }

  // Helper methods
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  String _encodeRequestBody(Map<String, dynamic> body) {
    return json.encode(body);
  }

  dynamic _decodeResponse(http.Response response) {
    return json.decode(response.body);
  }

  T _handleResponse<T>(
    http.Response response, {
    required T Function() successCallback,
    required String errorMessage,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return successCallback();
    } else {
      throw HttpException(
        message: '$errorMessage: ${response.body}',
        statusCode: response.statusCode,
      );
    }
  }

  void _logError(String operation, Object error) {
    print('Error $operation: $error');
  }

  Exception _createException(String message, Object error) {
    if (error is HttpException) {
      return error;
    }
    return Exception('$message: ${error.toString()}');
  }
}

// Custom exception class for better error handling
class HttpException implements Exception {
  final String message;
  final int? statusCode;

  HttpException({required this.message, this.statusCode});

  @override
  String toString() {
    return statusCode != null
        ? 'HttpException[$statusCode]: $message'
        : 'HttpException: $message';
  }
}
