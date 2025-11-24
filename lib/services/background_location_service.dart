import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  
  // 1. Initialize the Service
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Create Notification Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'my_foreground', 
      'Location Tracking',
      description: 'Tracking active for employee safety',
      importance: Importance.low, 
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, 
        isForegroundMode: true,
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'Employee App',
        initialNotificationContent: 'Initializing Location Service...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location], 
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  // 2. The Background Logic
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    
    // Initialize Firebase
    await Firebase.initializeApp();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Get the Employee ID
    final prefs = await SharedPreferences.getInstance();
    final String? empId = prefs.getString('uid'); 

    print("Background Service Started. Tracking Employee: $empId");

    // 3. Start the Loop (Every 15 Seconds)
    Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          
          try {
            // A. Get Location (UPDATED for Geolocator v10+)
            // We use LocationSettings instead of just desiredAccuracy
            Position position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 10, // Only update if moved 10 meters
              ),
            );

            print("📍 Location: ${position.latitude}, ${position.longitude}");

            // B. Upload to Firebase
            if (empId != null) {
              
              // 1. Update "Current Location" (Overwrites old location for Real-time Map)
              // Using empId as Document ID here makes it easy to find "Where is User X right now?"
              await FirebaseFirestore.instance
                  .collection('user')
                  .doc(empId)
                  .update({
                    'current_lat': position.latitude,
                    'current_lng': position.longitude,
                    'last_seen': FieldValue.serverTimestamp(),
                    'speed': position.speed,
                    'isMocked': position.isMocked,
                  })
                  .catchError((e) {
                    // If document doesn't exist (rare), create it
                     FirebaseFirestore.instance.collection('user').doc(empId).set({
                        'current_lat': position.latitude,
                        'current_lng': position.longitude,
                        'last_seen': FieldValue.serverTimestamp(),
                     }, SetOptions(merge: true));
                  });

              // 2. Save to History (Creates a TRAIL using Auto-ID)
              // This allows you to replay their path later
              await FirebaseFirestore.instance
                  .collection('user')
                  .doc(empId)
                  .collection('location_history') // Sub-collection
                  .add({
                    'lat': position.latitude,
                    'lng': position.longitude,
                    'timestamp': FieldValue.serverTimestamp(),
                    'speed': position.speed,
                  });

              // C. Update Notification
              service.setForegroundNotificationInfo(
                title: "Work Tracking Active",
                content: "Last Update: ${DateTime.now().hour}:${DateTime.now().minute}",
              );
            } else {
              print("Error: User UID not found in SharedPreferences");
            }

          } catch (e) {
            print("Background Location Error: $e");
          }
        }
      }
    });
  }

  // Required for iOS
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }
  
  static Future<void> startTracking() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (!isRunning) {
      service.startService();
    }
  }
  
  static Future<void> stopTracking() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }
}