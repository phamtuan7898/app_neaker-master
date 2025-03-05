import 'package:app_neaker/home/main_screen.dart';
import 'package:app_neaker/service/auth_service%20.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _inputController =
      TextEditingController(); // TextField dùng chung cho email/username
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  // Thêm biến để theo dõi trạng thái đăng nhập
  bool _isLoggingIn = false;
  // Thêm biến để theo dõi trạng thái hiển thị mật khẩu
  bool _passwordVisible = false;

  void _login() async {
    // Nếu đang trong quá trình đăng nhập, không thực hiện thêm
    if (_isLoggingIn) return;

    // Đặt trạng thái đăng nhập thành true và cập nhật UI
    setState(() {
      _isLoggingIn = true;
    });

    // Thêm delay trước khi gửi yêu cầu đăng nhập
    // Bạn có thể điều chỉnh thời gian theo mong muốn (đơn vị: milliseconds)
    await Future.delayed(Duration(milliseconds: 2000));

    try {
      final user = await _authService.login(
        _inputController.text,
        _passwordController.text,
      );

      // Thêm delay sau khi nhận phản hồi từ server nhưng trước khi chuyển màn hình
      // Đảm bảo người dùng thấy được trạng thái đang đăng nhập
      await Future.delayed(Duration(milliseconds: 1000));

      if (user != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(userId: user.id)),
          (Route<dynamic> route) => false, // Xóa tất cả các trang trước đó
        );
      }
    } catch (e) {
      // Thêm delay trước khi hiển thị thông báo lỗi
      await Future.delayed(Duration(milliseconds: 500));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed')),
      );

      // Đặt lại trạng thái khi đăng nhập thất bại
      setState(() {
        _isLoggingIn = false;
      });
    }
  }

  // Thêm hàm để toggle trạng thái hiển thị mật khẩu
  void _togglePasswordVisibility() {
    setState(() {
      _passwordVisible = !_passwordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Vô hiệu hóa nút quay lại vật lý
      child: Scaffold(
        appBar: AppBar(
          title: Text('Log in'),
          centerTitle: true,
          backgroundColor: Colors.white24,
          foregroundColor: Colors.black,
          automaticallyImplyLeading: false, // Ẩn nút back trên AppBar
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white24,
                Colors.lightBlueAccent.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(seconds: 1),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 3),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10.0,
                              spreadRadius: 2.0,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/img_logo/modern-sneaker-shoe-logo-vector.jpg',
                            width: 150,
                            height: 150,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildTextField(
                      controller: _inputController,
                      label: 'Username or Email',
                      icon: Icons.person,
                      enabled: !_isLoggingIn,
                    ),
                    SizedBox(height: 16),
                    _buildPasswordField(),
                    SizedBox(height: 20),
                    _buildElevatedButton(),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: _isLoggingIn
                          ? null
                          : () {
                              Navigator.pushNamed(context, '/forgot-password');
                            },
                      child: Text('Forgot Password?',
                          style: TextStyle(
                              color: _isLoggingIn ? Colors.grey : Colors.black,
                              fontSize: 16)),
                    ),
                    TextButton(
                      onPressed: _isLoggingIn
                          ? null
                          : () {
                              Navigator.pushNamed(context, '/register');
                            },
                      child: Text('Register',
                          style: TextStyle(
                              color: _isLoggingIn ? Colors.grey : Colors.black,
                              fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true, // Thêm tham số enabled với giá trị mặc định là true
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled, // Sử dụng tham số enabled
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.black54, fontSize: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(icon, color: Colors.black),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.black,
            ),
          ),
        ),
        obscureText: obscureText,
      ),
    );
  }

  // Thêm widget riêng cho trường mật khẩu có chức năng hiển thị/ẩn
  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        enabled: !_isLoggingIn,
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: TextStyle(color: Colors.black54, fontSize: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(Icons.lock, color: Colors.black),
          suffixIcon: IconButton(
            icon: Icon(
              // Thay đổi icon dựa trên trạng thái hiển thị
              _passwordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.black54,
            ),
            onPressed: !_isLoggingIn ? _togglePasswordVisibility : null,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: Colors.black,
            ),
          ),
        ),
        obscureText:
            !_passwordVisible, // Đảo ngược giá trị để kiểm soát hiển thị mật khẩu
      ),
    );
  }

  Widget _buildElevatedButton() {
    return Container(
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
        onPressed:
            _isLoggingIn ? null : _login, // Vô hiệu hóa khi đang đăng nhập
        child: _isLoggingIn
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
                  SizedBox(width: 10),
                  Text(
                    'Logging in...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              )
            : Text(
                'Log in',
                style: TextStyle(color: Colors.white),
              ),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 50),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          textStyle: TextStyle(
            fontSize: 18,
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
