import 'package:app_neaker/service/auth_service%20.dart';
import 'package:flutter/material.dart';
import 'package:app_neaker/models/products_model.dart';
import 'package:app_neaker/models/user_model.dart';
import 'package:app_neaker/service/product_service.dart';

class SearchState {
  final bool isLoading;
  final String? errorMessage;
  final List<ProductModel> filteredProducts;
  final UserModel? currentUser;
  final bool hasSearchText;
  final bool hasFilteredProducts;

  SearchState({
    this.isLoading = true,
    this.errorMessage,
    this.filteredProducts = const [],
    this.currentUser,
    this.hasSearchText = false,
  }) : hasFilteredProducts = filteredProducts.isNotEmpty;

  SearchState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<ProductModel>? filteredProducts,
    UserModel? currentUser,
    bool? hasSearchText,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      currentUser: currentUser ?? this.currentUser,
      hasSearchText: hasSearchText ?? this.hasSearchText,
    );
  }
}

class SearchViewModel {
  final List<ProductModel> _products = [];
  final TextEditingController searchController = TextEditingController();
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();

  final ValueNotifier<SearchState> stateNotifier = ValueNotifier<SearchState>(
    SearchState(),
  );

  SearchViewModel() {
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = searchController.text;
    stateNotifier.value = stateNotifier.value.copyWith(
      hasSearchText: query.isNotEmpty,
    );
  }

  Future<void> initializeData() async {
    try {
      await Future.wait([
        _fetchProducts(),
        _initializeUser(),
      ]);
    } catch (e) {
      stateNotifier.value = stateNotifier.value.copyWith(
        errorMessage: 'Failed to load data',
        isLoading: false,
      );
    }
  }

  Future<void> _initializeUser() async {
    try {
      final user = await _authService.getCurrentUser();
      stateNotifier.value = stateNotifier.value.copyWith(
        currentUser: user,
      );
    } catch (e) {
      print('Error getting current user: $e');
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final products = await _productService.fetchProducts();
      _products.clear();

      // Fix: Ép kiểu và xử lý danh sách đúng cách
      if (products is List<ProductModel>) {
        _products.addAll(products);
      } else if (products is List<dynamic>) {
        // Convert từ List<dynamic> sang List<ProductModel>
        final convertedProducts = products
            .whereType<Map<String, dynamic>>()
            .map((json) => ProductModel.fromJson(json))
            .whereType<ProductModel>()
            .toList();
        _products.addAll(convertedProducts);
      }

      stateNotifier.value = stateNotifier.value.copyWith(
        isLoading: false,
      );
    } catch (e) {
      print('Error fetching products: $e');
      stateNotifier.value = stateNotifier.value.copyWith(
        errorMessage: 'Failed to load products',
        isLoading: false,
      );
    }
  }

  void filterProducts(String query) {
    final filtered = query.isEmpty
        ? <ProductModel>[]
        : _products
            .where((product) =>
                product.productName.toLowerCase().contains(query.toLowerCase()))
            .toList();

    stateNotifier.value = stateNotifier.value.copyWith(
      filteredProducts: filtered,
      hasSearchText: query.isNotEmpty,
    );
  }

  void clearSearch() {
    searchController.clear();
    filterProducts('');
  }

  void dispose() {
    searchController.dispose();
    stateNotifier.dispose();
  }
}
