import 'package:employee_system/screens/admin/employee_list_monitor.dart';
import 'package:employee_system/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Import your screens
import 'manage_employees.dart';
import 'notifications_screen.dart';
import 'attendance.dart';
import 'reports.dart';
import 'settings.dart';
import 'generate_salary_screen.dart';
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // 1. Define the GlobalKey
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  int _selectedIndex = 0;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Define Titles & Icons for the Drawer
  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard_rounded},
    {'title': 'Employees', 'icon': Icons.people_alt_rounded},
    {'title': 'Notifications', 'icon': Icons.notifications_active_rounded},
    {'title': 'Attendance', 'icon': Icons.access_time_filled_rounded},
    {'title': 'Generate Salary', 'icon': Icons.attach_money_rounded},
    {'title': 'Monitoring', 'icon': Icons.monitor_rounded},
    {'title': 'Reports', 'icon': Icons.bar_chart_rounded},
    {'title': 'Settings', 'icon': Icons.settings_rounded},
  ];

  // 2. FIXED Function to Switch Tabs
  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Use the key to safely close the drawer ONLY if it is open
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  Future<void> _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      try {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardHome(onSwitchTab: _onItemSelected),
      const ManageEmployeesScreen(),
      const NotificationsScreen(),
      const AttendanceScreen(),
      const GenerateSalaryScreen(),
      const EmployeeListMonitor(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      // 3. Assign the Key here
      key: _scaffoldKey, 
      appBar: AppBar(
        title: Text(_menuItems[_selectedIndex]['title']),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[900]!, Colors.blue[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              accountName: const Text(
                "Admin Portal",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: Text(currentUser?.email ?? "admin@company.com"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.blue),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final bool isSelected = _selectedIndex == index;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Icon(
                        _menuItems[index]['icon'],
                        color: isSelected ? Colors.blue[800] : Colors.grey[600],
                      ),
                      title: Text(
                        _menuItems[index]['title'],
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.blue[800] : Colors.black87,
                        ),
                      ),
                      onTap: () => _onItemSelected(index),
                    ),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Version 1.0.0", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: pages[_selectedIndex],
      ),
    );
  }
}

// ==================================================
//  DASHBOARD HOME 
// ==================================================

class DashboardHome extends StatelessWidget {
  final Function(int) onSwitchTab;

  const DashboardHome({Key? key, required this.onSwitchTab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Overview",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('user').where('role', isEqualTo: 'employee').snapshots(),
                builder: (context, snapshot) {
                  String count = "...";
                  if (snapshot.hasData) {
                    count = snapshot.data!.docs.length.toString();
                  }
                  return _buildStatCard("Total Staff", count, Icons.people, Colors.blue);
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('announcements').snapshots(),
                builder: (context, snapshot) {
                  String count = "...";
                  if (snapshot.hasData) count = snapshot.data!.docs.length.toString();
                  return _buildStatCard("Notices", count, Icons.campaign, Colors.orange);
                },
              ),
              _buildStatCard("Present Today", "12", Icons.check_circle, Colors.green),
              _buildStatCard("On Leave", "2", Icons.beach_access, Colors.redAccent),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context, 
                  "Post Notice", 
                  Icons.send, 
                  Colors.indigo,
                  () => onSwitchTab(2), // Switch to Index 2
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  context, 
                  "Add Employee", 
                  Icons.person_add, 
                  Colors.teal,
                  () => onSwitchTab(1), // Switch to Index 1
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}