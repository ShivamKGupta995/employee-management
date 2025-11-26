import 'package:employee_system/utils/battery_optimization_helper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

// IMPORTS (Make sure you have these files created from previous steps)
import 'package:employee_system/screens/login_screen.dart';
import 'package:employee_system/screens/employee/employee_notifications_screen.dart';
import 'package:employee_system/screens/employee/salary_screen.dart';
import 'package:employee_system/screens/employee/upload_screen.dart';
import 'package:employee_system/services/contact_service.dart';
import 'package:employee_system/services/background_location_service.dart'; // If you have this file

import 'package:employee_system/services/background_location_service.dart'; // If you have this file
class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;
  String employeeName = "Employee";
  String employeeDept = "General";

  @override
  void initState() {
    super.initState();
    
    // 1. Subscribe to Notifications
    FirebaseMessaging.instance.subscribeToTopic('all_employees');

    // 2. Setup & Start Location Service
    // ✅ CHECK BATTERY OPTIMIZATION FIRST
  WidgetsBinding.instance.addPostFrameCallback((_) {
    BatteryOptimizationHelper.checkAndRequestBatteryOptimization(context);
  });

  // Setup Tracking
  _setupTracking();

    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('user').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          employeeName = doc['name'] ?? 'Employee';
          employeeDept = doc['department'] ?? 'General';
        });
      }
    }
  }


Future<void> _setupTracking() async {
  print("🔧 Setting up tracking...");
  
  // 1. Initialize Service
  await LocationService.initialize();
  print("✅ Service initialized");

  // 2. Check GPS is ON
  bool gpsEnabled = await Geolocator.isLocationServiceEnabled();
  if (!gpsEnabled) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("GPS Required"),
          content: const Text("Please enable GPS/Location Services to use tracking."),
          actions: [
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                Navigator.pop(context);
              },
              child: const Text("Open Settings"),
            ),
          ],
        ),
      );
    }
    return;
  }

  // 3. Request Permissions
  bool hasPermissions = await LocationService.requestPermissions();
  print("📋 Permissions granted: $hasPermissions");

  if (!hasPermissions) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Permissions Required"),
          content: const Text(
            "This app needs:\n"
            "• Location: ALLOW ALL THE TIME\n"
            "• Notifications: Allow\n\n"
            "Please grant these permissions in Settings.",
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Geolocator.openAppSettings();
                Navigator.pop(context);
              },
              child: const Text("Open Settings"),
            ),
          ],
        ),
      );
    }
    return;
  }

  // 4. Test GPS Before Starting Service
  try {
    print("🧪 Testing GPS signal...");
    Position testPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    ).timeout(const Duration(seconds: 15));
    
    print("✅ GPS Test Successful: ${testPosition.latitude}, ${testPosition.longitude}");
  } catch (e) {
    print("❌ GPS Test Failed: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("GPS signal is weak. Please move to an open area.\nError: $e"),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
    // Don't return - still start the service, it will keep trying
  }

  // 5. Start Service
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await LocationService.startLocationService(user.uid);
    print("✅ Location service started");
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Location tracking started successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define Pages
    final List<Widget> pages = [
      HomeTab(name: employeeName, dept: employeeDept), // Home
      const AttendanceTab(), // Monthly Report (Updated below)
      const EmployeeNotificationScreen(), // Read-Only Notices (Updated)
      ProfileTab(name: employeeName, dept: employeeDept), // Profile
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
        indicatorColor: Colors.blue.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notices',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ==================================================
// 1. HOME TAB (Clock In & Quick Actions)
// ==================================================
class HomeTab extends StatefulWidget {
  final String name;
  final String dept;

  const HomeTab({Key? key, required this.name, required this.dept}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool isClockedIn = false;
  bool isLoading = false;

  Future<void> _handleClockInOut() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    
    // Log to Firestore
    await FirebaseFirestore.instance.collection('attendance').add({
      'uid': user!.uid,
      'name': widget.name,
      'timestamp': FieldValue.serverTimestamp(),
      'type': isClockedIn ? 'Clock Out' : 'Clock In',
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    });

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        isClockedIn = !isClockedIn;
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isClockedIn ? "Clocked IN Successfully" : "Clocked OUT Successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade500],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(widget.name.isNotEmpty ? widget.name[0].toUpperCase() : "E", style: TextStyle(fontSize: 24, color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Welcome back,", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(widget.dept, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // BODY
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CLOCK IN CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)],
                    ),
                    child: Column(
                      children: [
                        Text(DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()), style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 5),
                        StreamBuilder(
                          stream: Stream.periodic(const Duration(seconds: 1)),
                          builder: (context, snapshot) {
                            return Text(DateFormat('hh:mm:ss a').format(DateTime.now()), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold));
                          },
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: isLoading ? null : _handleClockInOut,
                          child: Container(
                            height: 150, width: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isClockedIn ? Colors.red.shade50 : Colors.green.shade50,
                              border: Border.all(color: isClockedIn ? Colors.red : Colors.green, width: 2),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fingerprint, size: 40, color: isClockedIn ? Colors.red : Colors.green),
                                const SizedBox(height: 10),
                                Text(isClockedIn ? "Clock Out" : "Clock In", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isClockedIn ? Colors.red : Colors.green)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  // GRID ACTIONS (LINKED)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.5,
                    children: [
                      // Link to Salary Screen
                      _buildActionCard(context, Icons.receipt_long, "Salary Slip", Colors.purple, () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const SalaryScreen()));
                      }),
                      // Link to Upload Screen
                      _buildActionCard(context, Icons.camera_alt, "Upload Evidence", Colors.orange, () {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()));
                      }),
                      _buildActionCard(context, Icons.assignment, "Apply Leave", Colors.blue, () {
                        // Add Leave Screen navigation if you have it
                      }),
                      _buildActionCard(context, Icons.contact_phone, "Emergency", Colors.red, () {
                        // Add Emergency Screen navigation if you have it
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 5, spreadRadius: 1)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ==================================================
// 2. ATTENDANCE TAB (Updated to Monthly Report)
// ==================================================
class AttendanceTab extends StatefulWidget {
  const AttendanceTab({Key? key}) : super(key: key);

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  String _selectedMonth = "November"; 
  String _selectedYear = "2025";

  final List<String> _months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  final List<String> _years = ["2024", "2025", "2026"];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String docId = "${user!.uid}_${_selectedMonth}_$_selectedYear";

    return Scaffold(
      appBar: AppBar(title: const Text("Monthly Report"), centerTitle: true, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: DropdownButtonHideUnderline(child: DropdownButton(value: _selectedMonth, items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) => setState(() => _selectedMonth = v.toString())))),
                  const VerticalDivider(),
                  DropdownButtonHideUnderline(child: DropdownButton(value: _selectedYear, items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(), onChanged: (v) => setState(() => _selectedYear = v.toString()))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Report
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('monthly_stats').doc(docId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text("No report found for this month."));
                  }
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  return Column(
                    children: [
                      _buildStatCard("Present", "${data['present']} Days", Colors.green),
                      _buildStatCard("Absent", "${data['absent']} Days", Colors.red),
                      _buildStatCard("Late", "${data['late']} Days", Colors.orange),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(Icons.circle, color: color, size: 15)),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ==================================================
// 3. PROFILE TAB (Updated with Sync)
// ==================================================
class ProfileTab extends StatelessWidget {
  final String name;
  final String dept;

  const ProfileTab({Key? key, required this.name, required this.dept}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
       Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 50),
          Center(child: CircleAvatar(radius: 50, backgroundColor: Colors.blue.shade100, child: Text(name.isNotEmpty ? name[0] : "U", style: const TextStyle(fontSize: 40, color: Colors.blue)))),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(dept, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          
          // Sync Contacts Button
          ListTile(
            leading: const Icon(Icons.sync, color: Colors.blue),
            title: const Text("Sync Contacts"),
            subtitle: const Text("Backup phonebook to cloud"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Syncing contacts...")));
              String res = await ContactService.syncContactsToCloud();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}