import 'package:app_neaker/models/carts_model.dart';
import 'package:app_neaker/models/user_model.dart';
import 'package:app_neaker/service/auth_service%20.dart';
import 'package:app_neaker/service/cart_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as json;

class CartScreen extends StatefulWidget {
  final bool skipAddressCheck;

  const CartScreen({Key? key, this.skipAddressCheck = false}) : super(key: key);

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

  double parsePrice(String price) {
    String cleanPrice = price.replaceAll(RegExp(r'[^\d]'), '');
    return double.parse(cleanPrice);
  }

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _checkAddress() async {
    if (currentUser == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            '${CartService().baseUrl}/api/orders/check-address/${currentUser!.id}'),
      );

      if (response.statusCode == 200) {
        final data = json.jsonDecode(response.body);
        setState(() {
          _hasAddress = data['hasAddress'];
          if (_hasAddress) {
            _addressController.text = data['currentAddress'] ?? '';
            _phoneController.text = data['currentPhone'] ?? '';
          }
        });

        print('=== ADDRESS CHECK ===');
        print('Has address: $_hasAddress');
        print('Phone: ${_phoneController.text}');
        print('Address: ${_addressController.text}');
      }
    } catch (e) {
      print('Error checking address: $e');
    }
  }

  // THÊM: Phương thức lấy thông tin user từ profile
  Future<void> _loadUserProfile() async {
    if (currentUser == null) return;

    try {
      final response = await http.get(
        Uri.parse('${CartService().baseUrl}/api/users/${currentUser!.id}'),
      );

      if (response.statusCode == 200) {
        final userData = json.jsonDecode(response.body);
        setState(() {
          // Lấy thông tin từ user profile
          _phoneController.text = userData['phone'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _hasAddress = (userData['phone']?.isNotEmpty == true &&
              userData['address']?.isNotEmpty == true);
        });

        print('=== LOADED FROM USER PROFILE ===');
        print('Phone: ${_phoneController.text}');
        print('Address: ${_addressController.text}');
        print('Has address: $_hasAddress');
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<bool> _updateAddress(String address, String phone) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${CartService().baseUrl}/api/orders/update-address/${currentUser!.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.jsonEncode({
          'address': address,
          'phone': phone,
        }),
      );

      print('Update address response: ${response.statusCode}');
      print('Update address body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.jsonDecode(response.body);
        if (responseData['success'] == true) {
          setState(() {
            _hasAddress = true;
            _addressController.text = address;
            _phoneController.text = phone;
          });
          return true;
        }
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
      });
      if (user != null) {
        await fetchCartItems();

        // SỬA: Luôn load thông tin user profile trước
        await _loadUserProfile();

        // Sau đó mới kiểm tra address (nếu không phải skipAddressCheck)
        if (!widget.skipAddressCheck) {
          await _checkAddress();
        } else {
          // Nếu là skipAddressCheck, đảm bảo _hasAddress = true nếu có thông tin
          setState(() {
            _hasAddress = _phoneController.text.isNotEmpty &&
                _addressController.text.isNotEmpty;
          });
        }
      }
      setState(() {
        isLoading = false;
      });

      print('=== INITIALIZATION COMPLETE ===');
      print('Skip address check: ${widget.skipAddressCheck}');
      print('Has address: $_hasAddress');
      print('Phone: ${_phoneController.text}');
      print('Address: ${_addressController.text}');
    } catch (e) {
      print('Error getting current user: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _showContactDialog({VoidCallback? onSuccess}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Thông tin giao hàng',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    hintText: 'Nhập số điện thoại',
                    prefixIcon: Icon(Icons.phone,
                        color: Colors.lightBlueAccent.shade700),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.lightBlueAccent.shade700),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ giao hàng',
                    hintText: 'Nhập địa chỉ',
                    prefixIcon: Icon(Icons.location_on,
                        color: Colors.lightBlueAccent.shade700),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Colors.lightBlueAccent.shade700),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Xác nhận', style: TextStyle(color: Colors.blue)),
              onPressed: () async {
                if (_phoneController.text.trim().isEmpty ||
                    _phoneController.text.trim().length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vui lòng nhập số điện thoại hợp lệ'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (_addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Vui lòng nhập địa chỉ'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final success = await _updateAddress(
                    _addressController.text.trim(),
                    _phoneController.text.trim());
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cập nhật thông tin thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                  if (onSuccess != null) {
                    onSuccess();
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Không thể cập nhật thông tin'),
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
    } catch (e) {
      print('Error fetching cart items: $e');
      _showErrorMessage('Không thể tải giỏ hàng');
    }
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (currentUser == null || isUpdating) return;

    if (newQuantity < 1) {
      _showErrorMessage('Số lượng không thể nhỏ hơn 1');
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
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

      _showSuccessMessage('Đã cập nhật số lượng');
    } catch (e) {
      print('Lỗi cập nhật số lượng sản phẩm: $e');
      _showErrorMessage('Không thể cập nhật số lượng');
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

  // PHƯƠNG THỨC THANH TOÁN CHÍNH - SỬA LOGIC
  Future<void> _processPayment() async {
    if (cartItems.isEmpty) {
      _showErrorMessage('Giỏ hàng trống');
      return;
    }

    print('=== PROCESS PAYMENT ===');
    print('Skip address check: ${widget.skipAddressCheck}');
    print('Has address: $_hasAddress');
    print('Phone: ${_phoneController.text}');
    print('Address: ${_addressController.text}');

    // KIỂM TRA XEM CÓ THÔNG TIN GIAO HÀNG HỢP LỆ KHÔNG
    bool hasValidAddress = _phoneController.text.trim().isNotEmpty &&
        _phoneController.text.trim().length >= 10 &&
        _addressController.text.trim().isNotEmpty;

    if (hasValidAddress) {
      // ĐÃ CÓ THÔNG TIN HỢP LỆ - THANH TOÁN NGAY
      await _executePayment();
    } else {
      // CHƯA CÓ THÔNG TIN - HIỂN THỊ DIALOG NHẬP
      await _showContactDialog(onSuccess: _processPayment);
    }
  }

  // PHƯƠNG THỨC THANH TOÁN TỪNG SẢN PHẨM - SỬA LOGIC
  Future<void> _processSingleItemPayment(CartItem item) async {
    if (currentUser == null) return;

    print('=== PROCESS SINGLE ITEM PAYMENT ===');
    print('Skip address check: ${widget.skipAddressCheck}');
    print('Has address: $_hasAddress');
    print('Phone: ${_phoneController.text}');
    print('Address: ${_addressController.text}');

    // KIỂM TRA XEM CÓ THÔNG TIN GIAO HÀNG HỢP LỆ KHÔNG
    bool hasValidAddress = _phoneController.text.trim().isNotEmpty &&
        _phoneController.text.trim().length >= 10 &&
        _addressController.text.trim().isNotEmpty;

    if (hasValidAddress) {
      // ĐÃ CÓ THÔNG TIN HỢP LỆ - THANH TOÁN NGAY
      await _executeSingleItemPayment(item);
    } else {
      // CHƯA CÓ THÔNG TIN - HIỂN THỊ DIALOG NHẬP
      await _showContactDialog(
          onSuccess: () => _processSingleItemPayment(item));
    }
  }

  // THỰC THI THANH TOÁN TẤT CẢ - SỬA ĐỂ LUÔN HIỂN THỊ THÔNG TIN
  Future<void> _executePayment() async {
    bool? confirmPayment = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Xác nhận thanh toán',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LUÔN hiển thị thông tin giao hàng để user kiểm tra
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin giao hàng:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text('Số điện thoại: ${_phoneController.text.trim()}'),
                    SizedBox(height: 4),
                    Text('Địa chỉ: ${_addressController.text.trim()}'),
                    SizedBox(height: 12),
                  ],
                ),
                Text(
                  'Tổng tiền: ${currencyFormatter.format(getTotalPriceInVND())}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                SizedBox(height: 8),
                Text('Bạn có chắc chắn muốn thanh toán?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Xác nhận', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmPayment == true) {
      setState(() {
        isLoading = true;
      });

      try {
        print('=== EXECUTING PAYMENT ===');
        print('Using phone: ${_phoneController.text.trim()}');
        print('Using address: ${_addressController.text.trim()}');

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
          _showSuccessMessage('Thanh toán thành công');
        } else {
          _showErrorMessage('Thanh toán thất bại');
        }
      } catch (e) {
        print('Payment error: $e');
        _showErrorMessage('Thanh toán thất bại: ${e.toString()}');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // THỰC THI THANH TOÁN TỪNG SẢN PHẨM - SỬA ĐỂ LUÔN HIỂN THỊ THÔNG TIN
  Future<void> _executeSingleItemPayment(CartItem item) async {
    bool? confirmPayment = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Xác nhận thanh toán',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LUÔN hiển thị thông tin giao hàng để user kiểm tra
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Thông tin giao hàng:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),
                    Text('Số điện thoại: ${_phoneController.text.trim()}'),
                    SizedBox(height: 4),
                    Text('Địa chỉ: ${_addressController.text.trim()}'),
                    SizedBox(height: 12),
                  ],
                ),
                Text(
                  'Sản phẩm: ${item.productName}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Số lượng: ${item.quantity}',
                ),
                Text(
                  'Tổng tiền: ${currencyFormatter.format(parsePrice(item.price) * item.quantity)}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                SizedBox(height: 8),
                Text('Bạn có chắc chắn muốn mua sản phẩm này?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Xác nhận', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmPayment == true) {
      setState(() {
        isLoading = true;
      });

      try {
        print('=== EXECUTING SINGLE ITEM PAYMENT ===');
        print('Product: ${item.productName}');
        print('Quantity: ${item.quantity}');
        print('Using phone: ${_phoneController.text.trim()}');
        print('Using address: ${_addressController.text.trim()}');

        final success = await _cartService.processSingleItemPayment(
          currentUser!.id,
          item,
          _phoneController.text.trim(),
          _addressController.text.trim(),
        );

        if (success) {
          // SỬA: Chỉ xóa sản phẩm đã thanh toán
          setState(() {
            cartItems.removeWhere((cartItem) => cartItem.id == item.id);
          });
          _showSuccessMessage('Thanh toán thành công');

          print('=== AFTER SINGLE ITEM PAYMENT ===');
          print('Remaining cart items: ${cartItems.length}');
        } else {
          _showErrorMessage('Thanh toán thất bại');
        }
      } catch (e) {
        print('Single item payment error: $e');
        _showErrorMessage('Thanh toán thất bại: ${e.toString()}');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  // ... (phần còn lại của code giữ nguyên - _updateQuantity, _buildQuantityControls, build, etc.)

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
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: isUpdating
                ? null
                : () => _updateQuantity(item, item.quantity - 1),
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUpdating ? Colors.grey.shade300 : Colors.red,
              ),
              child: Icon(Icons.remove, size: 18, color: Colors.white),
            ),
          ),
          SizedBox(width: 12),
          Text(
            item.quantity.toString(),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 12),
          InkWell(
            onTap: isUpdating
                ? null
                : () => _updateQuantity(item, item.quantity + 1),
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUpdating ? Colors.grey.shade300 : Colors.green,
              ),
              child: Icon(Icons.add, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          appBar: AppBar(
            title:
                Text('GIỎ HÀNG', style: TextStyle(fontWeight: FontWeight.w600)),
            centerTitle: true,
            automaticallyImplyLeading: false,
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
          body: Center(
              child: CircularProgressIndicator(
                  color: Colors.lightBlueAccent.shade700)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('GIỎ HÀNG', style: TextStyle(fontWeight: FontWeight.w600)),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey.shade400),
                  SizedBox(height: 16),
                  Text(
                    'Giỏ hàng trống',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return AnimatedOpacity(
                  opacity: isUpdating && cartItems.contains(item) ? 0.7 : 1.0,
                  duration: Duration(milliseconds: 200),
                  child: Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                              ),
                              child: item.image.isNotEmpty
                                  ? Image.network(
                                      item.image,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                        Icons.broken_image,
                                        color: Colors.grey.shade400,
                                        size: 40,
                                      ),
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    (loadingProgress
                                                            .expectedTotalBytes ??
                                                        1)
                                                : null,
                                            color:
                                                Colors.lightBlueAccent.shade700,
                                          ),
                                        );
                                      },
                                    )
                                  : Icon(
                                      Icons.image,
                                      color: Colors.grey.shade400,
                                      size: 40,
                                    ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Giá: ${currencyFormatter.format(parsePrice(item.price))}',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.blueAccent),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text('Size: ${item.size}',
                                          style: TextStyle(fontSize: 12)),
                                    ),
                                    SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Text('Màu: ',
                                              style: TextStyle(fontSize: 12)),
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color:
                                                  _getColorFromHex(item.color),
                                              border: Border.all(
                                                  color: Colors.grey.shade400),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        child: _buildQuantityControls(item)),
                                    Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.black12,
                                                Colors.lightBlueAccent.shade700,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 4,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: isLoading
                                                ? null
                                                : () =>
                                                    _processSingleItemPayment(
                                                        item),
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: Size(80, 32),
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'Buy',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.red, size: 20),
                                          onPressed: isUpdating
                                              ? null
                                              : () => _removeCartItem(item),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cartItems.isEmpty ? null : _buildBottomBar(),
    );
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

  Widget _buildBottomBar() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.all(16),
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
                'Tổng tiền:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                currencyFormatter.format(getTotalPriceInVND()),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black12,
                  Colors.lightBlueAccent.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Đang xử lý...',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    )
                  : Text(
                      'Buy All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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
      await _cartService.removeCartItem(currentUser!.id, item.productId);
      setState(() {
        cartItems.remove(item);
      });
      _showSuccessMessage('Đã xóa sản phẩm khỏi giỏ hàng');
    } catch (e) {
      print('Lỗi xóa sản phẩm: $e');
      _showErrorMessage('Không thể xóa sản phẩm');
    }
  }

  double getTotalPriceInVND() {
    return cartItems.fold(
      0.0,
      (total, item) => total + (parsePrice(item.price) * item.quantity),
    );
  }
}
