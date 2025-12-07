import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/config.dart';

class ServerTester {
  static Future<void> testAllEndpoints() async {
    print('🔍 ===== TESTING SERVER CONNECTION =====');
    print('📡 Server URL: ${AppConfig.baseUrl}');

    final tests = [
      _testHealth(),
      _testCors(),
      _testPost(),
      _testRegister(),
      _testProducts(),
    ];

    for (var test in tests) {
      await test;
      await Future.delayed(Duration(seconds: 1));
    }

    print('✅ ===== ALL TESTS COMPLETED =====');
  }

  static Future<void> _testHealth() async {
    try {
      print('\n1️⃣ Testing /api/health...');
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 5));

      print('   Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('   ✅ Success: ${data['message']}');
        print('   📊 Server IP: ${data['ip']}');
        print('   🕐 Server Time: ${data['serverTime']}');
      }
    } catch (e) {
      print('   ❌ Error: $e');
    }
  }

  static Future<void> _testCors() async {
    try {
      print('\n2️⃣ Testing /api/test-cors...');
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/test-cors'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 5));

      print('   Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('   ✅ Success: ${data['message']}');
        print('   🌐 Origin: ${data['origin']}');
      }
    } catch (e) {
      print('   ❌ Error: $e');
    }
  }

  static Future<void> _testPost() async {
    try {
      print('\n3️⃣ Testing /api/test-post (POST request)...');
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/api/test-post'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'test': 'Hello Server',
              'timestamp': DateTime.now().toIso8601String(),
            }),
          )
          .timeout(Duration(seconds: 5));

      print('   Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('   ✅ Success: ${data['message']}');
      }
    } catch (e) {
      print('   ❌ Error: $e');
    }
  }

  static Future<void> _testRegister() async {
    try {
      print('\n4️⃣ Testing /api/users/register (POST)...');
      final response = await http
          .post(
            Uri.parse('${AppConfig.baseUrl}/api/users/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'username': 'testuser_${DateTime.now().millisecondsSinceEpoch}',
              'password': 'Test123!@#',
              'email':
                  'test${DateTime.now().millisecondsSinceEpoch}@example.com',
            }),
          )
          .timeout(Duration(seconds: 10));

      print('   Status: ${response.statusCode}');
      print('   Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('   ✅ Register endpoint is accessible');
      }
    } catch (e) {
      print('   ❌ Error: $e');
    }
  }

  static Future<void> _testProducts() async {
    try {
      print('\n5️⃣ Testing /api/products (GET)...');
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/products'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 5));

      print('   Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('   ✅ Retrieved ${data.length} products');
      }
    } catch (e) {
      print('   ❌ Error: $e');
    }
  }
}
