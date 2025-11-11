import 'package:app_neaker/service/auth_service%20.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_neaker/models/order_model.dart';
import 'package:app_neaker/models/carts_model.dart';
import 'package:app_neaker/service/cart_service.dart';
import 'package:app_neaker/product_screen/comment_screen.dart';
import 'package:app_neaker/home/cart_screen.dart';
import 'package:provider/provider.dart';
import 'package:app_neaker/order_tracking/view_models/order_tracking_view_model.dart';

class OrderItemTile extends StatelessWidget {
  final OrderItem item;
  final VoidCallback onBuyAgainSuccess;
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();

  OrderItemTile({
    Key? key,
    required this.item,
    required this.onBuyAgainSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildPriceRow(item, currencyFormatter),
            const SizedBox(height: 12),
            _buildSizeAndColorRow(item),
            const SizedBox(height: 16),
            _buildActionButtons(context, item),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(OrderItem item, NumberFormat currencyFormatter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Quantity: ${item.quantity}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        Text(
          _parsePrice(item.price, currencyFormatter),
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _parsePrice(String price, NumberFormat currencyFormatter) {
    try {
      // Xử lý giá tiền từ string sang số
      final cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanPrice.isNotEmpty) {
        final priceValue = double.parse(cleanPrice);
        return currencyFormatter.format(priceValue);
      }
      return price;
    } catch (e) {
      return price;
    }
  }

  Widget _buildSizeAndColorRow(OrderItem item) {
    return Row(
      children: [
        _buildSizeChip(item.size),
        const SizedBox(width: 16),
        _buildColorChip(item.color),
      ],
    );
  }

  Widget _buildSizeChip(String size) {
    return Row(
      children: [
        Text(
          'Size: ',
          style: TextStyle(color: Colors.grey[700]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            size,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildColorChip(String colorValue) {
    return Row(
      children: [
        Text(
          'Color: ',
          style: TextStyle(color: Colors.grey[700]),
        ),
        Container(
          margin: const EdgeInsets.only(right: 4),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: _getColorFromHex(colorValue),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, OrderItem item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildReviewButton(context, item),
        const SizedBox(width: 8),
        _buildBuyAgainButton(context, item),
      ],
    );
  }

  Widget _buildReviewButton(BuildContext context, OrderItem item) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.comment, color: Colors.blue),
      label: const Text('Write a Review', style: TextStyle(color: Colors.blue)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.blue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () => _onReviewPressed(context, item),
    );
  }

  Widget _buildBuyAgainButton(BuildContext context, OrderItem item) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.refresh, color: Colors.white),
      label: const Text('Buy Again', style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () => _onBuyAgainPressed(context, item),
    );
  }

  Future<void> _onReviewPressed(BuildContext context, OrderItem item) async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommentScreen(
              productId: item.productId,
              user: user,
              readOnly: false,
            ),
          ),
        );
      } else {
        _showSnackBar(context, 'Please login to comment', Colors.orange);
      }
    } catch (e) {
      _showSnackBar(context, 'Failed to open review screen', Colors.red);
    }
  }

  Future<void> _onBuyAgainPressed(BuildContext context, OrderItem item) async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        _showSnackBar(context, 'Please login to buy again', Colors.orange);
        return;
      }

      _showSnackBar(
          context, 'Adding ${item.productName} to cart...', Colors.blue);

      final cartItem = CartItem(
        id: '',
        userId: user.id,
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: item.quantity,
        size: item.size,
        color: item.color,
      );

      try {
        await _cartService.addCartItem(user.id, cartItem);

        _showSnackBar(context,
            'Added ${item.productName} to cart successfully!', Colors.green);

        // Gọi callback để parent refresh data
        onBuyAgainSuccess();

        // ĐỢI snackbar hiển thị xong rồi mới chuyển trang
        await Future.delayed(const Duration(milliseconds: 1500));

        // Sử dụng await để chờ kết quả từ CartScreen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CartScreen(skipAddressCheck: true),
          ),
        );

        // QUAN TRỌNG: Refresh lại khi quay từ CartScreen về
        // Đợi một chút để đảm bảo UI đã build xong
        await Future.delayed(const Duration(milliseconds: 500));
        onBuyAgainSuccess();
      } catch (e) {
        print('Cart service error: $e');
        _showSnackBar(
            context, 'Failed to add to cart: ${e.toString()}', Colors.red);
      }
    } catch (e) {
      print('Error in buy again: $e');
      _showSnackBar(context, 'Error: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getColorFromHex(String colorValue) {
    if (colorValue.toLowerCase() == 'red') return Colors.red;
    if (colorValue.toLowerCase() == 'blue') return Colors.blue;
    if (colorValue.toLowerCase() == 'green') return Colors.green;
    if (colorValue.toLowerCase() == 'black') return Colors.black;
    if (colorValue.toLowerCase() == 'white') return Colors.white;

    try {
      // Xử lý hex color
      String hexColor = colorValue.toUpperCase().replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
