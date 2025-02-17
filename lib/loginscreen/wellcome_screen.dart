import 'package:app_neaker/loginscreen/login_screen.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
    _controller.forward();
    Future.delayed(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Stack(
          children: [
            // Background gradient
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white24,
                    Colors.lightBlueAccent.shade700,
                  ],
                ),
              ),
            ),
            // Gradient overlay for better text visibility
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Animated logo with drop shadow and custom border
            Center(
              child: Opacity(
                opacity: _animation.value,
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 10.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.black,
                      width: 3,
                    ),
                    shape: BoxShape.circle,
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
            ),
            // Text elements with improved styles and positioning
            Positioned(
              top:
                  MediaQuery.of(context).size.height * 0.2, // Center vertically
              left: MediaQuery.of(context).size.width *
                  0.1, // Add padding from left
              right: MediaQuery.of(context).size.width *
                  0.1, // Add padding from right
              child: Text(
                'SneaSto', // Replace with your app name
                style: TextStyle(
                    fontSize: 50.0, // Larger title font
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Pacifico' // Add a playful font for variety
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height *
                  0.35, // Adjust for spacing
              left: MediaQuery.of(context).size.width * 0.1, // Align with title
              right: MediaQuery.of(context).size.width *
                  0.1, // Add padding from right
              child: Text(
                'Welcome to SneaSto!',
                style: TextStyle(
                    fontSize: 20.0,
                    color: Colors.white,
                    fontFamily: 'Roboto' // Use a clean and readable font
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            // Animated circular progress indicator (optional)
            Positioned(
              bottom: 50.0, // Position higher for balance
              left: MediaQuery.of(context).size.width * 0.45,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
