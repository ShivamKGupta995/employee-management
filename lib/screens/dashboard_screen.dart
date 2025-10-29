import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
       body: StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('notifications')
      .orderBy('timestamp', descending: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(child: Text('No notifications yet.'));
    }

    final notifications = snapshot.data!.docs;

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index].data() as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(notification['title'] ?? 'No Title',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(notification['message'] ?? ''),
            trailing: Text(
              notification['timestamp'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                          notification['timestamp'].millisecondsSinceEpoch)
                      .toLocal()
                      .toString()
                      .split('.')[0]
                  : '',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      },
    );
  },
),

    );
  }
}
