import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/employee/employee_dashboard.dart';
import '../screens/employee/salary_screen.dart';
import '../screens/employee/upload_screen.dart';
import '../screens/admin/employee_monitor_dashboard.dart';

/// AppRoutes - Centralized navigation with named routes
/// Benefits:
/// 1. Type-safe navigation
/// 2. Easy to manage all routes
/// 3. Can add route guards/middleware
class AppRoutes {
  AppRoutes._();

  // ==========================================
  // ROUTE NAMES
  // ==========================================
  static const String login = '/login';
  static const String adminDashboard = '/admin';
  static const String employeeDashboard = '/employee';
  static const String salaryScreen = '/salary';
  static const String uploadScreen = '/upload';
  static const String employeeMonitor = '/employee-monitor';

  // ==========================================
  // ROUTE MAP
  // ==========================================
  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginScreen(),
    adminDashboard: (context) => const AdminDashboard(),
    employeeDashboard: (context) => const EmployeeDashboard(),
    salaryScreen: (context) => const SalaryScreen(),
    uploadScreen: (context) => const UploadScreen(),
  };

  // ==========================================
  // NAVIGATION HELPERS
  // ==========================================
  
  /// Navigate to a named route
  static void navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  /// Navigate and replace current route
  static void navigateReplace(BuildContext context, String routeName) {
    Navigator.pushReplacementNamed(context, routeName);
  }

  /// Navigate and clear all previous routes
  static void navigateAndClearStack(BuildContext context, String routeName) {
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
  }

  /// Navigate to employee monitor with arguments
  static void navigateToEmployeeMonitor(
    BuildContext context, {
    required String employeeId,
    required String employeeName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeMonitorDashboard(
          employeeId: employeeId,
          employeeName: employeeName,
        ),
      ),
    );
  }

  /// Navigate to a widget directly
  static void navigateToWidget(BuildContext context, Widget widget) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => widget),
    );
  }

  /// Pop to previous screen
  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }

  /// Pop with result
  static void goBackWithResult<T>(BuildContext context, T result) {
    Navigator.pop(context, result);
  }

  /// Pop until a specific route
  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }
}
