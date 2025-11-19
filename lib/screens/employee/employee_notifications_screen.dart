import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmployeeNotificationScreen extends StatefulWidget {
  const EmployeeNotificationScreen({Key? key}) : super(key: key);

  @override
  State<EmployeeNotificationScreen> createState() => _EmployeeNotificationScreenState();
}

class _EmployeeNotificationScreenState extends State<EmployeeNotificationScreen> {
  // Filter state
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Urgent', 'Holiday', 'Policy', 'General'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Notices & Updates"),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // ===========================
          // 1. FILTER CHIPS (Top Bar)
          // ===========================
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  selectedColor: Colors.blue.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue.shade900 : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                );
              },
            ),
          ),

          // ===========================
          // 2. NOTIFICATION LIST
          // ===========================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("All caught up!", style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    
                    // Format Time
                    Timestamp? ts = data['timestamp'];
                    String timeStr = ts != null 
                        ? _formatTimestamp(ts.toDate()) 
                        : 'Just now';

                    // Styling based on Category
                    Color accentColor = Colors.blue;
                    IconData icon = Icons.article;

                    if (data['category'] == 'Urgent') {
                      accentColor = Colors.red;
                      icon = Icons.warning_amber_rounded;
                    } else if (data['category'] == 'Holiday') {
                      accentColor = Colors.green;
                      icon = Icons.beach_access;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          // Leading Icon Box
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: accentColor, size: 24),
                          ),
                          title: Text(
                            data['title'] ?? "Notice",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                // Category Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Text(
                                    (data['category'] ?? 'General').toUpperCase(),
                                    style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Time
                                Text(timeStr, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                              ],
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  const SizedBox(height: 10),
                                  Text(
                                    data['message'] ?? "",
                                    style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                                  ),
                                ],
                              ),
                            )
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
      ),
    );
  }

  // Helper: Apply Filter to Firestore Query
  Stream<QuerySnapshot> _getStream() {
    Query query = FirebaseFirestore.instance.collection('announcements');
    
    // Apply Filter if not 'All'
    if (_selectedFilter != 'All') {
      query = query.where('category', isEqualTo: _selectedFilter);
    }
    
    // Always sort by newest
    return query.orderBy('timestamp', descending: true).snapshots();
  }

  // Helper: Friendly Time Format (e.g., "2 hrs ago")
  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return DateFormat('MMM d').format(date);
    } else if (difference.inHours > 0) {
      return "${difference.inHours}h ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }
}