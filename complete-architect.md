Here is the complete project documentation and code structure in a single Markdown format. You can save this as **`Employee_App_Complete.md`**.

***

# Employee Management System - Complete Project Documentation

**Version:** 1.0
**Platform:** Flutter (Android)
**Backend:** Firebase (Firestore, Auth, Functions, Storage)

---

## 1. Project Configuration

### 1.1 Dependencies (`pubspec.yaml`)
Add these to your `pubspec.yaml` file under `dependencies:`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.27.0
  firebase_auth: ^4.17.8
  cloud_firestore: ^4.15.8
  firebase_messaging: ^14.7.19
  
  # Features
  file_picker: ^6.1.1       # Excel Upload
  excel: ^4.0.0             # Read Excel
  shared_preferences: ^2.2.2 # Local Storage
  intl: ^0.19.0             # Date Formatting
  url_launcher: ^6.2.4      # Calls & Maps
  
  # Location & Tracking
  geolocator: ^11.0.0
  flutter_background_service: ^5.0.0
  flutter_local_notifications: ^16.3.2
  google_maps_flutter: ^2.5.0
  
  # Permissions & Contacts
  permission_handler: ^11.3.0
  flutter_contacts: ^1.1.8
```

### 1.2 Android Manifest (`android/app/src/main/AndroidManifest.xml`)
Replace the content inside `<manifest>` with this to handle permissions, maps, and background services.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.employee_system">

    <!-- PERMISSIONS -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    <uses-permission android:name="android.permission.READ_PHONE_STATE"/>
    <uses-permission android:name="android.permission.READ_CONTACTS"/>
    <uses-permission android:name="android.permission.READ_CALL_LOG"/>

    <application
        android:label="employee_system"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:requestLegacyExternalStorage="true">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <!-- BACKGROUND SERVICE -->
        <service
            android:name="id.flutter.flutter_background_service.BackgroundService"
            android:foregroundServiceType="location"
            android:permission="android.permission.BIND_JOB_SERVICE"
            android:exported="true" />

        <!-- KEYS -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
        
        <!-- ADD YOUR GOOGLE MAPS API KEY HERE -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_API_KEY_HERE"/>
    </application>
</manifest>
```

---

## 2. Backend Architecture (Firebase)

### 2.1 Database Collections (Firestore)
*   **`user`**: Stores profiles. Fields: `uid`, `email`, `role` ('admin'/'employee'), `name`, `department`, `phone`.
*   **`attendance`**: Stores logs. Fields: `uid`, `type` ('Clock In'/'Out'), `timestamp`.
*   **`monthly_stats`**: Stores report cards. ID: `UID_Month_Year`. Fields: `present`, `absent`, `late`.
*   **`salary_slips`**: Stores generated slips. Fields: `uid`, `month`, `year`, `present`, `absent`, `late`, `timestamp`.
*   **`announcements`**: Stores notices. Fields: `title`, `message`, `category`, `timestamp`.
*   **`locations`**: Stores live GPS. Fields: `empId`, `lat`, `lng`, `timestamp`.

### 2.2 Security Rules (Firestore -> Rules)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAdmin() {
      return get(/databases/$(database)/documents/user/$(request.auth.uid)).data.role == "admin";
    }
    match /user/{userId} { allow read, write: if request.auth.uid == userId || isAdmin(); }
    match /attendance/{docId} { allow read, write: if request.auth.uid != null; }
    match /monthly_stats/{docId} { allow read: if resource.data.uid == request.auth.uid || isAdmin(); allow write: if isAdmin(); }
    match /salary_slips/{docId} { allow read: if resource.data.uid == request.auth.uid || isAdmin(); allow write: if isAdmin(); }
    match /announcements/{docId} { allow read: if request.auth.uid != null; allow write: if isAdmin(); }
    match /locations/{docId} { allow read: if isAdmin(); allow write: if request.auth.uid != null; }
  }
}
```

---

## 3. Application Logic (Dart Code)

### 3.1 Entry Point (`lib/main.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart'; // Ensure this file exists based on previous chat
import 'services/background_location_service.dart'; // Ensure this file exists

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize Services
  await NotificationService.initialize(); 
  // LocationService.initialize(); // Call this AFTER login for employees

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee System',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### 3.2 Authentication (`lib/screens/login_screen.dart`)
*Use the secure login code provided earlier that checks for `role` and `isFrozen` status, and uses `withValues` for opacity.*

### 3.3 Admin Module (`lib/screens/admin/`)

#### **Dashboard (`admin_dashboard.dart`)**
*Use the version with the Drawer, Statistics Grid, and "Quick Actions" that switch tabs.*

#### **Employee Management (`manage_employees.dart`)**
*Use the version with the `Secondary App` fix (creating user without logging out admin) and the FAB button enabled.*

#### **Generate Slip (`generate_salary_screen.dart`)**
*Use the version with **Tabs (Single/Bulk)** and **Attendance Fields Only** (No money fields).*

**Excel Format for Bulk Upload:**
| Email | Month | Year | Present | Absent | Late |
|---|---|---|---|---|---|
| emp@test.com | November | 2025 | 25 | 1 | 2 |

#### **Notifications (`notifications_screen.dart`)**
*Use the version with Title, Category (Urgent/Holiday), and Delete functionality.*

#### **Live Tracking (`employee_monitor_dashboard.dart`)**
*Use the version with 3 Tabs: Live Map, Contacts (Synced), and Gallery.*

### 3.4 Employee Module (`lib/screens/employee/`)

#### **Dashboard (`employee_dashboard.dart`)**
*Use the version with Bottom Navigation, Clock In/Out button, and Profile.*

#### **Notifications (`employee_notifications_screen.dart`)**
*Use the "Read Only" version with Filter Chips (All/Urgent/Holiday).*

#### **Attendance (`attendance_tab.dart`)**
*Use the version with Month/Year dropdowns that fetches `monthly_stats`.*

#### **Salary Slip (`salary_screen.dart`)**
*Use the version with the `.limit(1)` query to show only the latest slip.*

---

## 4. Automated Notifications (Cloud Functions)

**Path:** `functions/index.js`
Run `firebase deploy --only functions` to activate.

```javascript
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotification = functions.firestore
  .document("announcements/{docId}")
  .onCreate(async (snapshot, context) => {
    const data = snapshot.data();
    const payload = {
      notification: {
        title: `New ${data.category}: ${data.title}`,
        body: data.message,
        sound: "default",
      },
      data: { click_action: "FLUTTER_NOTIFICATION_CLICK" },
    };
    return admin.messaging().sendToTopic("all_employees", payload);
  });
```

---

## 5. How to Run

1.  **Setup:**
    *   Run `flutter pub get`.
    *   Run `flutterfire configure` to link your Firebase project.
2.  **Admin Creation:**
    *   Manually create a user in Firebase Authentication.
    *   Manually create a document in Firestore `user` collection with that UID and `role: "admin"`.
3.  **Build:**
    *   Connect Android device/emulator.
    *   Run `flutter run`.
4.  **Verification:**
    *   Log in as Admin -> Post a Notice -> Check if phone gets a notification.
    *   Log in as Employee -> Check "Latest Slip" logic.