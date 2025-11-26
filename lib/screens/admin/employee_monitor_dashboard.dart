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
// 1. LIVE MAP TAB (OPTIMIZED FOR ADMIN UX)
// ===================================================
class _LiveMapTab extends StatefulWidget {
  final String employeeId;
  const _LiveMapTab({Key? key, required this.employeeId}) : super(key: key);

  @override
  State<_LiveMapTab> createState() => _LiveMapTabState();
}

class _LiveMapTabState extends State<_LiveMapTab> {
  GoogleMapController? _mapController;
  bool _isFirstLoad = true;

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user')
          .doc(widget.employeeId)
          .snapshots(),
      builder: (context, snapshot) {
        // 1. Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. No Data
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Employee data not found"));
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;

        // 3. Check for Location Data
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

        // 4. Parse Data
        double lat = (data['current_lat'] as num).toDouble();
        double lng = (data['current_lng'] as num).toDouble();
        LatLng pos = LatLng(lat, lng);
        double speed = (data['speed'] as num?)?.toDouble() ?? 0.0;

        // 5. Calculate "Online" Status
        Timestamp? ts = data['last_seen'];
        bool isOnline = false;
        String statusText = "Offline";
        Color statusColor = Colors.grey;

        if (ts != null) {
          final lastSeen = ts.toDate();
          final diff = DateTime.now().difference(lastSeen).inMinutes;
          
          if (diff < 5) {
            isOnline = true;
            statusText = "🟢 Live Now (${(speed * 3.6).toStringAsFixed(1)} km/h)"; // Speed in km/h
            statusColor = Colors.green;
          } else {
            statusText = "🔴 Last seen $diff min ago";
            statusColor = Colors.red;
          }
        }

        // 6. Camera Handling (Only move on first load to avoid jitter)
        if (_isFirstLoad && _mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLng(pos));
          _isFirstLoad = false;
        }

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: pos, zoom: 15),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              markers: {
                Marker(
                  markerId: const MarkerId('emp'),
                  position: pos,
                  // Use a colored icon based on status if you have assets, 
                  // otherwise default red pin is standard.
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    isOnline ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed
                  ),
                  infoWindow: InfoWindow(
                    title: "Employee Location",
                    snippet: statusText,
                  ),
                )
              },
            ),

            // --- UI ELEMENT 1: STATUS PILL ---
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, color: statusColor, size: 14),
                    const SizedBox(width: 10),
                    Text(
                      statusText,
                      style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ],
                ),
              ),
            ),

            // --- UI ELEMENT 2: CONTROLS ---
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  // Re-Center Button
                  FloatingActionButton(
                    heroTag: "center",
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.blue),
                    onPressed: () {
                      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
                    },
                  ),
                  const SizedBox(width: 15),
                  // Navigate Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openGoogleMaps(lat, lng),
                      icon: const Icon(Icons.directions),
                      label: const Text("NAVIGATE"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                ],
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