import 'package:app_neaker/search_screen/view_models/search_view_model.dart';
import 'package:app_neaker/search_screen/widgets/empty_state.dart';
import 'package:app_neaker/search_screen/widgets/product_grid.dart';
import 'package:app_neaker/search_screen/widgets/search_field.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SearchViewModel _viewModel = SearchViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.initializeData();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SEARCH',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SearchField(
              controller: _viewModel.searchController,
              onChanged: _viewModel.filterProducts,
              onClear: _viewModel.clearSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder<SearchState>(
                valueListenable: _viewModel.stateNotifier,
                builder: (context, state, _) {
                  return _buildContent(state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SearchState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return EmptyState(
        icon: Icons.error_outline,
        text: state.errorMessage!,
      );
    }

    if (!state.hasSearchText) {
      return const EmptyState(
        icon: Icons.search,
        text: 'Enter a keyword to search',
      );
    }

    if (!state.hasFilteredProducts) {
      return const EmptyState(
        icon: Icons.search_off,
        text: 'No products found\nTry different keywords',
      );
    }

    return ProductGrid(
      products: state.filteredProducts,
      currentUser: state.currentUser,
    );
  }
}
