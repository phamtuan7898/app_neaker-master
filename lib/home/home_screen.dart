import 'package:app_neaker/models/products_model.dart';
import 'package:app_neaker/models/user_model.dart';
import 'package:app_neaker/product_screen/product_detail.dart';
import 'package:app_neaker/screens/search_screen.dart';
import 'package:app_neaker/service/auth_service%20.dart';
import 'package:app_neaker/service/product_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<ProductModel>> _productsFuture;
  late PageController _pageController;
  Timer? _timer;
  UserModel? currentUser; // Add this

  @override
  void initState() {
    super.initState();
    _productsFuture = ProductService().fetchProducts();
    _pageController = PageController();
    _initializeUser(); // Add this

    // Set up Timer to change page automatically
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Add this method
  Future<void> _initializeUser() async {
    try {
      final user = await AuthService().getCurrentUser();
      setState(() {
        currentUser = user;
      });
    } catch (e) {
      print('Error getting current user: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TRANG CHỦ',
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ProductModel>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Có lỗi xảy ra: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có sản phẩm nào.'));
          } else {
            final products = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: _buildPromotionsBanner(products),
                  ),
                  _buildCategoryTitle('Sản phẩm nổi bật'),
                  _buildHighlightedSection(products),
                  _buildCategoryTitle('Danh mục sản phẩm'),
                  _buildCategorySection(products, 'Running shoes'),
                  _buildCategorySection(products, 'Casual shoes'),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // Update the navigation methods to pass the user parameter
  void _navigateToProductDetail(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetail(
          product: product,
          user: currentUser, // Pass the current user
        ),
      ),
    );
  }

  Widget _buildPromotionsBanner(List<ProductModel> products) {
    final promotionsProducts = products.where((p) {
      final price = int.tryParse(p.price.replaceAll(RegExp(r'[^\d]'), ''));
      return price != null && price < 3500000;
    }).toList();
    if (promotionsProducts.isEmpty) return Container();

    final infiniteList = List.generate(
      1000,
      (index) => promotionsProducts[index % promotionsProducts.length],
    );

    return Container(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        itemCount: infiniteList.length,
        itemBuilder: (context, index) {
          final product = infiniteList[index];
          return GestureDetector(
            onTap: () => _navigateToProductDetail(product),
            child: _buildPromotionCard(product),
          );
        },
      ),
    );
  }

  Widget _buildCategorySection(List<ProductModel> products, String category) {
    final categoryProducts =
        products.where((p) => p.shoeType == category).toList();
    if (categoryProducts.isEmpty) {
      return Container(
        height: 200,
        child: const Center(
            child: Text('Không có sản phẩm nào trong danh mục này.')),
      );
    }

    return Container(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categoryProducts.length,
        itemBuilder: (context, index) {
          final product = categoryProducts[index];
          return GestureDetector(
            onTap: () => _navigateToProductDetail(product),
            child: _buildCategoryCard(product),
          );
        },
      ),
    );
  }

  Widget _buildHighlightedSection(List<ProductModel> products) {
    final highlightedProducts = products.where((p) => p.rating >= 4.5).toList();
    return _buildHorizontalProductList(highlightedProducts);
  }

  Widget _buildHorizontalProductList(List<ProductModel> products) {
    if (products.isEmpty) {
      return const Center(child: Text('Không có sản phẩm nổi bật.'));
    }

    return Container(
      height: 200,
      child: PageView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () => _navigateToProductDetail(product),
            child: _buildHighlightedCard(product),
          );
        },
      ),
    );
  }

  // Rest of your widget building methods remain the same
  Widget _buildPromotionCard(ProductModel product) {
    // Implementation remains the same
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(product.image[0]),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          product.productName,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(ProductModel product) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: 150,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                product.image[0],
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    product.price,
                    style: TextStyle(color: Colors.blueAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedCard(ProductModel product) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              product.image[0],
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  product.price,
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
