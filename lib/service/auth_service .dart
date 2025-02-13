import 'dart:convert';
import 'package:app_neaker/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart' as prefs;

class AuthService {
  final String apiUrl = 'http://192.168.1.8:5002';
  static const String USER_KEY = 'current_user';
  static UserModel? _currentUser;

  // Get the currently logged in user
  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    final prefs.SharedPreferences preferences =
        await prefs.SharedPreferences.getInstance();
    final String? userData = preferences.getString(USER_KEY);

    if (userData != null) {
      try {
        _currentUser = UserModel.fromMap(json.decode(userData));
        return _currentUser;
      } catch (e) {
        print('Error parsing stored user data: $e');
        await preferences.remove(USER_KEY);
      }
    }
    return null;
  }

  // Modified login method to save user data
  Future<UserModel> login(String usernameOrEmail, String password) async {
    final response = await http.post(
      Uri.parse('$apiUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': usernameOrEmail,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      _currentUser = UserModel.fromMap(userData);

      // Save user data to SharedPreferences
      final prefs.SharedPreferences preferences =
          await prefs.SharedPreferences.getInstance();
      await preferences.setString(USER_KEY, json.encode(userData));

      return _currentUser!;
    } else {
      throw Exception('Đăng nhập không thành công');
    }
  }

  // Add logout method
  Future<void> logout() async {
    final prefs.SharedPreferences preferences =
        await prefs.SharedPreferences.getInstance();
    await preferences.remove(USER_KEY);
    _currentUser = null;

    try {
      await http.post(
        Uri.parse('$apiUrl/logout'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      print('Error logging out from server: $e');
      // Continue with local logout even if server logout fails
    }
  }

  Future<void> register(String username, String password, String email,
      {String img = '', String phone = '', String address = ''}) async {
    final response = await http.post(
      Uri.parse('$apiUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
        'email': email,
        'img': img,
        'phone': phone,
        'address': address,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to register');
    }
  }

  Future<Map<String, dynamic>> checkUser(String emailOrUsername) async {
    final response = await http.post(
      Uri.parse('$apiUrl/check-user'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'emailOrUsername': emailOrUsername}),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['message']);
    }
  }

  Future<void> resetPassword(String userId, String newPassword) async {
    final response = await http.post(
      Uri.parse('$apiUrl/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['message']);
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$apiUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send reset password link');
    }
  }

  // Add method to update stored user data
  Future<void> updateStoredUserData(UserModel updatedUser) async {
    _currentUser = updatedUser;
    final prefs.SharedPreferences preferences =
        await prefs.SharedPreferences.getInstance();
    await preferences.setString(USER_KEY, json.encode(updatedUser.toMap()));
  }
}
