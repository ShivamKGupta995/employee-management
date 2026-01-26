import 'package:employee_system/screens/admin/attendance_intel_screen.dart';
import 'package:employee_system/screens/admin/birthday_month_screen.dart';
import 'package:employee_system/screens/admin/employee_list_monitor.dart';
import 'package:employee_system/screens/admin/leaderboard_screen.dart';
import 'package:employee_system/screens/admin/settings_screen.dart';
import 'package:employee_system/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Import your screens (ensure these paths are correct)
import 'manage_emergency_screen.dart' show ManageEmergencyScreen;
import 'manage_employees.dart';
import 'notifications_screen.dart';
import 'attendance.dart';
import 'reports.dart';
import 'generate_salary_screen.dart';
import 'manage_holidays_screen.dart';

// Luxury Theme Constants
const Color luxDarkGreen = Color(0xFF13211C);
const Color luxAccentGreen = Color(0xFF1D322C);
const Color luxGold = Color(0xFFC5A367);
const Color luxLightGold = Color(0xFFF1D18A);

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard_outlined},
    {'title': 'Employees', 'icon': Icons.people_outline_rounded},
    {'title': 'Leader Board', 'icon': Icons.leaderboard_outlined},
     {'title': 'Attendance Intel', 'icon': Icons.analytics_outlined}, // NEW
  {'title': 'Birthdays', 'icon': Icons.cake_outlined}, 
    {'title': 'Notifications', 'icon': Icons.campaign_outlined},
    {'title': 'Gen Attendance', 'icon': Icons.payments_outlined},
    {'title': 'Monitoring', 'icon': Icons.monitor_heart_outlined},
    // {'title': 'Reports', 'icon': Icons.analytics_outlined},
    {'title': 'Manage Holidays', 'icon': Icons.calendar_today_outlined},
    {'title': 'Crisis Protocol', 'icon': Icons.shield_outlined},
    {'title': 'Settings', 'icon': Icons.settings_outlined},
  ];

  void _onItemSelected(int index) {
    setState(() => _selectedIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  Future<void> _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: luxDarkGreen,
        shape: RoundedRectangleBorder(side: const BorderSide(color: luxGold, width: 0.5), borderRadius: BorderRadius.circular(15)),
        title: const Text("TERMINATE SESSION", style: TextStyle(color: luxGold, letterSpacing: 2, fontSize: 16, fontFamily: 'serif')),
        content: const Text("Are you sure you want to exit the admin portal?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL", style: TextStyle(color: luxGold))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("LOGOUT", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardHome(onSwitchTab: _onItemSelected),
      const ManageEmployeesScreen(),
      const PerformanceLeaderboard(),
       const AttendanceIntelScreen(), // NEW (Code below)
  const BirthdayMonthScreen(),  
      const NotificationsScreen(),
      const GenerateSalaryScreen(),
      const EmployeeListMonitor(),
      // const ReportsScreen(),
      const ManageHolidaysScreen(),
      const ManageEmergencyScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: luxDarkGreen,
      appBar: AppBar(
        title: Text(_menuItems[_selectedIndex]['title'].toUpperCase(), 
          style: const TextStyle(letterSpacing: 3, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: luxGold,
        actions: [
          IconButton(icon: const Icon(Icons.power_settings_new_rounded), onPressed: _logout),
        ],
      ),
      drawer: _buildLuxuryDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment.center, radius: 1.5, colors: [luxAccentGreen, luxDarkGreen]),
        ),
        child: pages[_selectedIndex],
      ),
    );
  }

  Widget _buildLuxuryDrawer() {
    return Drawer(
      backgroundColor: luxDarkGreen,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            width: double.infinity,
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: luxGold.withValues(alpha: 0.2)))),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: luxGold, width: 1)),
                  child: const CircleAvatar(
                    radius: 35,
                    backgroundColor: luxAccentGreen,
                    child: Icon(Icons.admin_panel_settings_outlined, size: 40, color: luxGold),
                  ),
                ),
                const SizedBox(height: 15),
                const Text("ADMIN PORTAL", style: TextStyle(color: luxGold, fontSize: 18, letterSpacing: 4, fontFamily: 'serif')),
                Text(currentUser?.email ?? "admin@osc.com", style: TextStyle(color: luxGold.withValues(alpha: 0.5), fontSize: 11)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final bool isSelected = _selectedIndex == index;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 25),
                  leading: Icon(_menuItems[index]['icon'], color: isSelected ? luxGold : luxGold.withValues(alpha: 0.4)),
                  title: Text(_menuItems[index]['title'].toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? luxGold : luxGold.withValues(alpha: 0.6),
                      )),
                  selected: isSelected,
                  selectedTileColor: luxGold.withValues(alpha: 0.05),
                  onTap: () => _onItemSelected(index),
                );
              },
            ),
          ),
          const Divider(color: luxGold, thickness: 0.1),
          const Padding(padding: EdgeInsets.all(16.0), child: Text("OSC EXECUTIVE v1.0", style: TextStyle(color: luxGold, fontSize: 10, letterSpacing: 2))),
        ],
      ),
    );
  }
}

// ==================================================
//  DASHBOARD HOME (REDESIGNED)
// ==================================================

class DashboardHome extends StatelessWidget {
  final Function(int) onSwitchTab;
  const DashboardHome({Key? key, required this.onSwitchTab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("OVERVIEW", style: TextStyle(fontSize: 14, color: luxGold, letterSpacing: 3, fontWeight: FontWeight.bold, fontFamily: 'serif')),
          const SizedBox(height: 20),
          
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('user').where('role', isEqualTo: 'employee').snapshots(),
                builder: (context, snapshot) {
                  return _buildStatCard("Total Staff", snapshot.hasData ? snapshot.data!.docs.length.toString() : "...", Icons.people_outline);
                },
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('announcements').snapshots(),
                builder: (context, snapshot) {
                  return _buildStatCard("Notices", snapshot.hasData ? snapshot.data!.docs.length.toString() : "...", Icons.campaign_outlined);
                },
              ),
              _buildStatCard("Attendance", "94%", Icons.verified_outlined),
              _buildStatCard("Pending", "03", Icons.hourglass_empty_outlined),
            ],
          ),

          const SizedBox(height: 40),
          const Text("QUICK ACTIONS", style: TextStyle(fontSize: 14, color: luxGold, letterSpacing: 3, fontWeight: FontWeight.bold, fontFamily: 'serif')),
          const SizedBox(height: 15),
          
          Row(
            children: [
              Expanded(child: _buildActionButton("Notice", Icons.send_outlined, () => onSwitchTab(5))),
              const SizedBox(width: 15),
              Expanded(child: _buildActionButton("Onboard User", Icons.person_add_outlined, () => onSwitchTab(1))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: luxAccentGreen.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: luxGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: luxGold, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'serif')),
          const SizedBox(height: 4),
          Text(title.toUpperCase(), style: TextStyle(color: luxGold.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(colors: [luxLightGold, luxGold], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: luxDarkGreen, size: 18),
            const SizedBox(width: 10),
            Text(label.toUpperCase(), style: const TextStyle(color: luxDarkGreen, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

}