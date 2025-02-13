import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  static const String baseUrl = 'http://192.168.1.4:5002';
  // Singleton pattern
  static final AdminService _instance = AdminService._internal();

  factory AdminService() {
    return _instance;
  }

  AdminService._internal();

  // Login method
  Future<Map<String, dynamic>> login(String adminname, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminname': adminname,
          'adminpass': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Save adminId to SharedPreferences
        await _saveAdminId(data['adminId']);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid credentials',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error',
      };
    }
  }

  // Save admin ID to SharedPreferences
  Future<void> _saveAdminId(String adminId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adminId', adminId);
  }

  // Get saved admin ID
  Future<String?> getAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('adminId');
  }

  // Logout method
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('adminId');
  }
}
