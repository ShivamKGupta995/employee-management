import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Config
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'config/constants/app_strings.dart';

// Screens
import 'screens/splash_screen.dart'; // ✅ Create this file next

// Services
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Notifications
  await NotificationService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      // We use the light theme as base, but our Luxury UI overrides specific screens
      theme: AppTheme.lightTheme, 
      // ✅ Set SplashScreen as the home
      home: const SplashScreen(),
    );
  }
}