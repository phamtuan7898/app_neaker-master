import 'package:flutter/material.dart';
import 'package:app_neaker/models/products_model.dart';
import 'package:app_neaker/models/user_model.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  final UserModel? currentUser;

  const ProductGrid({
    Key? key,
    required this.products,
    required this.currentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) => ProductCard(
        product: products[index],
        currentUser: currentUser,
      ),
    );
  }
}
