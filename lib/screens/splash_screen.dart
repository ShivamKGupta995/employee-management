import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Constants & Colors
import 'package:employee_system/config/constants/app_colors.dart';
import 'package:employee_system/config/constants/firebase_collections.dart';

// Destination Screens
import 'package:employee_system/screens/login_screen.dart';
import 'package:employee_system/screens/admin/admin_dashboard.dart';
import 'package:employee_system/screens/employee/employee_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartUpLogic();
  }

  Future<void> _handleStartUpLogic() async {
    // Luxury wait time
    await Future.delayed(const Duration(milliseconds: 2800));

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _navigateTo(const LoginScreen());
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? role = prefs.getString(FirebaseCollections.fieldRole);

    if (role == null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .doc(user.uid)
            .get();
            
        if (doc.exists) {
          role = doc[FirebaseCollections.fieldRole];
          await prefs.setString(FirebaseCollections.fieldRole, role ?? FirebaseCollections.roleEmployee);
        }
      } catch (e) {
        debugPrint('Auth Error: $e');
      }
    }

    if (role == FirebaseCollections.roleAdmin) {
      _navigateTo(const AdminDashboard());
    } else if (role == FirebaseCollections.roleEmployee) {
      _navigateTo(const EmployeeDashboard());
    } else {
      _navigateTo(const LoginScreen());
    }
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxDarkGreen,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.luxBgGradient),
        child: Center( // ✅ Added Center to fix the 99k pixel overflow
          child: Column(
            mainAxisSize: MainAxisSize.min, // ✅ Prevent column from taking infinite space
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Branded Scaling Animation
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1500),
                // ✅ Changed to easeOutCubic: Beautiful, smooth, and NEVER goes above 1.0
                curve: Curves.easeOutCubic, 
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2), // Scales from 0.8 to 1.0
                    child: Opacity(
                      opacity: value, // Now perfectly safe (0.0 to 1.0)
                      child: Image.asset(
                        'assets/images/osc-light.png',
                        width: 180,
                        color: AppColors.luxGold,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              
              const Text(
                "OSC SYSTEMS",
                style: TextStyle(
                  color: AppColors.luxGold,
                  fontSize: 14,
                  letterSpacing: 10,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'serif',
                ),
              ),
              
              const SizedBox(height: 80),
              
              const SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.luxGold),
                  minHeight: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}