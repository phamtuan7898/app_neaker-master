import 'package:app_neaker/home/home_screen.dart';
import 'package:app_neaker/loginscreen/forgot_password_screen.dart';
import 'package:app_neaker/loginscreen/login_screen.dart';
import 'package:app_neaker/loginscreen/register_screen.dart';
import 'package:app_neaker/loginscreen/wellcome_screen.dart';
import 'package:app_neaker/utils/server_tester.dart'; // Thêm import
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test server connection
  await ServerTester.testAllEndpoints();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: WelcomeScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
