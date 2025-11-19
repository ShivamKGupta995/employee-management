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
  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  // Database Reference
  final CollectionReference announcementsRef = 
      FirebaseFirestore.instance.collection('announcements');

  String _selectedCategory = 'General';
  final List<String> _categories = ['General', 'Urgent', 'Holiday', 'Policy'];
  
  bool _isLoading = false;

  // 1. Send Notification
  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and message')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await announcementsRef.add({
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'category': _selectedCategory,
        'timestamp': FieldValue.serverTimestamp(),
        'senderId': FirebaseAuth.instance.currentUser?.uid ?? 'Admin',
      });

      _titleController.clear();
      _messageController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Announcement Broadcasted!')),
        );
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Delete Notification
  Future<void> _deleteNotification(String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Notice?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if (confirm) {
      await announcementsRef.doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notice Deleted")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ==================================
        // 1. COMPOSE SECTION
        // ==================================
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("📢 Compose Announcement", 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 15),
              
              // ============ FIX START ============
              Row(
                children: [
                  // Title Input (Given equal space)
                  Expanded(
                    flex: 1, 
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Dropdown (Given equal space + Fixed Overflow)
                  Expanded(
                    flex: 1, 
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      isExpanded: true, // ✅ FIXED: Prevents overflow
                      decoration: const InputDecoration(
                        labelText: "Type",
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(
                        value: c, 
                        child: Text(
                          c, 
                          overflow: TextOverflow.ellipsis, // ✅ FIXED: Truncates long text
                        ),
                      )).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                    ),
                  ),
                ],
              ),
              // ============ FIX END ============

              const SizedBox(height: 10),
              
              // Message Box
              TextField(
                controller: _messageController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Message Details",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              
              // Send Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendNotification,
                  icon: _isLoading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.send),
                  label: const Text("POST TO DASHBOARD"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ==================================
        // 2. HISTORY LIST SECTION
        // ==================================
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: announcementsRef.orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Error loading notices"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final notifications = snapshot.data!.docs;

              if (notifications.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 50, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("No active announcements"),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final data = notifications[index].data() as Map<String, dynamic>;
                  final String docId = notifications[index].id;

                  // Formatting logic
                  Timestamp? ts = data['timestamp'];
                  String time = ts != null 
                    ? DateFormat('MMM d, h:mm a').format(ts.toDate()) 
                    : 'Posting...';

                  Color badgeColor = Colors.blue;
                  if(data['category'] == 'Urgent') badgeColor = Colors.red;
                  if(data['category'] == 'Holiday') badgeColor = Colors.green;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Icon
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.campaign, color: badgeColor),
                          ),
                          const SizedBox(width: 12),
                          
                          // Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      data['title'] ?? "No Title",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(time, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(data['message'] ?? ""),
                              ],
                            ),
                          ),

                          // Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _deleteNotification(docId),
                          ),
                        ],
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