import 'dart:convert';
import 'package:app_neaker/models/order_model.dart';
import 'package:http/http.dart' as http;

class OrderService {
  final String apiUrl = 'http://192.168.1.16:5002';

  Future<List<Order>> fetchOrders(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/orders/$userId'),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        print('Fetched Orders: $jsonResponse'); // Debug dữ liệu nhận được
        return jsonResponse.map((order) => Order.fromJson(order)).toList();
      } else {
        throw Exception('Failed to load orders: ${response.body}');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      throw Exception('Failed to load orders');
    }
  }

  Future<OrderItem> fetchOrderDetails(String userId, String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/orders/$userId/$orderId'),
      );

      if (response.statusCode == 200) {
        return OrderItem.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load order details: ${response.body}');
      }
    } catch (e) {
      print('Error fetching order details: $e');
      throw Exception('Failed to load order details');
    }
  }
}
