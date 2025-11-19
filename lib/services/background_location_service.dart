import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  
  // 1. Initialize the Service (Call this from Login Screen or Dashboard)
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Create the Notification Channel (Required for Android Foreground Service)
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
        // This function runs when service starts
        onStart: onStart,

        // Auto start is false so we can control it manually after login
        autoStart: false, 
        isForegroundMode: true,
        
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'Employee App',
        initialNotificationContent: 'Initializing Location Service...',
        foregroundServiceNotificationId: 888,
        
        // CRITICAL for Android 14+
        foregroundServiceTypes: [AndroidForegroundType.location], 
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  // 2. The Background Logic (Runs in a separate thread/isolate)
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // Necessary initialization for background isolates
    DartPluginRegistrant.ensureInitialized();
    
    // Initialize Firebase inside this background thread
    // NOTE: You might need to pass options if you have specific config, 
    // but usually default works if configured via flutterfire CLI.
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

    // Get the Employee ID (We assume it was saved to SharedPreferences during Login)
    final prefs = await SharedPreferences.getInstance();
    final String? empId = prefs.getString('uid'); // Make sure you saved 'uid' in LoginScreen

    print("Background Service Started. Tracking Employee: $empId");

    // 3. Start the Loop (Every 15 Seconds)
    Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          
          try {
            // A. Get Location
            Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high);

            print("📍 Location: ${position.latitude}, ${position.longitude}");

            // B. Upload to Firebase
            if (empId != null) {
              await FirebaseFirestore.instance.collection('locations').add({
                'empId': empId,
                'lat': position.latitude,
                'lng': position.longitude,
                'timestamp': FieldValue.serverTimestamp(),
                'speed': position.speed,
                'isMocked': position.isMocked, // Good for detecting fake GPS
              });

              // C. Update Notification (Visual feedback)
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
  
  // Helper to start service manually
  static Future<void> startTracking() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (!isRunning) {
      service.startService();
    }
  }
  
  // Helper to stop service
  static Future<void> stopTracking() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
  }
}