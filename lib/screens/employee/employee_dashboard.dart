import 'package:employee_system/services/gallery_backup_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart'; // Required for Date Formatting

// --- CUSTOM FILE IMPORTS (Ensure these exist in your project) ---
import 'package:employee_system/screens/login_screen.dart';
import 'package:employee_system/screens/employee/employee_notifications_screen.dart';
import 'package:employee_system/screens/employee/salary_screen.dart';
import 'package:employee_system/screens/employee/upload_screen.dart';
import 'package:employee_system/screens/employee/holiday_screen.dart';
import 'package:employee_system/screens/employee/emergency_screen.dart';
import 'package:employee_system/utils/battery_optimization_helper.dart';
import 'package:employee_system/services/contact_service.dart';
import 'package:employee_system/services/background_location_service.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({Key? key}) : super(key: key);

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;
  
  // Data Variables
  String employeeName = "Loading...";
  String employeeDept = "General";
  String employeePhoto = "";
  String joiningDate = ""; // format: YYYY-MM-DD

  void _onItemTapped(int index) {
  setState(() {
    _selectedIndex = index;
  });
}


  @override
  void initState() {
    super.initState();
    
    // 1. Subscribe to Notifications
    FirebaseMessaging.instance.subscribeToTopic('all_employees');

    // 2. Check Battery Optimization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BatteryOptimizationHelper.checkAndRequestBatteryOptimization(context);
    });


    // 3. Start Location & Fetch Data
    _setupTracking();
    _fetchUserDetails();
   // 🔥 AUTO BACKUP CHECK (BACKGROUND)
      WidgetsBinding.instance.addPostFrameCallback((_) {
      GalleryBackupService.startBackupIfEnabled();
    });
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

        // 🔄 AUTO CONTACT SYNC LOGIC (NEW)
        Timestamp? lastSyncTs = data['lastContactSync'];
        DateTime? lastSyncDate = lastSyncTs?.toDate();

        bool shouldSync = false;

        if (lastSyncDate == null) {
          shouldSync = true; // Never synced
        } else {
          final daysDiff =
              DateTime.now().difference(lastSyncDate).inDays;
          if (daysDiff >= 30) {
            shouldSync = true; // Older than 30 days
          }
        }

        if (shouldSync) {
          debugPrint("🔄 Auto-syncing contacts...");
          ContactService.syncContactsToCloud().then((res) {
            debugPrint("Contact auto-sync result: $res");
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }
}


  

 Future<void> _setupTracking() async {
  // 1️⃣ Initialize background service (no tracking yet)
  await LocationService.initialize();

  // 2️⃣ Check & request permissions
  bool permissionsGranted = await LocationService.requestPermissions();
  if (!permissionsGranted) {
    debugPrint("❌ Required permissions not granted. Tracking not started.");
    return;
  }

  // 3️⃣ Ensure GPS is enabled (foreground UI allowed)
  bool gpsEnabled = await Geolocator.isLocationServiceEnabled();
  if (!gpsEnabled && mounted) {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Enable Location"),
        content: const Text(
          "Location services are disabled. Please enable GPS to allow tracking.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Geolocator.openLocationSettings();
              Navigator.pop(context);
            },
            child: const Text("Enable GPS"),
          ),
        ],
      ),
    );

    // Recheck GPS after dialog
    gpsEnabled = await Geolocator.isLocationServiceEnabled();
    if (!gpsEnabled) {
      debugPrint("❌ GPS still disabled. Tracking aborted.");
      return;
    }
  }

  // 4️⃣ Start tracking only if user is logged in
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await LocationService.startLocationService(user.uid);
    debugPrint("✅ Background location tracking started");
  }
}


  @override
  Widget build(BuildContext context) {
    // Define Pages
    final List<Widget> pages = [
      HomeTab(
        name: employeeName, 
        dept: employeeDept, 
        photoUrl: employeePhoto, 
        joiningDate: joiningDate
      ), 
      const AttendanceTab(),
      const EmployeeNotificationScreen(), 
      ProfileTab(name: employeeName, dept: employeeDept, photoUrl: employeePhoto), 
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9), // Matches the soft UI background
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: const Color(0xFFB5A0D9).withOpacity(0.3), // Soft Purple
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF5E4B8B)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded, color: Color(0xFF5E4B8B)),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_rounded, color: Color(0xFF5E4B8B)),
            label: 'Notices',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF5E4B8B)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ==================================================
// 1. HOME TAB (SOFT UI MATCHING REFERENCE)
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
    // Logic to parse the date into Day, Month, Year
    String day = "--";
    String month = "--";
    String year = "--";

    try {
      if (joiningDate.isNotEmpty) {
        // Tries to parse standard formats like 2024-05-14
        DateTime parsedDate = DateTime.parse(joiningDate); 
        day = DateFormat('dd').format(parsedDate);
        month = DateFormat('MMM').format(parsedDate); // e.g. May
        year = DateFormat('yy').format(parsedDate);   // e.g. 24
      } else {
        // Fallback defaults if empty
        day = "01"; month = "Jan"; year = "25";
      }
    } catch (e) {
       // Fallback if parse fails
       day = "??"; month = "???"; year = "??";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F9), // Light Grey Background
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            children: [
              // --- TOP NAVIGATION ---
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     _buildTopIcon(Icons.arrow_back_ios_new, () {
              //       // Logic for back or drawer if needed
              //     }),
              //     _buildTopIcon(Icons.logout_rounded, () async {
              //       await FirebaseAuth.instance.signOut();
              //       if (context.mounted) {
              //         Navigator.of(context).pushAndRemoveUntil(
              //             MaterialPageRoute(builder: (context) => const LoginScreen()),
              //             (route) => false);
              //       }
              //     }),
              //   ],
              // ),

              // const SizedBox(height: 30),

              // --- BIG PROFILE PHOTO ---
              // --- BIG PROFILE PHOTO (Updated) ---
              Container(
                padding: const EdgeInsets.all(2), // Adds a white border ring
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white, // Color of the ring
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15), // Slightly darker for depth
                      blurRadius: 25,
                      spreadRadius: 5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 65, // Reduced size (was 60)
                  // backgroundColor: Colors.grey.shade100,
                  backgroundImage: (photoUrl.isNotEmpty) 
                      ? NetworkImage(photoUrl) 
                      : null,
                  child: (photoUrl.isEmpty)
                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : "E", 
                          style: const TextStyle(
                            fontSize: 35, // Adjusted text size
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5E4B8B) // Matching the purple theme
                          ))
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              
              // --- NAME & DEPT ---
              Text(
                name,
                style: const TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D2D2D),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Since".toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 20),

              // --- 3 BOXES (JOINING DATE) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoBox(day, "Day", isActive: true),
                  _buildInfoBox(month, "Month"),
                  _buildInfoBox("20$year", "Year"),
                ],
              ),

              const SizedBox(height: 35),

              // --- ACTION LIST ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFFF3E5F5), // Light Purple
                      iconColor: const Color(0xFF9C27B0),
                      title: "Salary Slip",
                      subtitle: "Check monthly earnings",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalaryScreen())),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.cloud_upload_rounded,
                      color: const Color(0xFFE3F2FD), // Light Blue
                      iconColor: const Color(0xFF2196F3),
                      title: "Upload Work",
                      subtitle: "Submit daily evidence",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen())),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.calendar_month_rounded,
                      color: const Color(0xFFFFF3E0), // Light Orange
                      iconColor: const Color(0xFFFF9800),
                      title: "Holidays",
                      subtitle: "Upcoming leaves",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HolidayScreen())),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.phonelink_ring_rounded,
                      color: const Color(0xFFFFEBEE), // Light Red
                      iconColor: const Color(0xFFF44336),
                      title: "Emergency",
                      subtitle: "SOS Contacts",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen())),
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER: TOP BUTTONS ---
  Widget _buildTopIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }

  // --- WIDGET HELPER: THE 3 SQUARES ---
  Widget _buildInfoBox(String value, String label, {bool isActive = false}) {
    return Container(
      width: 100,
      height: 105,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFB5A0D9) : Colors.white, // Purple if active
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: const Color(0xFFB5A0D9).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          else
             BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isActive ? Colors.white.withOpacity(0.8) : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: LIST ITEMS ---
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================
// 2. ATTENDANCE TAB (Monthly Report)
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Monthly Report", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F5F9),
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
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('monthly_stats').doc(docId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(child: Text("No report for $_selectedMonth $_selectedYear", style: TextStyle(color: Colors.grey[400])));
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
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 5, backgroundColor: color),
              const SizedBox(width: 15),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ==================================================
// 3. PROFILE TAB
// ==================================================
class ProfileTab extends StatelessWidget {
  final String name;
  final String dept;
  final String photoUrl;

  const ProfileTab({Key? key, required this.name, required this.dept, required this.photoUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Settings", style: TextStyle(color: Colors.black)), centerTitle: true, elevation: 0, backgroundColor: Colors.white),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: (photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                child: (photoUrl.isEmpty) ? Text(name.isNotEmpty ? name[0] : "U", style: const TextStyle(fontSize: 40)) : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(dept, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            _buildProfileItem(context, Icons.sync, "Sync Contacts", () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Syncing contacts...")));
              String res = await ContactService.syncContactsToCloud();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
            }),
            _buildProfileItem(context, Icons.security, "Privacy & Security", () {}),
            _buildProfileItem(context, Icons.logout, "Logout", () async {
               await FirebaseAuth.instance.signOut();
               if(context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: isDestructive ? Colors.red[50] : Colors.blue[50], borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: isDestructive ? Colors.red : Colors.blue),
      ),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }
}