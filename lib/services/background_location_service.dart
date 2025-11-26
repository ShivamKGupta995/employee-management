import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:employee_system/firebase_options.dart'; // ADD THIS IMPORT

/// LocationService:
/// This service runs in the background to track an employee's real-time GPS location.
/// It:
/// 1. Initializes a foreground service (required on Android to track in background)
/// 2. Requests location and notification permissions
/// 3. Starts a periodic timer that captures GPS data every 15 seconds
/// 4. Writes location to Firestore (live status + history for breadcrumbs)
/// 5. Updates the foreground notification with current speed and time
/// 6. Automatically stops if GPS fails too many times or tracking is disabled
///
/// NOTE: @pragma('vm:entry-point') tells Dart this method is called from native code
/// (Android/iOS triggers the background service entry point).
@pragma('vm:entry-point')
class LocationService {
  static const String notificationChannelId = 'employee_tracking_channel';
  static const int notificationId = 888;

  // ====================================================
  // 1. INITIAL SETUP - Configure the background service
  // ====================================================
  /// initialize():
  /// Called once at app startup to configure the background service.
  /// Creates a notification channel (Android) and registers the onStart callback.
  /// This prepares everything but does NOT start tracking yet.
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    // Create Android Notification Channel:
    // Android requires notification channels for foreground services.
    // We create a low-importance channel so the notification doesn't interfere.
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      'Employee Tracking Service',
      description: 'Running in background to track location',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation
          <AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Configure the background service:
    // - onStart: The callback function invoked when the service starts
    // - autoStart: Don't auto-start; only start when explicitly told
    // - isForegroundMode: Run as a foreground service (shows persistent notification)
    // - notificationChannelId: Link to the channel we created above
    // - autoStartOnBoot: Restart tracking if phone reboots (set to true for production)
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Location Tracking',
        initialNotificationContent: 'Initializing GPS...',
        foregroundServiceNotificationId: notificationId,
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  // ====================================================
  // 2. PERMISSION HANDLING
  // ====================================================
  /// requestPermissions():
  /// Checks and requests all necessary runtime permissions for background GPS tracking.
  /// Returns true if all permissions are granted, false otherwise.
  ///
  /// Required permissions:
  /// 1. Notification - to show foreground service notification
  /// 2. Location Service - GPS hardware must be enabled
  /// 3. Location (Fine) - permission to access GPS coordinates
  /// 4. Location (Always) - permission to track in background (not just when app is open)
  static Future<bool> requestPermissions() async {
    print("📋 Checking permissions...");

    // A. Notification Permission:
    // Android 13+ requires explicit permission to send notifications.
    // Without this, the foreground service notification won't appear.
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // B. Check GPS Hardware:
    // GPS service must be enabled in device settings.
    // If disabled, prompt user to enable it. Wait 2s then check again.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("❌ GPS is OFF - Opening settings");
      await Geolocator.openLocationSettings();
      await Future.delayed(const Duration(seconds: 2));
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
    }

    // C. Location Permission (Fine/Coarse):
    // Check current state. If denied, request. If denied forever, open app settings.
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("❌ Location permission denied");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("❌ Location permission denied forever");
      await Geolocator.openAppSettings();
      return false;
    }

    // D. Background Location Permission ("Always Allow"):
    // On Android 10+, "While in Use" alone is not enough for background tracking.
    // We must request "Always Allow" (PERMISSION_ACCESS_BACKGROUND_LOCATION).
    // This permission opens app settings if the user denies it.
    if (permission == LocationPermission.whileInUse) {
      print("⚠️ Requesting ALWAYS permission...");
      var backgroundStatus = await Permission.locationAlways.request();

      if (!backgroundStatus.isGranted) {
        print("❌ Background location denied - Opening settings");
        await Geolocator.openAppSettings();
        return false;
      }
    }

    print("✅ All permissions granted!");
    return true;
  }

  // ====================================================
  // 3. START & STOP HELPERS
  // ====================================================
  /// startLocationService(uid):
  /// Starts the background location service for a given user (uid).
  /// The uid is saved to SharedPreferences so the background isolate can access it.
  /// Calls service.startService() to spawn the background task.
  static Future<void> startLocationService(String uid) async {
    final service = FlutterBackgroundService();

    print("🚀 Starting location service for UID: $uid");

    // Save UID and tracking flag:
    // The background isolate runs in a separate process and cannot directly
    // access local variables. SharedPreferences is a bridge that persists data
    // so the background task can read it.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tracker_uid', uid);
    await prefs.setBool('is_tracking', true);

    if (!await service.isRunning()) {
      await service.startService();
      print("✅ Service started");
    } else {
      print("⚠️ Service already running");
    }
  }

  /// stopLocationService():
  /// Stops the background service by setting is_tracking = false.
  /// The background loop checks this flag every iteration and exits if false.
  static Future<void> stopLocationService() async {
    final service = FlutterBackgroundService();
    final prefs = await SharedPreferences.getInstance();
    // Set flag to false; background loop will detect and stop itself
    await prefs.setBool('is_tracking', false);

    service.invoke("stopService");
    print("🛑 Service stopped");
  }

  // ====================================================
  // 4. BACKGROUND WORKER - Main background task
  // ====================================================
  /// onStart(service):
  /// This is the entry point for the background service (runs in a separate isolate).
  /// An isolate is an independent Dart thread with its own memory.
  /// It does NOT share variables with the main UI thread.
  ///
  /// Flow:
  /// 1. Initialize Dart plugins (required in isolate)
  /// 2. Initialize Firebase
  /// 3. Get the employee UID from SharedPreferences
  /// 4. Start a periodic timer to capture GPS every 15 seconds
  /// 5. Write location to Firestore + history
  /// 6. Update foreground notification
  /// 7. Stop if tracking flag is false or GPS fails too many times
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    // CRITICAL: Initialize Dart plugins in this isolate.
    // Without this, packages like firebase_core won't work in the background.
    DartPluginRegistrant.ensureInitialized();

    print("🔧 Background Service: Initializing...");

    // Initialize Firebase in the background isolate.
    // Each isolate (main thread + background service) needs its own Firebase instance.
    // We check if already initialized to avoid duplicate initialization.
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print("✅ Firebase initialized in background");
      } else {
        print("✅ Firebase already initialized");
      }
    } catch (e) {
      print("❌ Firebase initialization error: $e");
      service.stopSelf();
      return;
    }

    // B. Get Employee UID from SharedPreferences.
    // This UID was saved when startLocationService(uid) was called from the UI.
    // It's used to identify which user document to update in Firestore.
    final prefs = await SharedPreferences.getInstance();
    final String? empId = prefs.getString('tracker_uid');

    if (empId == null || empId.isEmpty) {
      print("❌ No UID found - Stopping service");
      service.stopSelf();
      return;
    }

    print("✅ Background Service Started for: $empId");

    // C. Setup Stop Listener.
    // Listen for explicit stop commands from the UI.
    service.on('stopService').listen((event) {
      print("🛑 Stop command received");
      service.stopSelf();
    });

    // D. Promote to Foreground Service (Android only).
    // A foreground service must have a visible notification.
    // This keeps the service from being killed when the app is closed.
    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
    }

    // ====================================================
    // E. LOCATION TRACKING LOOP (The Core)
    // ====================================================
    /// This timer runs every 15 seconds to:
    /// 1. Get current GPS position
    /// 2. Write live location to Firestore user doc (for admin dashboard)
    /// 3. Add breadcrumb to location_history subcollection (for route replay)
    /// 4. Update the foreground notification with current speed
    /// 5. Track failures; stop if too many GPS timeouts or errors
    
    int failureCount = 0;
    const int maxFailures = 10;

    // Wait a bit before first GPS attempt to ensure all is initialized
    await Future.delayed(const Duration(seconds: 2));

    // Start a timer that fires every 60 seconds.
    int takeLocationAfterEmployee = 60; // seconds
    Timer.periodic(Duration(seconds: takeLocationAfterEmployee), (timer) async {
      try {
        print("📍 Attempting to get location...");

        // Check if still tracking.
        // The UI may have called stopLocationService() which sets is_tracking = false.
        // We reload SharedPreferences to pick up the latest value.
        final currentPrefs = await SharedPreferences.getInstance();
        await currentPrefs.reload(); // Get fresh values from disk
        bool isTracking = currentPrefs.getBool('is_tracking') ?? true;

        if (!isTracking) {
          print("🛑 Tracking disabled - Stopping timer");
          timer.cancel();
          service.stopSelf();
          return;
        }

        // Get current GPS position with timeout.
        // Timeout is important: if GPS takes too long, we move on and retry later.
        // This prevents the background service from freezing if GPS is weak.
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).timeout(
          const Duration(seconds: 30), // Max wait: 30 seconds for a GPS fix
          onTimeout: () {
            throw TimeoutException("GPS signal timeout");
          },
        );

        print("✅ Location acquired: ${position.latitude}, ${position.longitude}");

        // Reset failure counter on success (so we don't stop the service)
        failureCount = 0;

        // UPDATE FIRESTORE: Live Location (User Document)
        // This is what the admin dashboard reads to show real-time employee location.
        // We merge (not overwrite) so other fields like 'name', 'email' are preserved.
        print("🔥 Writing to Firestore: user/$empId");
        
        // Write current position + metadata to the user doc.
        // SetOptions(merge: true) means: update only these fields, don't delete others.
        await FirebaseFirestore.instance.collection('user').doc(empId).set({
          'current_lat': position.latitude,
          'current_lng': position.longitude,
          'last_seen': FieldValue.serverTimestamp(), // Server timestamp (coordinated)
          'speed': position.speed, // Speed in m/s
          'heading': position.heading, // Direction in degrees (0-360)
          'accuracy': position.accuracy, // Accuracy radius in meters
          'is_mocked': position.isMocked, // Flag if location is spoofed
          'updated_at': DateTime.now().toIso8601String(), // Local time for debugging
        }, SetOptions(merge: true));

        print("✅ Firestore user document updated");

        // ADD TO LOCATION HISTORY (Breadcrumb Trail)
        // We keep a subcollection of all location points over time.
        // Admin can play back the route the employee took today.
        // This is stored separately to keep the user doc lightweight.
        await FirebaseFirestore.instance
            .collection('user')
            .doc(empId)
            .collection('location_history')
            .add({
              'lat': position.latitude,
              'lng': position.longitude,
              'timestamp': FieldValue.serverTimestamp(), // Server time for ordering
              'speed': position.speed,
              'accuracy': position.accuracy,
              // Firestore auto-generates a document ID (timestamp-based)
            });

        print("✅ Location history added");

        // UPDATE FOREGROUND NOTIFICATION
        // Keep the user informed of what the background service is doing.
        // Show current time and speed for visual feedback.
        if (service is AndroidServiceInstance) {
          final now = DateTime.now();
          service.setForegroundNotificationInfo(
            title: "📍 Tracking Active",
            content:
                "Last: ${now.hour}:${now.minute.toString().padLeft(2, '0')} | ${(position.speed * 3.6).toStringAsFixed(1)} km/h",
          );
        }
      } on TimeoutException catch (e) {
        // GPS took too long; increment failure counter.
        // If 10+ consecutive timeouts, we stop the service.
        failureCount++;
        print("⚠️ GPS Timeout ($failureCount/$maxFailures): $e");

        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: "⚠️ Weak GPS Signal",
            content: "Searching... ($failureCount/$maxFailures)",
          );
        }

        if (failureCount >= maxFailures) {
          print("❌ Too many GPS failures - Stopping service");
          timer.cancel();
          service.stopSelf();
        }
      } catch (e, stackTrace) {
        // Any other error (permission denied, Firestore error, etc.)
        failureCount++;
        print("❌ Error in background loop ($failureCount/$maxFailures): $e");
        print("📚 Stack trace: $stackTrace");

        if (service is AndroidServiceInstance) {
          String errorMsg = e.toString();
          if (errorMsg.length > 40) errorMsg = errorMsg.substring(0, 40);
          service.setForegroundNotificationInfo(
            title: "❌ Error",
            content: errorMsg,
          );
        }

        if (failureCount >= maxFailures) {
          print("❌ Too many errors - Stopping service");
          timer.cancel();
          service.stopSelf();
        }
      }
    });
  }
}