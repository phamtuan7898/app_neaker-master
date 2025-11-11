import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app_neaker/models/order_model.dart';
import 'package:app_neaker/order_tracking/widgets/order_item_tile.dart';

class OrderDetailsSheet extends StatelessWidget {
  final Order order;
  final VoidCallback onBuyAgainSuccess;

  const OrderDetailsSheet({
    Key? key,
    required this.order,
    required this.onBuyAgainSuccess,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'VND',
      decimalDigits: 0,
    );

    return DraggableScrollableSheet(
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
                _buildDragHandle(),
                _buildTitle('Order Details'),
                const SizedBox(height: 16),
                _buildOrderInfoCard(order, currencyFormatter),
                const SizedBox(height: 16),
                _buildTitle('Products'),
                const SizedBox(height: 8),
                ...order.items.map((item) => OrderItemTile(
                      item: item,
                      onBuyAgainSuccess:
                          onBuyAgainSuccess, // Truyền callback xuống
                    )),
                const SizedBox(height: 16),
                _buildTotalAmountCard(order, currencyFormatter),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildOrderInfoCard(Order order, NumberFormat currencyFormatter) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow('Order ID:', order.id.substring(0, 8)),
            _buildInfoRow(
              'Date Booked:',
              DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate),
            ),
            _buildInfoRow('Status:', order.status),
            _buildInfoRow('Phone Number:', order.phone),
            _buildInfoRow('Address:', order.address),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAmountCard(Order order, NumberFormat currencyFormatter) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildInfoRow(
          'Total Amount:',
          currencyFormatter.format(order.totalAmount),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? textStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: textStyle ?? const TextStyle(fontSize: 16),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
