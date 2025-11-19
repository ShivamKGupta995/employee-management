Here is the complete documentation for the **Background Location System**.

This feature allows the Admin to track where employees are in real-time, even if the employee closes the app. It uses a **Foreground Service** (a persistent notification) to keep the app alive in the background.

Save this file as **`Background_Location_System.md`**.

***

# Background Location System Documentation

**Overview:**
1.  **Employee App:** Runs a background service that silently uploads GPS coordinates to Firebase every 15 minutes (or continuous).
2.  **Admin App:** Displays these coordinates on a Google Map with a "Navigate" button.
3.  **Firebase:** Stores the history of locations in the `locations` collection.

---

## 1. Configuration (AndroidManifest.xml)

**Crucial:** Android 10+ requires strict permissions. Ensure these are in `android/app/src/main/AndroidManifest.xml`.

```xml
<manifest ...>
    <!-- PERMISSIONS -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <!-- Required for Android 14+ -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/> 
    <uses-permission android:name="android.permission.WAKE_LOCK"/>

    <application ...>
        <!-- SERVICE REGISTRATION -->
        <service
            android:name="id.flutter.flutter_background_service.BackgroundService"
            android:foregroundServiceType="location"
            android:permission="android.permission.BIND_JOB_SERVICE"
            android:exported="true" />
    </application>
</manifest>
```

---

## 2. Database Structure (Firestore)

**Collection Name:** `locations`

| Field | Type | Description |
| :--- | :--- | :--- |
| `empId` | String | UID of the Employee |
| `lat` | Number | Latitude |
| `lng` | Number | Longitude |
| `timestamp` | Timestamp | Server time (used to show latest) |

---

## 3. Employee Side (The Tracker)

**File:** `lib/services/background_location_service.dart`

This service runs separately from the main UI. It starts when the employee logs in.

```dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // 1. Create Notification Channel (Required for Background Service)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'my_foreground', 
      'Location Tracking',
      description: 'Tracking active for safety',
      importance: Importance.low, 
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 2. Configure Service
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // We start it manually after login
        isForegroundMode: true,
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'Employee App',
        initialNotificationContent: 'Tracking Location...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location], // Android 14 fix
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  // 3. The Background Logic (Runs even if app is closed)
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    await Firebase.initializeApp();
    
    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) => service.setAsForegroundService());
      service.on('setAsBackground').listen((event) => service.setAsBackgroundService());
    }

    service.on('stopService').listen((event) => service.stopSelf());

    // Get Employee ID from Storage
    final prefs = await SharedPreferences.getInstance();
    final String? empId = prefs.getString('uid'); 

    // 4. Start Tracking Loop (Every 15 seconds)
    Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          try {
            Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
            
            // Upload to Firestore
            if (empId != null) {
              await FirebaseFirestore.instance.collection('locations').add({
                'empId': empId,
                'lat': position.latitude,
                'lng': position.longitude,
                'timestamp': FieldValue.serverTimestamp(),
              });
              print("📍 Location Updated: ${position.latitude}, ${position.longitude}");
              
              // Update Notification Text
              service.setForegroundNotificationInfo(
                title: "Work Tracking Active",
                content: "Last Update: ${DateTime.now().hour}:${DateTime.now().minute}",
              );
            }
          } catch (e) {
            print("Location Error: $e");
          }
        }
      }
    });
  }
}
```

### **Activation (Where to start it?)**
Call this in `lib/screens/login_screen.dart` immediately after a successful login.

```dart
// Inside _login() method, after success:
await LocationService.initialize(); // Configure it
final service = FlutterBackgroundService();
await service.startService(); // Start it
```

---

## 4. Admin Side (The Viewer)

**File:** `lib/screens/admin/employee_monitor_dashboard.dart`

This screen shows the map. Note: You must enable **Maps SDK for Android** in Google Cloud Console and add the API Key to `AndroidManifest.xml`.

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveMapTab extends StatelessWidget {
  final String employeeId;
  const LiveMapTab({Key? key, required this.employeeId}) : super(key: key);

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final uri = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // Get the LATEST location doc
      stream: FirebaseFirestore.instance
          .collection('locations')
          .where('empId', isEqualTo: employeeId)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_off, size: 50, color: Colors.grey),
                Text("No location data found"),
              ],
            ),
          );
        }

        var data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        double lat = data['lat'];
        double lng = data['lng'];
        LatLng pos = LatLng(lat, lng);

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: pos, zoom: 15),
              markers: {
                Marker(
                  markerId: const MarkerId('emp'),
                  position: pos,
                  infoWindow: const InfoWindow(title: "Employee is here"),
                )
              },
            ),
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: () => _openGoogleMaps(lat, lng),
                icon: const Icon(Icons.directions),
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
```

---

## 5. Deployment Notes

1.  **Google Play Store Policy:**
    *   If you publish this to the Play Store, you must fill out the "Location Permissions" declaration.
    *   You must state that the app monitors employees for safety/work tracking.
    *   If this is an internal app (distributed via APK), you don't need to worry about this.

2.  **Battery Usage:**
    *   This service runs every 15 seconds. This consumes battery.
    *   To save battery, you can increase the `Timer.periodic` duration to `Duration(minutes: 5)`.

3.  **Firestore Costs:**
    *   1 update every 15 seconds = 4 writes/minute = 240 writes/hour.
    *   For 10 employees working 8 hours = ~19,000 writes/day.
    *   This is well within Firebase's limits, but be aware of it if you have 100+ employees.