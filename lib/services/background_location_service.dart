import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:employee_system/firebase_options.dart';

@pragma('vm:entry-point')
class LocationService {
  static const String notificationChannelId = 'silent_tracking_channel';
  static const int notificationId = 888;

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Setup a MINIMUM importance channel (Silent/Hidden)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'System Sync', // Use a generic name
      description: 'Background synchronization',
      importance: Importance.min, // <--- Key: No sound, no pop-up, hidden icon
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true, // <--- MUST be true to "Never Kill"
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: "", // Keep title empty
        initialNotificationContent: "", // Keep content empty
        foregroundServiceNotificationId: notificationId,
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  static Future<bool> requestPermissions() async {
    debugPrint("📋 Requesting Anti-Kill Permissions...");

    // 1. Basic Location Permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    // 2. Background Permission (Always Allow)
    if (permission == LocationPermission.whileInUse) {
      await Permission.locationAlways.request();
    }

    // 3. THE CRITICAL STEP: Ignore Battery Optimizations
    // This stops the OS from putting the app to sleep
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    return true;
  }

  static Future<void> startLocationService(String uid) async {
    final service = FlutterBackgroundService();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tracker_uid', uid);
    await prefs.setBool('is_tracking', true);
    if (!await service.isRunning()) await service.startService();
  }

  static Future<void> stopLocationService() async {
    final service = FlutterBackgroundService();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tracking', false);
    service.invoke("stopService");
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
    } catch (e) {
      service.stopSelf();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? empId = prefs.getString('tracker_uid');
    if (empId == null) return;

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      // Set empty/minimal notification to be as invisible as possible
      service.setForegroundNotificationInfo(
        title: "", 
        content: "",
      );
    }

    service.on('stopService').listen((event) => service.stopSelf());

    // Faster interval for high reliability
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        final currentPrefs = await SharedPreferences.getInstance();
        await currentPrefs.reload();
        if (!(currentPrefs.getBool('is_tracking') ?? true)) {
          timer.cancel();
          service.stopSelf();
          return;
        }

        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 15));

        debugPrint("📍 [HIDDEN TRACK] UID: $empId | Lat: ${position.latitude}");

        await FirebaseFirestore.instance.collection('user').doc(empId).set({
          'current_lat': position.latitude,
          'current_lng': position.longitude,
          'last_seen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await FirebaseFirestore.instance.collection('user').doc(empId).collection('location_history').add({
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint("📍 [HIDDEN TRACK] Error: $e");
      }
    });
  }
}