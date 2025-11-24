import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// 1. Background Handler (Must be outside any class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background Message: ${message.messageId}");
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // 2. Initialize
  Future<void> initialize() async {
    // A. Request Permission (Required for iOS & Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      // B. Subscribe to a Topic
      // This allows the Admin to send 1 message to "all_employees"
      await _firebaseMessaging.subscribeToTopic('all_employees');
      print('Subscribed to all_employees topic');

      // C. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
          // Note: Foreground notifications usually don't show a banner automatically
          // You can use flutter_local_notifications here to show it manually if you want
        }
      });
    }
    
    // D. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}