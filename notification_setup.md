Here is the complete documentation for the **Notification System**.

Since you cannot deploy the **Cloud Function** (JS Code) without the **Blaze (Paid) Plan**, I have structured this so:
1.  **The In-App Notice Board works FREE immediately.** (Employees see updates instantly when they open the app).
2.  **The Push Notification (Pop-up)** section is marked as "Future Implementation" so you can add it when you upgrade your plan.

Save this file as **`Notification_System.md`**.

***

# Notification System Documentation

**Overview:**
The notification system allows Admins to broadcast messages to all employees.
1.  **In-App Feed (Works Now - Free):** Using Firestore Streams, employees see new messages instantly inside the app.
2.  **Push Notifications (Future - Paid Plan):** Uses Cloud Functions to wake up the phone with a beep/alert even if the app is closed.

---

## 1. Database Structure (Firestore)

**Collection Name:** `announcements`

| Field | Type | Description |
| :--- | :--- | :--- |
| `title` | String | Headline of the notice |
| `message` | String | Detailed content |
| `category` | String | 'Urgent', 'Holiday', 'Policy', 'General' |
| `timestamp` | Timestamp | Server time (used for sorting) |
| `senderId` | String | UID of the Admin |

---

## 2. Admin Side (Send Notifications)
**File:** `lib/screens/admin/notifications_screen.dart`

This screen allows the Admin to write and save notices to the database.

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final CollectionReference announcementsRef = FirebaseFirestore.instance.collection('announcements');

  String _selectedCategory = 'General';
  final List<String> _categories = ['General', 'Urgent', 'Holiday', 'Policy'];
  bool _isLoading = false;

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Save to Firestore - This updates Employee Apps instantly
      await announcementsRef.add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'category': _selectedCategory,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': FirebaseAuth.instance.currentUser?.uid ?? 'Admin',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Announcement Posted!')));
        _titleController.clear();
        _messageController.clear();
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNotification(String docId) async {
    await announcementsRef.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // COMPOSE SECTION
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("📢 Compose", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder(), isDense: true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(controller: _messageController, maxLines: 2, decoration: const InputDecoration(labelText: "Message", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendNotification,
                  icon: const Icon(Icons.send),
                  label: const Text("POST NOTICE"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[900], foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
        // HISTORY LIST
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: announcementsRef.orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              
              if (docs.isEmpty) return const Center(child: Text("No Announcements"));

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  Color color = data['category'] == 'Urgent' ? Colors.red : Colors.blue;
                  
                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.campaign, color: color),
                      title: Text(data['title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['message'] ?? ""),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteNotification(docs[index].id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
```

---

## 3. Employee Side (Read-Only Feed)
**File:** `lib/screens/employee/employee_notifications_screen.dart`

This screen displays the notices in a clean feed with filters.

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmployeeNotificationScreen extends StatefulWidget {
  const EmployeeNotificationScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeNotificationScreen> createState() => _EmployeeNotificationScreenState();
}

class _EmployeeNotificationScreenState extends State<EmployeeNotificationScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Urgent', 'Holiday', 'Policy', 'General'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Notices"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: Column(
        children: [
          // FILTERS
          Container(
            height: 50,
            padding: const EdgeInsets.only(left: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (bool selected) => setState(() => _selectedFilter = filter),
                  ),
                );
              },
            ),
          ),
          // LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("No Notices"));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    Timestamp? ts = data['timestamp'];
                    String time = ts != null ? DateFormat('MMM d, h:mm a').format(ts.toDate()) : 'Just now';
                    Color color = data['category'] == 'Urgent' ? Colors.red : Colors.blue;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ExpansionTile(
                        leading: Icon(Icons.notifications, color: color),
                        title: Text(data['title'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(data['message'] ?? "", style: const TextStyle(fontSize: 15)),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getStream() {
    Query query = FirebaseFirestore.instance.collection('announcements');
    if (_selectedFilter != 'All') {
      query = query.where('category', isEqualTo: _selectedFilter);
    }
    return query.orderBy('timestamp', descending: true).snapshots();
  }
}
```

---

## 4. FUTURE IMPLEMENTATION (Requires Payment)
**Do this step ONLY when you upgrade to the Firebase Blaze Plan.**

### A. Backend (Cloud Function)
This "Robot" watches the database and sends the beep to phones.

**Path:** `functions/index.js`
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
*Deploy command: `firebase deploy --only functions`*

### B. Frontend (Flutter Setup)
Add this to `lib/main.dart` or your Dashboard `initState` to make the phone listen.

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

void setupNotifications() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  
  // 1. Request Permission
  await messaging.requestPermission(alert: true, sound: true);
  
  // 2. Subscribe to Topic
  await messaging.subscribeToTopic('all_employees');
  print("Subscribed to Notifications");
}
```