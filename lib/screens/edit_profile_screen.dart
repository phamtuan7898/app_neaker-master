import 'dart:io';
import 'package:app_neaker/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileEditScreen extends StatefulWidget {
  final String userId;
  const ProfileEditScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late ApiService apiService;
  final ImagePicker _picker = ImagePicker();

  // Controllers for editable fields
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  String? absoluteImagePath;

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
        absoluteImagePath = fetchedUser.img;
        usernameController.text = fetchedUser.username ?? '';
        emailController.text = fetchedUser.email ?? '';
        phoneController.text = fetchedUser.phone ?? '';
        addressController.text = fetchedUser.address ?? '';
      });
    }
  }

  Future<void> saveProfileChanges() async {
    final updatedData = {
      'username': usernameController.text,
      'email': emailController.text,
      'phone': phoneController.text,
      'address': addressController.text,
    };
    final success =
        await apiService.updateUserProfile(widget.userId, updatedData);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context, true); // Return `true` to indicate success
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile.')),
      );
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      uploadImage(File(pickedFile.path));
    }
  }

  Future<void> uploadImage(File imageFile) async {
    final uploadSuccess =
        await apiService.uploadProfileImage(widget.userId, imageFile);
    if (uploadSuccess) {
      fetchUserProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'EDIT PROFILE',
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
        child: ListView(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: absoluteImagePath != null
                    ? NetworkImage('${apiService.baseUrl}/$absoluteImagePath')
                    : null,
                child: absoluteImagePath == null
                    ? Icon(Icons.camera_alt, size: 60, color: Colors.grey)
                    : null,
              ),
            ),
            SizedBox(height: 16),
            _buildTextField(usernameController, 'User name', Icons.person),
            SizedBox(height: 16),
            _buildTextField(emailController, 'Email', Icons.email),
            SizedBox(height: 16),
            _buildTextField(phoneController, 'Phone number', Icons.phone),
            SizedBox(height: 16),
            _buildTextField(addressController, 'Address', Icons.home),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
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
            onPressed: saveProfileChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.transparent, // Ensure the gradient is visible
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(vertical: 16.0),
              textStyle: TextStyle(fontSize: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            child: Text(
              'Save changes',
              style: TextStyle(color: Colors.black, fontSize: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        prefixIcon: Icon(icon),
      ),
    );
  }
}
