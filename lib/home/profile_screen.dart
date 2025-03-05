import 'package:app_neaker/models/user_model.dart';
import 'package:app_neaker/screens/changepass_screen.dart';
import 'package:app_neaker/screens/edit_profile_screen.dart';
import 'package:app_neaker/screens/order_tracking_screen.dart';
import 'package:app_neaker/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileViewScreen extends StatefulWidget {
  final String userId;
  const ProfileViewScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileViewScreenState createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  late ApiService apiService;
  UserModel? user;
  final TextEditingController _passwordController = TextEditingController();
  // Thêm biến để kiểm soát hiển thị mật khẩu
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    final fetchedUser = await apiService.getUserProfile(widget.userId);
    if (fetchedUser != null) {
      setState(() {
        user = fetchedUser;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user profile.')),
      );
    }
  }

  Future<void> confirmDeleteAccount() async {
    // Reset giá trị ban đầu của _passwordVisible và _passwordController
    setState(() {
      _passwordVisible = false;
      _passwordController.clear();
    });

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text('Delete Account',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Please enter your password to confirm account deletion:'),
                SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setStateDialog(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final success = await apiService.deleteAccount(
                    widget.userId,
                    _passwordController.text,
                  );

                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Account deleted successfully')),
                    );
                    // Navigate to login screen and clear navigation stack
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (Route<dynamic> route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete account')),
                    );
                  }
                },
                child:
                    Text('Confirm', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          );
        });
      },
    );
  }

  // Thêm hàm confirmSignOut để hiển thị dialog xác nhận
  Future<void> confirmSignOut() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Sign Out',
              style:
                  TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Đóng dialog
                await signOut(); // Thực hiện đăng xuất
              },
              child: Text('Sign Out', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('PROFILE', style: TextStyle(fontWeight: FontWeight.w600)),
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
          automaticallyImplyLeading: false, // Ẩn nút back trên AppBar
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              if (user != null) ...[
                CircleAvatar(
                  radius: 60,
                  backgroundImage: user!.img != null && user!.img!.isNotEmpty
                      ? NetworkImage('${apiService.baseUrl}/${user!.img}')
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: user!.img == null
                      ? Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
                SizedBox(height: 16),
                Text(
                  user!.username ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  user!.email ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                ),
                SizedBox(height: 20),
                Divider(color: Colors.grey[400]),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Phone: ${user!.phone ?? ''}',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Address: ${user!.address ?? ''}',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Divider(color: Colors.grey[400]),
              ],
              ListTile(
                leading: Icon(Icons.edit),
                title: Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 16),
                ),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileEditScreen(userId: widget.userId),
                    ),
                  );
                  if (result == true) {
                    fetchUserProfile(); // Refresh the profile data after editing
                  }
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.local_shipping, color: Colors.green),
                title: Text('My Orders', style: TextStyle(fontSize: 16)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderTrackingScreen(),
                    ),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.lock, color: Colors.amber),
                title: Text('Change Password', style: TextStyle(fontSize: 16)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChangePasswordScreen(userId: widget.userId),
                    ),
                  );
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete Account', style: TextStyle(fontSize: 16)),
                onTap: confirmDeleteAccount,
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.blue),
                title: Text('Sign Out', style: TextStyle(fontSize: 16)),
                onTap:
                    confirmSignOut, // Thay đổi từ signOut sang confirmSignOut
              ),
            ],
          ),
        ),
      ),
    );
  }
}
