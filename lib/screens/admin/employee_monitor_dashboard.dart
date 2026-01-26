import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:employee_system/config/constants/app_colors.dart'; // Adjust path

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
      backgroundColor: AppColors.luxDarkGreen,
      appBar: AppBar(
        title: Text(widget.employeeName.toUpperCase(), 
          style: const TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.luxGold,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.luxGold,
          labelColor: AppColors.luxGold,
          unselectedLabelColor: AppColors.luxGold.withValues(alpha: 0.4),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
          tabs: const [
            Tab(text: "LIVE RADAR", icon: Icon(Icons.satellite_alt_outlined)),
            Tab(text: "INTEL / CONTACTS", icon: Icon(Icons.folder_shared_outlined)),
            Tab(text: "VISUAL LOGS", icon: Icon(Icons.photo_library_outlined)),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.luxBgGradient),
        child: TabBarView(
          controller: _tabController,
          children: [
            _LiveMapTab(employeeId: widget.employeeId),
            _ContactsTab(employeeId: widget.employeeId),
            _ImagesTab(employeeId: widget.employeeId),
          ],
        ),
      ),
    );
  }
}

// ===================================================
// 1. LIVE MAP TAB (LUXURY REDESIGN)
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

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 45)),
      lastDate: now,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.luxGold, onPrimary: AppColors.luxDarkGreen, surface: AppColors.luxAccentGreen),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadHistoryForDay(picked);
    }
  }

  Future<void> _loadHistoryForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final snapshot = await FirebaseFirestore.instance
        .collection('user').doc(widget.employeeId).collection('location_history')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThan: start.add(const Duration(days: 1)))
        .orderBy('timestamp').get();

    final points = snapshot.docs.map((doc) => LatLng((doc['lat'] as num).toDouble(), (doc['lng'] as num).toDouble())).toList();
    if (mounted) setState(() => _historyPoints = points);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('user').doc(widget.employeeId).snapshots(),
      builder: (context, liveSnapshot) {
        if (!liveSnapshot.hasData || !liveSnapshot.data!.exists) return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));

        final data = liveSnapshot.data!.data() as Map<String, dynamic>;
        if (!data.containsKey('current_lat')) return const Center(child: Text("OFFLINE", style: TextStyle(color: AppColors.luxGold, letterSpacing: 2)));

        final LatLng livePos = LatLng((data['current_lat'] as num).toDouble(), (data['current_lng'] as num).toDouble());
        Timestamp? ts = data['last_seen'];
        bool isOnline = ts != null && DateTime.now().difference(ts.toDate()).inMinutes < 5;

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: livePos, zoom: 15),
              onMapCreated: (controller) => _mapController = controller,
              polylines: _historyPoints.isNotEmpty ? {Polyline(polylineId: const PolylineId("path"), points: _historyPoints, color: AppColors.luxGold, width: 4)} : {},
              markers: {Marker(markerId: const MarkerId("live"), position: livePos, icon: BitmapDescriptor.defaultMarkerWithHue(isOnline ? 120 : 0))},
            ),

            // LUXURY STATUS PILL
            Positioned(
              top: 20, left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.luxDarkGreen.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isOnline ? Colors.greenAccent : Colors.redAccent)),
                    const SizedBox(width: 12),
                    Text(isOnline ? "ENCRYPTED SIGNAL: LIVE" : "SIGNAL LOST: LAST KNOWN", 
                      style: const TextStyle(color: AppColors.luxGold, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            // DATE PICKER
            Positioned(
              top: 80, right: 20,
              child: GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.luxAccentGreen, shape: BoxShape.circle, border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.5))),
                  child: const Icon(Icons.history_toggle_off, color: AppColors.luxGold, size: 22),
                ),
              ),
            ),

            // NAVIGATION BUTTON (GOLD GRADIENT)
            Positioned(
              bottom: 30, left: 25, right: 25,
              child: GestureDetector(
                onTap: () => _openGoogleMaps(livePos.latitude, livePos.longitude),
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: AppColors.luxGoldGradient,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 10)],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_outlined, color: AppColors.luxDarkGreen),
                        SizedBox(width: 12),
                        Text("INITIATE NAVIGATION", style: TextStyle(color: AppColors.luxDarkGreen, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 13)),
                      ],
                    ),
                  ),
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
// 2. CONTACTS TAB (LUXURY REDESIGN)
// ===================================================
class _ContactsTab extends StatelessWidget {
  final String employeeId;
  const _ContactsTab({Key? key, required this.employeeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('user').doc(employeeId).collection('synced_contacts').orderBy('displayName').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final String name = data['displayName'] ?? 'Unknown';
            final List phones = data['phones'] ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: AppColors.luxAccentGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.luxGold.withValues(alpha: 0.1),
                  child: Text(name.isNotEmpty ? name[0] : "?", style: const TextStyle(color: AppColors.luxGold, fontWeight: FontWeight.bold)),
                ),
                title: Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                subtitle: phones.isNotEmpty ? Text(phones.first.toString(), style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.6), fontSize: 12)) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.phone_outlined, color: AppColors.luxGold, size: 20),
                  onPressed: () => phones.isNotEmpty ? launchUrl(Uri.parse("tel:${phones.first}")) : null,
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
// 3. IMAGES TAB (LUXURY REDESIGN)
// ===================================================
class _ImagesTab extends StatelessWidget {
  final String employeeId;
  const _ImagesTab({Key? key, required this.employeeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('uploads')
          .where('uid', isEqualTo: employeeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: Text("NO VISUAL LOGS FOUND", 
              style: TextStyle(color: AppColors.luxGold, fontSize: 10, letterSpacing: 2)),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, 
            crossAxisSpacing: 12, 
            mainAxisSpacing: 12,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var doc = docs[index];
            var data = doc.data() as Map<String, dynamic>;
            String imageUrl = data['url'] ?? '';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageViewer(
                      imageUrl: imageUrl,
                      heroTag: doc.id, // Unique tag for animation
                    ),
                  ),
                );
              },
              child: Hero(
                tag: doc.id,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.3)),
                    image: DecorationImage(
                      image: NetworkImage(imageUrl), 
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const FullScreenImageViewer({
    Key? key,
    required this.imageUrl,
    required this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for focus
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppColors.luxGold,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            panEnabled: true, // Set to false to prevent panning
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4.0, // Maximum zoom level
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));
              },
            ),
          ),
        ),
      ),
    );
  }
}