import 'dart:convert';
import 'dart:io';
import 'package:app_neaker/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.1.16:5002';
  static const String _contentType = 'application/json';

  // Singleton instance
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl => _baseUrl;

  // Generic HTTP GET request helper
  Future<Map<String, dynamic>?> _getRequest(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$endpoint'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('GET Request failed: $endpoint - ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('GET Request error: $endpoint - $error');
      return null;
    }
  }

  // Generic HTTP PUT request helper
  Future<bool> _putRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'Content-Type': _contentType},
        body: jsonEncode(data),
      );

      final success = response.statusCode == 200;
      if (!success) {
        final responseBody = response.body;
        print(
            'PUT Request failed: $endpoint - ${response.statusCode}, body: $responseBody');
      }
      return success;
    } catch (e) {
      print('PUT Request error: $endpoint - $e');
      return false;
    }
  }

  // Generic HTTP DELETE request helper
  Future<bool> _deleteRequest(String endpoint,
      {Map<String, dynamic>? data}) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {'Content-Type': _contentType},
        body: data != null ? jsonEncode(data) : null,
      );

      final success = response.statusCode == 200;
      if (!success) {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] ?? 'DELETE request failed';
        print(
            'DELETE Request failed: $endpoint - ${response.statusCode}, message: $errorMessage');
      }
      return success;
    } catch (e) {
      print('DELETE Request error: $endpoint - $e');
      return false;
    }
  }

  // User profile methods
  Future<UserModel?> getUserProfile(String userId) async {
    final data = await _getRequest('/api/users/$userId');
    return data != null ? UserModel.fromMap(data) : null;
  }

  Future<bool> updateUserProfile(
      String userId, Map<String, dynamic> updatedData) async {
    return await _putRequest('/api/users/$userId', updatedData);
  }

  Future<bool> uploadProfileImage(String userId, File imageFile) async {
    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse('$_baseUrl/api/users/$userId/upload-image'));
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();
      final success = response.statusCode == 200;

      if (!success) {
        print('Image upload failed: ${response.statusCode}');
      }

      return success;
    } catch (e) {
      print('Error uploading profile image: $e');
      return false;
    }
  }

  Future<bool> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) async {
    return await _putRequest(
      '/api/users/$userId/change-password',
      {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
  }

// Method to delete all user data before account deletion
  Future<bool> deleteAllUserData(String userId) async {
    try {
      // Delete user comments
      final commentsResponse = await http.delete(
        Uri.parse('$_baseUrl/api/comments/user/$userId'),
      );

      // Delete user cart items
      final cartResponse = await http.delete(
        Uri.parse('$_baseUrl/api/cart/user/$userId'),
      );

      // Delete user orders
      final ordersResponse = await http.delete(
        Uri.parse('$_baseUrl/api/orders/user/$userId'),
      );

      // Log the results for debugging
      print('Comments deletion: ${commentsResponse.statusCode}');
      print('Cart deletion: ${cartResponse.statusCode}');
      print('Orders deletion: ${ordersResponse.statusCode}');

      // We consider it successful even if some deletions fail
      // The main account deletion will handle the transaction
      return true;
    } catch (e) {
      print('Error deleting user data: $e');
      return false;
    }
  }

  // Enhanced delete account method
  Future<bool> deleteAccount(String userId, String password) async {
    try {
      // First, try to delete individual user data
      await deleteAllUserData(userId);

      // Then delete the main account
      final success = await _deleteRequest(
        '/api/users/$userId/delete-account',
        data: {'password': password},
      );

      if (success) {
        await _clearSharedPreferences();
      }

      return success;
    } catch (e) {
      print('Error in deleteAccount: $e');
      return false;
    }
  }

  // Alternative method for more controlled deletion
  Future<Map<String, dynamic>> deleteAccountWithDetails(
      String userId, String password) async {
    try {
      final Map<String, dynamic> result = {
        'success': false,
        'accountDeleted': false,
        'dataDeleted': false,
        'message': ''
      };

      // Delete user data first
      result['dataDeleted'] = await deleteAllUserData(userId);

      // Then delete account
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/users/$userId/delete-account'),
        headers: {'Content-Type': _contentType},
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode == 200) {
        result['success'] = true;
        result['accountDeleted'] = true;
        result['message'] = 'Account and all data deleted successfully';
        await _clearSharedPreferences();
      } else {
        final errorData = jsonDecode(response.body);
        result['message'] = errorData['message'] ?? 'Failed to delete account';
      }

      return result;
    } catch (e) {
      print('Error in deleteAccountWithDetails: $e');
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Clear shared preferences (extracted for reusability)
  Future<void> _clearSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error clearing shared preferences: $e');
    }
  }

  // Additional utility methods
  Future<bool> checkServerConnection() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Method to update multiple user fields efficiently
  Future<bool> updateUserFields(
    String userId, {
    String? username,
    String? email,
    String? phone,
    String? address,
    String? img,
  }) async {
    final updateData = <String, dynamic>{};

    if (username != null) updateData['username'] = username;
    if (email != null) updateData['email'] = email;
    if (phone != null) updateData['phone'] = phone;
    if (address != null) updateData['address'] = address;
    if (img != null) updateData['img'] = img;

    if (updateData.isEmpty) return true; // Nothing to update

    return await updateUserProfile(userId, updateData);
  }
}
