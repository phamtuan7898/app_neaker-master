import 'package:flutter/material.dart';
import 'package:app_neaker/order_tracking/view_models/order_tracking_view_model.dart';
import 'package:app_neaker/order_tracking/widgets/order_card.dart';
import 'package:app_neaker/order_tracking/widgets/empty_orders.dart';
import 'package:provider/provider.dart';

class OrderTrackingScreen extends StatefulWidget {
  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => OrderTrackingViewModel(),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _OrderTrackingBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
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
    );
  }
}

class _OrderTrackingBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<OrderTrackingViewModel>();

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => viewModel.loadOrders(),
      child: viewModel.orders.isEmpty
          ? const EmptyOrders()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.orders.length,
              itemBuilder: (context, index) {
                final order = viewModel.orders[index];
                return OrderCard(
                  order: order,
                  onTap: () => viewModel.showOrderDetails(context, order),
                );
              },
            ),
    );
  }
}
