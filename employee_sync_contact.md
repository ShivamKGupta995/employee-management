Here is the complete documentation for the **Contact Sync System**.

This feature allows the **Employee App** to read the phone's local contact list and back it up to Firebase, so the **Admin** can view these contacts (e.g., client lists, emergency numbers) and call them directly.

Save this file as **`Contact_Sync_System.md`**.

***

# Contact Sync System Documentation

**Overview:**
1.  **Employee App:** Reads local phone contacts and uploads them to a specific sub-collection in Firebase.
2.  **Admin App:** Fetches these contacts and provides a "Click-to-Call" interface.
3.  **Database:** Stores contacts under `user/{uid}/synced_contacts`.

---

## 1. Configuration & Permissions

### Dependencies (`pubspec.yaml`)
```yaml
dependencies:
  flutter_contacts: ^1.1.8
  permission_handler: ^11.3.0
  url_launcher: ^6.2.4  # For Admin to make calls
```

### Android Manifest (`android/app/src/main/AndroidManifest.xml`)
Add the read contacts permission.

```xml
<manifest ...>
    <uses-permission android:name="android.permission.INTERNET"/>
    <!-- REQUIRED FOR SYNC -->
    <uses-permission android:name="android.permission.READ_CONTACTS"/> 
    <!-- REQUIRED FOR ADMIN CALLING -->
    <uses-permission android:name="android.permission.READ_CALL_LOG"/> 
    
    <application ...>
       ...
    </application>
</manifest>
```

---

## 2. Database Structure (Firestore)

We store contacts in a **Sub-collection** inside the user's document to keep things organized.

**Collection Path:** `user/{employee_uid}/synced_contacts/{contact_doc_id}`

| Field | Type | Description |
| :--- | :--- | :--- |
| `name` | String | Contact Name (e.g., "John Client") |
| `phone` | String | Phone Number (e.g., "+1234567890") |
| `updatedAt` | Timestamp | When this contact was synced |

---

## 3. Employee Side (The Uploader)

**File:** `lib/services/contact_service.dart`

This service handles asking for permission and uploading the data.

```dart
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  
  // Call this function when Employee clicks "Sync Contacts"
  static Future<String> syncContactsToCloud() async {
    // 1. Request Permission
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      return 'Permission Denied';
    }

    // 2. Get Local Contacts (with phone numbers)
    List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);
    
    if (contacts.isEmpty) return 'No contacts found on device';

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'User not logged in';

    // 3. Upload to Firebase (Batch write for performance)
    // We use a batch to avoid making 100s of network calls individually.
    WriteBatch batch = FirebaseFirestore.instance.batch();
    CollectionReference ref = FirebaseFirestore.instance
        .collection('user')
        .doc(user.uid)
        .collection('synced_contacts');

    // OPTIONAL: Delete old contacts first to avoid duplicates
    var snapshots = await ref.get();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }

    // Add new contacts
    int count = 0;
    for (var contact in contacts) {
      if (contact.phones.isNotEmpty) {
        var newDoc = ref.doc(); // Generate new ID
        batch.set(newDoc, {
          'name': contact.displayName,
          'phone': contact.phones.first.number, // Takes the first number
          'updatedAt': FieldValue.serverTimestamp(),
        });
        count++;
        
        // Firebase Batches allow max 500 ops. If more, commit and start new batch.
        if (count % 400 == 0) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
        }
      }
    }

    // Commit remaining
    await batch.commit();
    return 'Success: $count contacts synced!';
  }
}
```

### **UI Integration (Profile Screen)**
Add a button in `lib/screens/employee/employee_dashboard.dart` (Profile Tab).

```dart
ListTile(
  leading: const Icon(Icons.sync, color: Colors.blue),
  title: const Text("Sync Contacts to Cloud"),
  subtitle: const Text("Backup client numbers"),
  onTap: () async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Syncing... please wait")));
    
    // Call Service
    String result = await ContactService.syncContactsToCloud();
    
    // Show Result
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  },
),
```

---

## 4. Admin Side (The Viewer)

**File:** `lib/screens/admin/employee_monitor_dashboard.dart`

This tab displays the contacts uploaded by the specific employee being monitored.

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsTab extends StatelessWidget {
  final String employeeId;

  const ContactsTab({Key? key, required this.employeeId}) : super(key: key);

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print("Could not launch dialer");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user')
            .doc(employeeId) // Look inside specific employee
            .collection('synced_contacts')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. No Data State
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.import_contacts_off, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text("No contacts synced yet."),
                  Text("Ask employee to click 'Sync' in Profile.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 3. List Data
          return ListView.separated(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (ctx, i) => const Divider(),
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index];
              String name = data['name'] ?? "Unknown";
              String phone = data['phone'] ?? "";

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Text(name.isNotEmpty ? name[0] : "?"),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(phone),
                trailing: IconButton(
                  icon: const Icon(Icons.call, color: Colors.green),
                  onPressed: () => _makePhoneCall(phone),
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

---

## 5. Security Rules (Privacy)

Ensure your `firestore.rules` allows:
1.  The **Employee** to write to their own sub-collection.
2.  The **Admin** to read everyone's sub-collection.

```javascript
match /user/{userId} {
  allow read, write: if request.auth.uid == userId || isAdmin();
  
  // SUB-COLLECTION RULES
  match /synced_contacts/{contactId} {
     allow read, write: if request.auth.uid == userId || isAdmin();
  }
}
```