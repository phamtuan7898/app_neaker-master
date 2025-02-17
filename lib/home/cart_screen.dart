import 'package:app_neaker/models/carts_model.dart';
import 'package:app_neaker/models/user_model.dart';
import 'package:app_neaker/service/auth_service%20.dart';
import 'package:app_neaker/service/cart_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as json;

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> cartItems = [];
  final CartService _cartService = CartService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _hasAddress = false;

  UserModel? currentUser;
  bool isLoading = true;
  bool isUpdating = false;
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VND',
    decimalDigits: 0,
  );

  // Helper method to parse price string to double
  double parsePrice(String price) {
    // Remove currency symbol, commas and spaces
    String cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');
    return double.parse(cleanPrice);
  }

  // Rest of the initialization and user management methods remain the same...
  @override
  void initState() {
    super.initState();
    _initializeUser();
    _checkAddress();
  }

  Future<void> _checkAddress() async {
    if (currentUser == null) return;

    try {
      final response = await http.get(
        Uri.parse('${CartService().apiUrl}/check-address/${currentUser!.id}'),
      );

      if (response.statusCode == 200) {
        final data = json.jsonDecode(response.body);
        setState(() {
          _hasAddress = data['hasAddress'];
          if (_hasAddress) {
            _addressController.text = data['currentAddress'];
            _phoneController.text = data['currentPhone'];
          }
        });
      }
    } catch (e) {
      print('Error checking address: $e');
    }
  }

  Future<bool> _updateAddress(String address, String phone) async {
    try {
      final response = await http.put(
        Uri.parse('${CartService().apiUrl}/update-address/${currentUser!.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.jsonEncode({
          'address': address,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _hasAddress = true;
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating address and phone: $e');
      return false;
    }
  }

  Future<void> _initializeUser() async {
    try {
      final user = await AuthService().getCurrentUser();
      setState(() {
        currentUser = user;
        isLoading = false;
      });
      if (user != null) {
        await fetchCartItems();
        // Kiểm tra và điền thông tin người dùng nếu có
        if (user.phone != null && user.phone!.isNotEmpty) {
          _phoneController.text = user.phone!;
        }
        if (user.address != null && user.address!.isNotEmpty) {
          _addressController.text = user.address!;
          _hasAddress = true;
        }
      }
    } catch (e) {
      print('Error getting current user: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showContactDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delivery information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone number',
                    hintText: 'Enter your phone number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Shipping address',
                    hintText: 'Enter your address',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () async {
                if (_phoneController.text.trim().isEmpty ||
                    _phoneController.text.trim().length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid phone number'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (_addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter address'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final success = await _updateAddress(
                    _addressController.text.trim(),
                    _phoneController.text.trim());
                if (success) {
                  Navigator.of(context).pop();
                  _processPayment();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Unable to update information'),
                      backgroundColor: Colors.red,
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

  Future<void> fetchCartItems() async {
    if (currentUser == null) return;

    try {
      final items = await _cartService.fetchCartItems(currentUser!.id);
      setState(() {
        cartItems = items;
      });

      // Kiểm tra và điền thông tin người dùng nếu có
      if (currentUser!.phone != null && currentUser!.phone!.isNotEmpty) {
        _phoneController.text = currentUser!.phone!;
      }
      if (currentUser!.address != null && currentUser!.address!.isNotEmpty) {
        _addressController.text = currentUser!.address!;
        _hasAddress = true;
      }
    } catch (e) {
      print('Error fetching cart items: $e');
      _showErrorMessage('Unable to load cart');
    }
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (currentUser == null || isUpdating) return;

    if (newQuantity < 1) {
      _showErrorMessage('Quantity cannot be less than 1');
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      // Sử dụng item.productId thay vì item.id
      await _cartService.updateCartItemQuantity(
        currentUser!.id,
        item.productId,
        newQuantity,
      );

      setState(() {
        final index = cartItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          cartItems[index].quantity = newQuantity;
        }
      });

      _showSuccessMessage('Quantity updated');
    } catch (e) {
      print('Error updating cart item quantity: $e');
      _showErrorMessage('Unable to update quantity');
      // Khôi phục lại số lượng cũ nếu cập nhật thất bại
      setState(() {
        final index = cartItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          cartItems[index].quantity = item.quantity;
        }
      });
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (cartItems.isEmpty) {
      _showErrorMessage('Cart is empty');
      return;
    }

    // Kiểm tra xem người dùng đã có địa chỉ và số điện thoại hay chưa
    if (_hasAddress && _phoneController.text.trim().isNotEmpty) {
      // Hiển thị dialog xác nhận thanh toán
      bool? confirmPayment = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Payment Confirmation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery information:'),
                  SizedBox(height: 8),
                  Text('Phone number: ${_phoneController.text.trim()}'),
                  SizedBox(height: 4),
                  Text('Address: ${_addressController.text.trim()}'),
                  SizedBox(height: 12),
                  Text(
                      'Total amount: ${currencyFormatter.format(getTotalPriceInVND())}'),
                  SizedBox(height: 8),
                  Text('Are you sure you want to make payment?'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text('Confirm'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      // Nếu người dùng xác nhận thanh toán
      if (confirmPayment == true) {
        setState(() {
          isLoading = true;
        });

        try {
          final success = await _cartService.processPayment(
            currentUser!.id,
            cartItems,
            getTotalPriceInVND(),
            _phoneController.text.trim(),
            _addressController.text.trim(),
          );

          if (success) {
            setState(() {
              cartItems.clear();
            });
            _showSuccessMessage('Payment successful');
          }
        } catch (e) {
          _showErrorMessage('Payment failed: ${e.toString()}');
        } finally {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      // Nếu không có địa chỉ hoặc số điện thoại, hiển thị dialog để nhập thông tin
      await _showContactDialog();
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

  Widget _buildQuantityControls(CartItem item) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.remove_circle_outline),
          color: Colors.red,
          onPressed: isUpdating
              ? null
              : () => _updateQuantity(item, item.quantity - 1),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            item.quantity.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle_outline),
          color: Colors.green,
          onPressed: isUpdating
              ? null
              : () => _updateQuantity(item, item.quantity + 1),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('CART')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CART',
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
      body: cartItems.isEmpty
          ? Center(
              child: Text('Cart is empty', style: TextStyle(fontSize: 18)),
            )
          : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Price: ${currencyFormatter.format(parsePrice(item.price))}',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.blueAccent),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            _buildQuantityControls(item),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.grey),
                              onPressed: isUpdating
                                  ? null
                                  : () => _removeCartItem(item),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cartItems.isEmpty ? null : _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total amount:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currencyFormatter.format(getTotalPriceInVND()),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: Size(double.infinity, 50),
            ),
            child: isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    'PAY',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeCartItem(CartItem item) async {
    if (currentUser == null) return;

    try {
      // Sử dụng item.productId thay vì item.id
      await _cartService.removeCartItem(currentUser!.id, item.productId);
      setState(() {
        cartItems.remove(item);
      });
      _showSuccessMessage('Product removed from cart');
    } catch (e) {
      print('Error removing cart item: $e');
      _showErrorMessage('Cannot delete product');
    }
  }

  double getTotalPriceInVND() {
    return cartItems.fold(
      0.0,
      (total, item) => total + (parsePrice(item.price) * item.quantity),
    );
  }
}
