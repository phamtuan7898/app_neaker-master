import 'package:app_neaker/models/carts_model.dart';
import 'package:app_neaker/models/products_model.dart';
import 'package:app_neaker/models/user_model.dart';
import 'package:app_neaker/product_screen/comment_screen.dart';
import 'package:app_neaker/service/cart_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter/material.dart';

class ProductDetail extends StatefulWidget {
  final ProductModel product;
  final UserModel? user; // Make user parameter nullable

  ProductDetail({
    required this.product,
    required this.user,
  });

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  String? selectedSize;
  String? selectedColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product.productName,
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
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
              // Existing decoration...
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageCarousel(),
              SizedBox(height: 20),
              _buildTitleAndPrice(),
              SizedBox(height: 10),
              _buildDescription(),
              SizedBox(height: 20),
              _buildSizeSelector(), // Replace _buildAvailableSizes() with this
              SizedBox(height: 20),
              _buildColorSelector(), // Replace _buildAvailableColors() with this
              SizedBox(height: 30),
              // Comment button and rest of your widget...
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentScreen(
                        productId: widget.product.id,
                        user: widget.user,
                      ),
                    ),
                  );
                },
                child: Text('View Comments'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildAddToCartButton(context),
    );
  }

  Widget _buildSizeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a size:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          children: widget.product.size.map((size) {
            return ChoiceChip(
              label: Text(size),
              selected: selectedSize == size,
              onSelected: (selected) {
                setState(() {
                  selectedSize = selected ? size : null;
                });
              },
              backgroundColor: Colors.blue[100],
              selectedColor: Colors.blue[400],
              padding: EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select a color:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 8.0),
        Wrap(
          spacing: 10.0,
          children: widget.product.color.map((colorHex) {
            Color color = Color(int.parse(colorHex));
            bool isSelected = selectedColor == colorHex;
            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedColor = colorHex;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                margin: EdgeInsets.only(right: 8, bottom: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.black54,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: isSelected
                    ? Center(
                        child: Icon(
                          Icons.check,
                          color:
                              _isDarkColor(color) ? Colors.white : Colors.black,
                        ),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _isDarkColor(Color color) {
    return color.computeLuminance() < 0.5;
  }

  Widget _buildImageCarousel() {
    return Container(
      height: 300,
      child: PageView.builder(
        itemCount: widget.product.image.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.network(
              widget.product.image[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleAndPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.product.productName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              widget.product.price,
              style: TextStyle(
                fontSize: 20,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        _buildRatingBar(),
      ],
    );
  }

  Widget _buildRatingBar() {
    return Row(
      children: [
        RatingBarIndicator(
          rating: widget.product.rating,
          itemBuilder: (context, index) => Icon(
            Icons.star,
            color: Colors.amber,
          ),
          itemCount: 5,
          itemSize: 22.0,
          direction: Axis.horizontal,
        ),
        SizedBox(width: 8),
        Text(
          '${widget.product.rating.toStringAsFixed(1)}',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          widget.product.description,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildAvailableSizes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available sizes:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          children: widget.product.size.map((size) {
            return Chip(
              label: Text(size),
              backgroundColor: Colors.blue[100],
              padding: EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailableColors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available colors:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: 8.0),
        Row(
          children: widget.product.color.map((colorHex) {
            Color color = Color(int.parse(colorHex));
            return Container(
              width: 30,
              height: 30,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: Colors.black54, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAddToCartButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white24, Colors.lightBlueAccent.shade700],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: ElevatedButton(
          onPressed: () {
            if (widget.user != null) {
              _showQuantityDialog(context);
            } else {
              // Show login dialog or navigate to login screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please login to add to cart'),
                  action: SnackBarAction(
                    label: 'Log in',
                    onPressed: () {
                      // Navigate to login screen
                      // Navigator.pushNamed(context, '/login');
                    },
                  ),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: 15),
            textStyle: TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Add to cart',
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),
        ),
      ),
    );
  }

  void _showQuantityDialog(BuildContext context) {
    if (widget.user == null) return; // Early return if no user

    // Validate size and color selection
    if (selectedSize == null || selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(selectedSize == null && selectedColor == null
              ? 'Please select both size and color'
              : selectedSize == null
                  ? 'Please select a size'
                  : 'Please select a color'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    int quantity = 1;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select quantity'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Show selected size and color
                  Text('Size: $selectedSize',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Color: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(int.parse(selectedColor!)),
                          border: Border.all(color: Colors.black54, width: 1),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove),
                        onPressed: () {
                          if (quantity > 1) {
                            setState(() => quantity--);
                          }
                        },
                      ),
                      Text(
                        '$quantity',
                        style: TextStyle(fontSize: 24),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          setState(() => quantity++);
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () async {
                CartItem cartItem = CartItem(
                  id: '', // MongoDB will generate this
                  userId: widget.user!.id,
                  productId: widget.product.id,
                  productName: widget.product.productName,
                  price: widget.product.price,
                  quantity: quantity,
                  size: selectedSize!,
                  color: selectedColor!,
                );

                try {
                  await CartService().addCartItem(widget.user!.id, cartItem);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${widget.product.productName} has been added to cart!'),
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cannot add product to cart.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
