import 'dart:convert';
import 'dart:io';
import 'package:app_neaker/models/user_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = 'http://192.168.1.15:5002';

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/User/$userId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromMap(data);
      } else {
        print('Failed to load profile: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching user profile: $error');
    }
    return null;
  }

  Future<bool> updateUserProfile(
    String userId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(
            '$baseUrl/User/$userId'), // Correct endpoint for user profile update
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        return true; // Update successful
      } else {
        final responseBody = response.body; // Get response body for error
        print(
            'Failed to update profile: ${response.statusCode}, body: $responseBody');
        return false; // Update failed
      }
    } catch (e) {
      print('Error updating user profile: $e');
      return false; // Return false on error
    }
  }

  Future<bool> uploadProfileImage(String userId, File imageFile) async {
    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/User/$userId/upload-image'));

      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        return true; // Upload successful
      } else {
        print('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading profile image: $e');
    }
    return false; // Upload failed
  }

  Future<bool> changePassword(
      String userId, String oldPassword, String newPassword) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/User/$userId/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'oldPassword': oldPassword, 'newPassword': newPassword}),
      );

      return response.statusCode == 200; // Return true if update is successful
    } catch (e) {
      print('Error changing password: $e');
      return false; // Return false on error
    }
  }

  Future<bool> deleteAccount(String userId, String password) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/User/$userId/delete-account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'password': password}),
      );

      if (response.statusCode == 200) {
        // Clear local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        return true;
      }

      print('Failed to delete account: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error deleting account: $e');
      return false;
    }
  }
}
