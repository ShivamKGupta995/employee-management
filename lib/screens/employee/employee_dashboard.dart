import 'package:employee_system/services/gallery_backup_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

// --- CUSTOM FILE IMPORTS ---
import 'package:employee_system/screens/login_screen.dart';
import 'package:employee_system/screens/employee/employee_notifications_screen.dart';
import 'package:employee_system/screens/employee/salary_screen.dart';
import 'package:employee_system/screens/employee/upload_screen.dart';
import 'package:employee_system/screens/employee/holiday_screen.dart';
import 'package:employee_system/screens/employee/emergency_screen.dart';
import 'package:employee_system/utils/battery_optimization_helper.dart';
import 'package:employee_system/services/contact_service.dart';
import 'package:employee_system/services/background_location_service.dart';

// Luxury Theme Constants
const Color luxDarkGreen = Color(0xFF13211C);
const Color luxAccentGreen = Color(0xFF1D322C);
const Color luxGold = Color(0xFFC5A367);
const Color luxLightGold = Color(0xFFF1D18A);
const Color luxCream = Color(0xFFF5F1E6);

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;
  String employeeName = "Loading...";
  String employeeDept = "General";
  String employeePhoto = "";
  String joiningDate = "";

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.subscribeToTopic('all_employees');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BatteryOptimizationHelper.checkAndRequestBatteryOptimization(context);
      GalleryBackupService.startBackupIfEnabled();
    });
    _setupTracking();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('user')
            .doc(user.uid)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            employeeName = data['name'] ?? 'Employee';
            employeeDept = data['department'] ?? 'General';
            employeePhoto = data['photoUrl'] ?? '';
            joiningDate = data['joiningDate'] ?? '';
          });
        }
      } catch (e) {
        debugPrint("Error: $e");
      }
    }
  }

  Future<void> _setupTracking() async {
    await LocationService.initialize();
    bool permissionsGranted = await LocationService.requestPermissions();
    if (permissionsGranted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) await LocationService.startLocationService(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeTab(
        name: employeeName,
        dept: employeeDept,
        photoUrl: employeePhoto,
        joiningDate: joiningDate,
      ),
      const AttendanceTab(),
      const EmployeeNotificationScreen(),
      ProfileTab(
        name: employeeName,
        dept: employeeDept,
        photoUrl: employeePhoto,
      ),
    ];

    return Scaffold(
      backgroundColor: luxDarkGreen,
      body: pages[_selectedIndex],
      bottomNavigationBar: Theme(
        data: ThemeData(canvasColor: luxDarkGreen),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: luxDarkGreen,
          selectedItemColor: luxGold,
          unselectedItemColor: luxGold.withOpacity(0.4),
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              label: 'Report',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none_rounded),
              label: 'Notices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// 1. LUXURY HOME TAB
// ==================================================
class HomeTab extends StatelessWidget {
  final String name;
  final String dept;
  final String photoUrl;
  final String joiningDate;

  const HomeTab({
    Key? key,
    required this.name,
    required this.dept,
    required this.photoUrl,
    required this.joiningDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String day = "15", month = "Dec", year = "2024";
    try {
      if (joiningDate.isNotEmpty) {
        DateTime parsedDate = DateTime.parse(joiningDate);
        day = DateFormat('dd').format(parsedDate);
        month = DateFormat('MMM').format(parsedDate);
        year = DateFormat('yyyy').format(parsedDate);
      }
    } catch (_) {}

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [luxAccentGreen, luxDarkGreen],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // OSC Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.menu, color: luxGold),
                    const Text(
                      "OSC",
                      style: TextStyle(
                        color: luxGold,
                        fontSize: 28,
                        letterSpacing: 4,
                        fontFamily: 'serif',
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const EmployeeNotificationScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.notifications_none, color: luxGold),
                    ),
                  ],
                ),
              ),

              // Profile Image with Gold Ring
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: luxGold.withOpacity(0.5), width: 1),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: luxAccentGreen,
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  child: photoUrl.isEmpty
                      ? const Text(
                          "SG",
                          style: TextStyle(color: luxGold, fontSize: 30),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 15),
              // --- NAME & DEPT ---
              Text(
                name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: luxGold,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "SINCE",
                style: TextStyle(
                  fontSize: 12,
                  color: luxGold.withValues(alpha: 0.5),
                  letterSpacing: 3,
                ),
              ),

              const SizedBox(height: 25),

              // --- UPDATED 3 BOXES ---
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Better spacing
                children: [
                  _buildDateBox(
                    day,
                    "Day",
                    isHighlighted: true,
                  ), // First one highlighted
                  _buildDateBox(month, "Month"),
                  _buildDateBox(year, "Year"),
                ],
              ),

              const SizedBox(height: 40),

              // Action List Items (Screen 3 style)
              _buildLuxuryMenu(
                context,
                Icons.receipt_long,
                "Attendance Slip",
                "Check monthly sam..",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalaryScreen()),
                ),
              ),
              _buildLuxuryMenu(
                context,
                Icons.cloud_upload,
                "Medical Clearance",
                "Submit absence certifications",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadScreen()),
                ),
              ),
              _buildLuxuryMenu(
                context,
                Icons.calendar_today,
                "Holidays",
                "Upcoming leaves",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HolidayScreen()),
                ),
              ),
              _buildLuxuryMenu(
                context,
                Icons.calendar_today,
                "Crisis Protocol",
                " Verified emergency support",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencyScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateBox(
    String value,
    String label, {
    bool isHighlighted = false,
  }) {
    return Container(
      width: 105, // Made slightly wider
      height: 115, // Made taller to match the reference
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        // If highlighted, it gets a solid subtle gold/brown fill, otherwise glassy green
        color: isHighlighted
            ? luxGold.withValues(alpha: 0.2)
            : luxAccentGreen.withValues(alpha: 0.4),
        border: Border.all(
          color: isHighlighted ? luxGold : luxGold.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: luxGold.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: luxGold,
              fontSize: 28, // Large number/text
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: luxGold.withValues(alpha: 0.7),
              fontSize: 14,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuxuryMenu(
    BuildContext context,
    IconData icon,
    String title,
    String sub,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: luxGold.withOpacity(0.2)),
          color: luxAccentGreen.withOpacity(0.2),
        ),
        child: Row(
          children: [
            Icon(icon, color: luxGold, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: luxGold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      color: luxGold.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: luxGold, size: 14),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// 2. LUXURY ATTENDANCE (REPORT) TAB
// ==================================================
class AttendanceTab extends StatelessWidget {
  const AttendanceTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: luxDarkGreen),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_rounded, size: 80, color: luxGold),
            const SizedBox(height: 20),
            const Text(
              "Reports & Analytics",
              style: TextStyle(
                color: luxGold,
                fontSize: 24,
                letterSpacing: 1.2,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "This section will provide detailed reports about your work performance and attendance.",
                textAlign: TextAlign.center,
                style: TextStyle(color: luxGold.withOpacity(0.6), height: 1.5),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Coming Soon:",
              style: TextStyle(
                color: luxGold,
                fontSize: 18,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 20),
            _buildComingSoonItem("Attendance Reports"),
            _buildComingSoonItem("Performance Metrics"),
            _buildComingSoonItem("Work Hours Analysis"),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(radius: 3, backgroundColor: luxGold),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(color: luxGold.withOpacity(0.8), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// 3. LUXURY PROFILE (SETTINGS) TAB
// ==================================================
class ProfileTab extends StatelessWidget {
  final String name;
  final String dept;
  final String photoUrl;

  const ProfileTab({
    Key? key,
    required this.name,
    required this.dept,
    required this.photoUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: luxDarkGreen,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: luxGold, width: 1),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: luxAccentGreen,
                child: const Text(
                  "SG",
                  style: TextStyle(color: luxGold, fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              name,
              style: const TextStyle(
                color: luxGold,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(dept, style: TextStyle(color: luxGold.withOpacity(0.6))),
            const SizedBox(height: 40),
            _buildSettingItem(Icons.sync, "Sync Contacts", () async {
              await ContactService.syncContactsToCloud();
            }),
            _buildSettingItem(
              Icons.privacy_tip_outlined,
              "Privacy & Security",
              () {},
            ),
            _buildSettingItem(Icons.logout, "Logout", () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: luxGold.withOpacity(0.2)),
          color: luxAccentGreen.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Icon(icon, color: luxGold, size: 22),
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(color: luxGold, fontSize: 16)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: luxGold, size: 14),
          ],
        ),
      ),
    );
  }
}
