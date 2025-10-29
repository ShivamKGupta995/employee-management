import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        // Add any other screens here
        // '/adminDashboard': (context) => AdminDashboard(),
      },
      title: 'OSC Employee Portal',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFD4AF37), // Gold color
        fontFamily: 'Poppins',
        

      ),
      home: LoginScreen(), // 👈 Start from login screen
    );
  }
}
