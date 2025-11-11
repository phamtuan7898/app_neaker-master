import 'dart:convert';
import 'package:app_neaker/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart' as prefs;

class AuthService {
  static const String _apiUrl = 'http://192.168.1.16:5002';
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

  // Generic HTTP POST request helper
  Future<Map<String, dynamic>> _postRequest(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$_apiUrl$endpoint'),
      headers: {'Content-Type': _contentType},
      body: json.encode(body),
    );

    final responseData = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      throw Exception(
          responseData['error'] ?? responseData['message'] ?? 'Request failed');
    }
  }

  // Login method
  Future<UserModel> login(String usernameOrEmail, String password) async {
    final userData = await _postRequest(
      '/api/users/login',
      {'username': usernameOrEmail, 'password': password},
    );

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
