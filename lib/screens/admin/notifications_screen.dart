import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:employee_system/config/constants/app_colors.dart'; // Adjust path

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Logic Variables (Original)
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final CollectionReference announcementsRef = FirebaseFirestore.instance.collection('announcements');
  String _selectedCategory = 'General';
  final List<String> _categories = ['General', 'Urgent', 'Holiday', 'Policy'];
  bool _isLoading = false;

  // ==========================================
  // LUXURY UI HELPERS
  // ==========================================
  
  InputDecoration _luxInput(String label) => InputDecoration(
    labelText: label.toUpperCase(),
    labelStyle: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.6), letterSpacing: 1.5, fontSize: 11),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.luxGold.withValues(alpha: 0.2), width: 1),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.luxGold, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
    fillColor: AppColors.luxAccentGreen.withValues(alpha: 0.2),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  );

  // ==========================================
  // LOGIC METHODS (ORIGINAL PRESERVED)
  // ==========================================

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      _showSnackBar('Please enter all details');
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
        _showSnackBar('✅ Broadcast Successful');
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNotification(String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.luxDarkGreen,
        shape: RoundedRectangleBorder(side: const BorderSide(color: AppColors.luxGold), borderRadius: BorderRadius.circular(15)),
        title: const Text("DELETE NOTICE?", style: TextStyle(color: AppColors.luxGold, fontFamily: 'serif', letterSpacing: 2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: AppColors.luxGold))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("DELETE", style: TextStyle(color: Colors.redAccent))),
        ],
      )
    ) ?? false;
    if (confirm) await announcementsRef.doc(docId).delete();
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.luxAccentGreen));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.luxBgGradient,
      ),
      child: Column(
        children: [
          // 1. COMPOSE SECTION (Luxury Inset Box)
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.luxAccentGreen.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("BROADCAST COMMAND", 
                  style: TextStyle(color: AppColors.luxGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 3, fontFamily: 'serif')),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _titleController, style: const TextStyle(color: Colors.white), decoration: _luxInput("Notice Title"))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: AppColors.luxAccentGreen,
                        style: const TextStyle(color: Colors.white),
                        decoration: _luxInput("Category"),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(controller: _messageController, maxLines: 2, style: const TextStyle(color: Colors.white), decoration: _luxInput("Detailed Message")),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _isLoading ? null : _sendNotification,
                  child: Container(
                    width: double.infinity, height: 50,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.luxGoldGradient),
                    child: Center(
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.luxDarkGreen, strokeWidth: 2))
                        : const Text("POST TO DASHBOARD", style: TextStyle(color: AppColors.luxDarkGreen, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. HISTORY LIST (Luxury List Items)
          // ==================================
// 2. HISTORY LIST (Fixed for Long Text)
// ==================================
Expanded(
  child: StreamBuilder<QuerySnapshot>(
    stream: announcementsRef.orderBy('timestamp', descending: true).snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));
      final notifications = snapshot.data!.docs;

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final data = notifications[index].data() as Map<String, dynamic>;
          final String docId = notifications[index].id;
          
          Timestamp? ts = data['timestamp'];
          String time = ts != null ? DateFormat('MMM d, h:mm a').format(ts.toDate()) : '...';

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.luxAccentGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, // ✅ Keeps icon at the top
              children: [
                // 1. Icon Badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.luxGold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign_outlined, color: AppColors.luxGold, size: 20),
                ),
                const SizedBox(width: 15),

                // 2. Content Area (Wrapped in Expanded to prevent overflow)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Time Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              data['title']?.toString().toUpperCase() ?? "NOTICE",
                              maxLines: 1, // ✅ Prevents title from taking multiple lines
                              overflow: TextOverflow.ellipsis, // ✅ Adds "..." if too long
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'serif',
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            time.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.luxGold.withValues(alpha: 0.5),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Message Text
                      Text(
                        data['message'] ?? "",
                        maxLines: 3, // ✅ Limits preview to 3 lines
                        overflow: TextOverflow.ellipsis, // ✅ Adds "..." if too long
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.4)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          data['category'].toString().toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.luxGold,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Delete Action
                IconButton(
                  icon: Icon(
                    Icons.delete_sweep_outlined,
                    color: Colors.redAccent.withValues(alpha: 0.6),
                    size: 22,
                  ),
                  onPressed: () => _deleteNotification(docId),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(), // ✅ Shrinks button hit area to save space
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
}