import 'dart:async';
import 'dart:convert';
import 'package:app_neaker/constants/config.dart';
import 'package:app_neaker/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart' as prefs;

class AuthService {
  // Sử dụng từ AppConfig
  String get _baseUrl => AppConfig.baseUrl;
  Duration get _timeout => Duration(seconds: AppConfig.apiTimeout);

  static const String _userKey = 'current_user';
  static const String _contentType = 'application/json';

  static UserModel? _currentUser;
  static prefs.SharedPreferences? _preferences;

  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  // Initialize preferences
  Future<void> _initPreferences() async {
    _preferences ??= await prefs.SharedPreferences.getInstance();
  }

  // Get current user with caching
  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    await _initPreferences();
    final String? userData = _preferences!.getString(_userKey);

    if (userData != null) {
      try {
        _currentUser = UserModel.fromMap(json.decode(userData));
        return _currentUser;
      } catch (e) {
        print('Error parsing stored user data: $e');
        await _preferences!.remove(_userKey);
      }
    }
    return null;
  }

  // Generic HTTP POST request helper with timeout
  Future<Map<String, dynamic>> _postRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      print('🌐 Making request to: $_baseUrl$endpoint');

      // Headers cho Flutter Web
      Map<String, String> headers = {
        'Content-Type': _contentType,
        'Accept': 'application/json',
      };

      // THÊM Origin header cho Flutter Web
      if (kIsWeb) {
        headers['Origin'] = 'http://localhost:59500'; // Flutter Web dev server
      }

      final response = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: headers, // Sử dụng headers mới
            body: json.encode(body),
          )
          .timeout(_timeout);

      print('✅ Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw Exception(responseData['error'] ??
            responseData['message'] ??
            'Request failed with status ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timeout');
    } on http.ClientException catch (e) {
      print('❌ ClientException: $e');
      print('URI: ${e.uri}');
      print('Message: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      rethrow;
    }
  }

  // Login method
  Future<UserModel> login(String usernameOrEmail, String password) async {
    print('🔐 Attempting login...');
    print('Username/Email: $usernameOrEmail');

    // CHỈ GỬI MỘT TRƯỜNG - không gửi cả email và username
    final Map<String, dynamic> requestBody = {
      'password': password,
    };

    // Chỉ thêm email hoặc username, không cả hai
    if (usernameOrEmail.contains('@')) {
      requestBody['email'] = usernameOrEmail;
    } else {
      requestBody['username'] = usernameOrEmail;
    }

    final userData = await _postRequest(
      '/api/users/login',
      requestBody,
    );

    print('✅ Login successful, user data: $userData');

    _currentUser = UserModel.fromMap(userData);
    await _storeUserData(userData);

    return _currentUser!;
  }

  // Register method
  Future<void> register(
    String username,
    String password,
    String email, {
    String img = '',
    String phone = '',
    String address = '',
  }) async {
    await _postRequest(
      '/api/users/register',
      {
        'username': username,
        'password': password,
        'email': email,
        'img': img,
        'phone': phone,
        'address': address,
      },
    );
  }

  // Check user existence
  Future<Map<String, dynamic>> checkUser(String emailOrUsername) async {
    return await _postRequest(
      '/api/users/check-user',
      {'emailOrUsername': emailOrUsername},
    );
  }

  // Reset password
  Future<void> resetPassword(String userId, String newPassword) async {
    await _postRequest(
      '/api/users/reset-password',
      {'userId': userId, 'newPassword': newPassword},
    );
  }

  // Forgot password
  Future<void> forgotPassword(String email) async {
    await _postRequest(
      '/api/users/forgot-password',
      {'email': email},
    );
  }

  // Update stored user data
  Future<void> updateStoredUserData(UserModel updatedUser) async {
    _currentUser = updatedUser;
    await _storeUserData(updatedUser.toMap());
  }

  // Helper method to store user data
  Future<void> _storeUserData(Map<String, dynamic> userData) async {
    await _initPreferences();
    await _preferences!.setString(_userKey, json.encode(userData));
  }

  // Logout method
  Future<void> logout() async {
    await _initPreferences();
    await _preferences!.remove(_userKey);
    _currentUser = null;
  }

  // Clear cache (for testing or memory management)
  void clearCache() {
    _currentUser = null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
}
