import 'package:employee_system/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'manage_employees.dart';
import 'notifications_screen.dart';
import 'attendance.dart';
import 'reports.dart';
import 'settings.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
   Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      // Navigate back to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during logout: $e")),
      );
    }
  }
  
  final List<Widget> _pages = [
    const DashboardHome(),
    const ManageEmployeesScreen(),
    const NotificationsScreen(),
    const AttendanceScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Manage Employees',
    'Notifications',
    'Attendance',
    'Reports',
    'Settings',
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // close drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.blueAccent,
         actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView.builder(
          itemCount: _titles.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Icon(Icons.circle),
              title: Text(_titles[index]),
              selected: _selectedIndex == index,
              onTap: () => _onItemSelected(index),
            );
          },
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Welcome Admin 👋\nSelect an option from the menu',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
