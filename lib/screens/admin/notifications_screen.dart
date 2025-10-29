import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final TextEditingController messageController = TextEditingController();
  final CollectionReference notificationsRef =
      FirebaseFirestore.instance.collection('notifications');

  Future<void> _sendNotification() async {
    if (messageController.text.isEmpty) return;
    await notificationsRef.add({
      'message': messageController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });
    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: messageController,
            decoration: InputDecoration(
              labelText: 'Write a notification',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: _sendNotification,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: notificationsRef.orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final notifications = snapshot.data!.docs;
              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final data = notifications[index];
                  return ListTile(
                    title: Text(data['message']),
                    subtitle: Text(
                      data['timestamp'] != null
                          ? data['timestamp'].toDate().toString()
                          : 'Pending...',
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
