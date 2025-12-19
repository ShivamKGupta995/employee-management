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

  DateTime? _selectedDate;
  List<LatLng> _historyPoints = [];

  // ─────────────────────────────────────────────
  // OPEN GOOGLE MAPS NAVIGATION
  // ─────────────────────────────────────────────
  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ─────────────────────────────────────────────
  // PICK DATE (LAST 45 DAYS ONLY)
  // ─────────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 45)),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _historyPoints.clear();
      });
      await _loadHistoryForDay(picked);
    }
  }

  // ─────────────────────────────────────────────
  // LOAD HISTORY FOR SELECTED DAY ONLY
  // ─────────────────────────────────────────────
  Future<void> _loadHistoryForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final snapshot = await FirebaseFirestore.instance
        .collection('user')
        .doc(widget.employeeId)
        .collection('location_history')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThan: end)
        .orderBy('timestamp')
        .get();

    final points = snapshot.docs.map((doc) {
      final data = doc.data();
      return LatLng(
        (data['lat'] as num).toDouble(),
        (data['lng'] as num).toDouble(),
      );
    }).toList();

    if (mounted) {
      setState(() => _historyPoints = points);
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user')
          .doc(widget.employeeId)
          .snapshots(),
      builder: (context, liveSnapshot) {
        if (!liveSnapshot.hasData || !liveSnapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = liveSnapshot.data!.data() as Map<String, dynamic>;

        if (!data.containsKey('current_lat') ||
            !data.containsKey('current_lng')) {
          return const Center(child: Text("Tracking not started"));
        }

        final LatLng livePos = LatLng(
          (data['current_lat'] as num).toDouble(),
          (data['current_lng'] as num).toDouble(),
        );

        // ───────── ONLINE STATUS ─────────
        Timestamp? ts = data['last_seen'];
        bool isOnline = false;
        String statusText = "Offline";
        Color statusColor = Colors.red;

        if (ts != null) {
          final diff = DateTime.now().difference(ts.toDate()).inMinutes;
          if (diff < 5) {
            isOnline = true;
            statusText = "🟢 Live Now";
            statusColor = Colors.green;
          } else {
            statusText = "🔴 Last seen $diff min ago";
          }
        }

        if (_isFirstLoad && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(livePos, 15),
          );
          _isFirstLoad = false;
        }

        return Stack(
          children: [
            // ───────── GOOGLE MAP ─────────
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: livePos, zoom: 15),
              onMapCreated: (controller) => _mapController = controller,

              // HISTORY ROUTE (ONE DAY ONLY)
              polylines: _historyPoints.length > 1
                  ? {
                      Polyline(
                        polylineId: const PolylineId("history"),
                        points: _historyPoints,
                        color: Colors.blueAccent,
                        width: 5,
                      ),
                    }
                  : {},

              // LIVE MARKER
              markers: {
                Marker(
                  markerId: const MarkerId("live"),
                  position: livePos,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    isOnline
                        ? BitmapDescriptor.hueGreen
                        : BitmapDescriptor.hueRed,
                  ),
                  infoWindow: InfoWindow(
                    title: "Employee",
                    snippet: statusText,
                  ),
                ),
              },
            ),

            // ───────── STATUS PILL ─────────
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, color: statusColor, size: 12),
                    const SizedBox(width: 10),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ───────── DATE PICKER BUTTON ─────────
            Positioned(
              top: 80,
              right: 20,
              child: FloatingActionButton(
                heroTag: "date",
                backgroundColor: Colors.white,
                child: const Icon(Icons.calendar_month, color: Colors.blue),
                onPressed: _pickDate,
              ),
            ),

            // ───────── CONTROLS ─────────
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  FloatingActionButton(
                    heroTag: "center",
                    backgroundColor: Colors.white,
                    child:
                        const Icon(Icons.my_location, color: Colors.blue),
                    onPressed: () {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(livePos, 16),
                      );
                    },
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _openGoogleMaps(livePos.latitude, livePos.longitude),
                      icon: const Icon(Icons.directions),
                      label: const Text("NAVIGATE"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user')
          .doc(employeeId)
          .collection('synced_contacts')
          .orderBy('displayName')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No contacts synced",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;

            final String name = data['displayName'] ?? 'Unknown';
            final List phones = data['phones'] ?? [];
            final List emails = data['emails'] ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ───── HEADER ─────
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFEEF2FF),
                          child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5E4B8B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ───── PHONES ─────
                    if (phones.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      ...phones.map((p) {
                        final phone = p.toString();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 18,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  phone,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.call,
                                  color: Colors.green,
                                ),
                                onPressed: () =>
                                    launchUrl(Uri.parse("tel:$phone")),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // ───── EMAILS ─────
                    if (emails.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...emails.map((e) {
                        final email = e.toString();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.email_outlined,
                                size: 18,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  email,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
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