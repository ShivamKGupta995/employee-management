import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Config
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'config/constants/app_strings.dart';
import 'config/constants/firebase_collections.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/employee/employee_dashboard.dart';

// Services
import 'services/notification_service.dart';

// Widgets
import 'widgets/common/loading_indicator.dart';

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
      theme: AppTheme.lightTheme,
      // darkTheme: AppTheme.darkTheme, // Uncomment for dark mode support
      home: const AuthCheck(),
    );
  }
}

/// AuthCheck - Handles authentication state and role-based routing
class AuthCheck extends StatelessWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: LoadingIndicator()),
          );
        }

        // Not logged in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // Logged in - check role
        return FutureBuilder<String?>(
          future: _getUserRole(snapshot.data!.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: LoadingIndicator()),
              );
            }

            final role = roleSnapshot.data;

            if (role == FirebaseCollections.roleAdmin) {
              return const AdminDashboard();
            } else if (role == FirebaseCollections.roleEmployee) {
              return const EmployeeDashboard();
            } else {
              // Unknown role - go to login
              return const LoginScreen();
            }
          },
        );
      },
    );
  }

  /// Get user role from cache or Firestore
  Future<String?> _getUserRole(String uid) async {
    // Try to get from local cache first (faster)
    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString(FirebaseCollections.fieldRole);

    if (role != null) return role;

    // Fetch from Firestore if not cached
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirebaseCollections.users)
          .doc(uid)
          .get();
          
      if (doc.exists) {
        role = doc[FirebaseCollections.fieldRole];
        // Cache for next time
        await prefs.setString(FirebaseCollections.fieldRole, role ?? FirebaseCollections.roleEmployee);
        return role;
      }
    } catch (e) {
      debugPrint('Error getting user role: $e');
    }
    
    return null;
  }
}
