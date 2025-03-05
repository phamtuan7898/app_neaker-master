import 'package:app_neaker/home/cart_screen.dart';
import 'package:app_neaker/models/carts_model.dart';
import 'package:app_neaker/product_screen/comment_screen.dart';
import 'package:app_neaker/service/auth_service%20.dart';
import 'package:app_neaker/service/order_service.dart';
import 'package:app_neaker/service/cart_service.dart'; // Thêm import CartService
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';

class OrderTrackingScreen extends StatefulWidget {
  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService(); // Khởi tạo CartService
  List<Order> orders = [];
  bool isLoading = true;

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VND',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        final fetchedOrders = await _orderService.fetchOrders(user.id);
        setState(() {
          orders = fetchedOrders;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        isLoading = false;
      });
      _showErrorMessage('Unable to load order list');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Order details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow('Date booked:',
                      DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)),
                  _buildInfoRow('Status:', order.status),
                  _buildInfoRow('Phone number:', order.phone),
                  _buildInfoRow('Address:', order.address),
                  SizedBox(height: 16),
                  Text(
                    'Product:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...order.items.map((item) => _buildOrderItemTile(item)),
                  Divider(thickness: 1),
                  _buildInfoRow(
                    'Total amount:',
                    currencyFormatter.format(order.totalAmount),
                    textStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? textStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: textStyle ?? TextStyle(fontSize: 16),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemTile(OrderItem item) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Quantity: ${item.quantity}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Spacer(),
                Text(
                  currencyFormatter.format(double.parse(
                      item.price.replaceAll(RegExp(r'[^\d]'), ''))),
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Row(
                  children: [
                    Text(
                      'Size: ',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.size,
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 16),
                Row(
                  children: [
                    Text(
                      'Color: ',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    Container(
                      margin: EdgeInsets.only(right: 4),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getColorFromHex(item.color),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            // Thêm nút để viết comment và mua lại
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.comment, color: Colors.blue),
                  label: Text('Write a review',
                      style: TextStyle(color: Colors.blue)),
                  onPressed: () async {
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please login to comment')),
                      );
                    }
                  },
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  icon: Icon(Icons.refresh, color: Colors.green),
                  label:
                      Text('Buy Again', style: TextStyle(color: Colors.green)),
                  onPressed: () => _buyAgain(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buyAgain(OrderItem item) async {
    final user = await _authService.getCurrentUser();
    if (user == null) {
      _showErrorMessage('Please login to buy again');
      return;
    }

    // Create CartItem from OrderItem
    final cartItem = CartItem(
      id: '', // MongoDB will auto-generate
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

      // Navigate to Cart Screen and wait for result
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CartScreen(),
        ),
      );

      // If returned from CartScreen, reload orders
      await _loadOrders();
    } catch (e) {
      _showErrorMessage('Failed to add ${item.productName} to cart');
      print('Error adding to cart: $e');
    }
  }

  Color _getColorFromHex(String colorValue) {
    if (colorValue.toLowerCase() == 'red') return Colors.red;
    if (colorValue.toLowerCase() == 'blue') return Colors.blue;
    try {
      int colorInt = int.parse(colorValue);
      return Color(colorInt);
    } catch (e) {
      if (colorValue.startsWith('#')) {
        colorValue = colorValue.substring(1);
      }
      try {
        return Color(int.parse('0xFF$colorValue'));
      } catch (e) {
        return Colors.grey;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('MY ORDER')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MY ORDER',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white24, Colors.lightBlueAccent.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: orders.isEmpty
            ? Center(
                child: Text(
                  'No orders yet',
                  style: TextStyle(fontSize: 18),
                ),
              )
            : ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: InkWell(
                      onTap: () => _showOrderDetails(order),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #${order.id.substring(0, 8)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd/MM/yyyy')
                                      .format(order.orderDate),
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '${order.items.length} product',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total amount:',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  currencyFormatter.format(order.totalAmount),
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                order.status.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
