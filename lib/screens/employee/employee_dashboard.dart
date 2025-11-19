import 'package:employee_system/screens/login_screen.dart';
import 'package:employee_system/screens/notifications_screen.dart'; // Reuse your existing screen
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Ensure intl is in pubspec.yaml

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define Pages
    final List<Widget> pages = [
      HomeTab(name: employeeName, dept: employeeDept),
      const AttendanceTab(),
      const NotificationsScreen(), // Reusing the screen we made earlier
      ProfileTab(name: employeeName, dept: employeeDept),
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
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(Icons.access_time_filled),
            label: 'Attendance',
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
// 1. HOME TAB (Clock In & Overview)
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

  // Toggle Clock In/Out
  Future<void> _handleClockInOut() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    
    // 1. Create a record in Firestore
    // Note: In a real app, you would check if they already clocked in today first.
    await FirebaseFirestore.instance.collection('attendance').add({
      'uid': user!.uid,
      'name': widget.name,
      'timestamp': FieldValue.serverTimestamp(),
      'type': isClockedIn ? 'Clock Out' : 'Clock In',
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    });

    await Future.delayed(const Duration(seconds: 1)); // Fake delay for UI

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
          // Header
          Container(
            padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    widget.name.isNotEmpty ? widget.name[0].toUpperCase() : "E",
                    style: TextStyle(fontSize: 24, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Welcome back,", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    Text(
                      widget.name,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.dept,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body Content
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
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 5),
                        StreamBuilder(
                          stream: Stream.periodic(const Duration(seconds: 1)),
                          builder: (context, snapshot) {
                            return Text(
                              DateFormat('hh:mm:ss a').format(DateTime.now()),
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: isLoading ? null : _handleClockInOut,
                          child: Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isClockedIn ? Colors.red.shade50 : Colors.green.shade50,
                              border: Border.all(
                                color: isClockedIn ? Colors.red : Colors.green,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isClockedIn ? Colors.red : Colors.green).withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                )
                              ]
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.fingerprint,
                                  size: 40,
                                  color: isClockedIn ? Colors.red : Colors.green,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  isClockedIn ? "Clock Out" : "Clock In",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isClockedIn ? Colors.red : Colors.green,
                                  ),
                                ),
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

                  // Grid Actions
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 1.5,
                    children: [
                      _buildActionCard(Icons.calendar_today, "My Holidays", Colors.orange),
                      _buildActionCard(Icons.receipt_long, "Salary Slip", Colors.purple),
                      _buildActionCard(Icons.assignment, "Apply Leave", Colors.blue),
                      _buildActionCard(Icons.contact_phone, "Emergency", Colors.red),
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

  Widget _buildActionCard(IconData icon, String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 5, spreadRadius: 1),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ==================================================
// 2. ATTENDANCE TAB (Simple List)
// ==================================================

class AttendanceTab extends StatelessWidget {
  const AttendanceTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(title: const Text("My Attendance")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('uid', isEqualTo: user?.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading data"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No attendance records found."));

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isClockIn = data['type'] == 'Clock In';
              Timestamp ts = data['timestamp'];
              String time = DateFormat('h:mm a').format(ts.toDate());
              String date = DateFormat('MMM d, yyyy').format(ts.toDate());

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isClockIn ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    child: Icon(
                      isClockIn ? Icons.login : Icons.logout,
                      color: isClockIn ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(data['type']),
                  subtitle: Text(date),
                  trailing: Text(
                    time,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
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

  const ProfileTab({Key? key, required this.name, required this.dept}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
       Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 50),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: Text(name.isNotEmpty ? name[0] : "U", style: const TextStyle(fontSize: 40, color: Colors.blue)),
            ),
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(dept, style: const TextStyle(color: Colors.grey)),
          
          const SizedBox(height: 30),
          
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Personal Information"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text("Change Password"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
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