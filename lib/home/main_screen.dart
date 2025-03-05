import 'package:app_neaker/home/cart_screen.dart';
import 'package:app_neaker/home/home_screen.dart';
import 'package:app_neaker/home/profile_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  final String userId;
  const MainScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      WillPopScope(
        onWillPop: () async => false,
        child: HomeScreen(),
      ),
      WillPopScope(
        onWillPop: () async => false,
        child: CartScreen(),
      ),
      WillPopScope(
        onWillPop: () async => false,
        child: ProfileViewScreen(userId: widget.userId),
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        // Giữ nguyên phần bottom navigation bar
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        selectedIconTheme: IconThemeData(size: 30),
        unselectedIconTheme: IconThemeData(size: 24),
      ),
    );
  }
}
