import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployeeMonitorDashboard extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeMonitorDashboard({
    Key? key,
    required this.employeeId,
    required this.employeeName,
  }) : super(key: key);

  @override
  State<EmployeeMonitorDashboard> createState() => _EmployeeMonitorDashboardState();
}

class _EmployeeMonitorDashboardState extends State<EmployeeMonitorDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tracking: ${widget.employeeName}"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Live Map", icon: Icon(Icons.location_on)),
            Tab(text: "Contacts", icon: Icon(Icons.contacts)),
            Tab(text: "Gallery", icon: Icon(Icons.image)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: MAP
          _LiveMapTab(employeeId: widget.employeeId),
          
          // TAB 2: CONTACTS (Synced from Employee)
          _ContactsTab(employeeId: widget.employeeId),
          
          // TAB 3: IMAGES (Uploaded by Employee)
          _ImagesTab(employeeId: widget.employeeId),
        ],
      ),
    );
  }
}

// ===================================================
// 1. LIVE MAP TAB (FIXED for 'user' collection)
// ===================================================
class _LiveMapTab extends StatelessWidget {
  final String employeeId;
  const _LiveMapTab({Key? key, required this.employeeId}) : super(key: key);

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch Google Maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>( // Changed to DocumentSnapshot
      // FIX 1: Listen to the 'user' collection, specific employee doc
      stream: FirebaseFirestore.instance
          .collection('user') 
          .doc(employeeId)
          .snapshots(),
      builder: (context, snapshot) {
        // 1. Handle Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Handle Errors or Missing User
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Employee data not found"));
        }

        // 3. Get Data
        var data = snapshot.data!.data() as Map<String, dynamic>;

        // FIX 2: Check if 'current_lat' exists (Employee might have logged in but not started service yet)
        if (!data.containsKey('current_lat') || !data.containsKey('current_lng')) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 50, color: Colors.grey),
                SizedBox(height: 10),
                Text("Employee has not started tracking yet."),
              ],
            ),
          );
        }
        
        // FIX 3: Use the fields written by your LocationService
        // ✅ SAFE WAY (Converts both Int and Double to Double)
        double lat = (data['current_lat'] as num).toDouble();
        double lng = (data['current_lng'] as num).toDouble();
        LatLng pos = LatLng(lat, lng);
        
        // Optional: Get Last Seen time
        Timestamp? ts = data['last_seen'];
        String timeStr = ts != null 
            ? "${ts.toDate().hour}:${ts.toDate().minute}" 
            : "Unknown";

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: pos, zoom: 15),
              markers: {
                Marker(
                  markerId: const MarkerId('emp'),
                  position: pos,
                  infoWindow: InfoWindow(
                    title: "Current Location",
                    snippet: "Last Update: $timeStr",
                  ),
                )
              },
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: () => _openGoogleMaps(lat, lng),
                icon: const Icon(Icons.navigation),
                label: const Text("NAVIGATE TO EMPLOYEE"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(15),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
// ===================================================
// 2. CONTACTS TAB (Synced Data)
// ===================================================
class _ContactsTab extends StatelessWidget {
  final String employeeId;
  const _ContactsTab({Key? key, required this.employeeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Assumes Employee App uploads contacts to a sub-collection
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user')
          .doc(employeeId)
          .collection('synced_contacts')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No contacts synced."));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index];
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(data['name'] ?? 'Unknown'),
              subtitle: Text(data['phone'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.call, color: Colors.green),
                onPressed: () => launchUrl(Uri.parse("tel:${data['phone']}")),
              ),
            );
          },
        );
      },
    );
  }
}

// ===================================================
// 3. IMAGES TAB (Uploaded Data)
// ===================================================
class _ImagesTab extends StatelessWidget {
  final String employeeId;
  const _ImagesTab({Key? key, required this.employeeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('uploads') // Assuming a collection for uploads
          .where('uid', isEqualTo: employeeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No images uploaded."));

        return GridView.builder(
          padding: const EdgeInsets.all(10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index];
            return GestureDetector(
              onTap: () {
                // Show full screen image logic here
              },
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(data['url']),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        );
      },
    );
  }
}