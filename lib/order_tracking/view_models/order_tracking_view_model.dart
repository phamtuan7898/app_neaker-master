import 'package:app_neaker/service/auth_service%20.dart';
import 'package:flutter/material.dart';
import 'package:app_neaker/models/order_model.dart';
import 'package:app_neaker/service/order_service.dart';
import 'package:app_neaker/order_tracking/widgets/order_details_sheet.dart';

class OrderTrackingViewModel with ChangeNotifier {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();

  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  OrderTrackingViewModel() {
    loadOrders();
  }

  Future<void> loadOrders() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.getCurrentUser();
      if (user != null) {
        _orders = await _orderService.fetchOrders(user.id);
      } else {
        _errorMessage = 'Please login to view orders';
      }
    } catch (e) {
      _errorMessage = 'Unable to load order list';
      _showSnackBar('Unable to load order list');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void showOrderDetails(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => OrderDetailsSheet(
        order: order,
        onBuyAgainSuccess: loadOrders,
      ),
    );
  }

  void _showSnackBar(String message) {}
  void refreshOnReturn() {
    // Có thể thêm logic kiểm tra nếu cần refresh
    loadOrders();
  }
}
