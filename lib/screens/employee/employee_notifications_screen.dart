import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:employee_system/config/constants/app_colors.dart'; // Ensure path is correct

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
      backgroundColor: AppColors.luxDarkGreen,
      appBar: AppBar(
        title: const Text("NOTICES & UPDATES", 
          style: TextStyle(letterSpacing: 3, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.luxGold,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF1D322C), AppColors.luxDarkGreen],
          ),
        ),
        child: Column(
          children: [
            // ===========================
            // 1. LUXURY FILTER CHIPS
            // ===========================
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (c, i) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.luxGold : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.luxGold, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        filter.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: isSelected ? AppColors.luxDarkGreen : AppColors.luxGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                  if (snapshot.hasError) return const Center(child: Text("Connection Error", style: TextStyle(color: Colors.redAccent)));
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 60, color: AppColors.luxGold.withValues(alpha: 0.2)),
                          const SizedBox(height: 15),
                          Text("NO RECENT NOTICES", 
                            style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.5), letterSpacing: 2, fontFamily: 'serif')),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      
                      Timestamp? ts = data['timestamp'];
                      String timeStr = ts != null ? _formatTimestamp(ts.toDate()) : 'Just now';

                      // Theming Icons
                      IconData icon = Icons.article_outlined;
                      if (data['category'] == 'Urgent') icon = Icons.priority_high_rounded;
                      if (data['category'] == 'Holiday') icon = Icons.beach_access_outlined;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.luxAccentGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.2)),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                            unselectedWidgetColor: AppColors.luxGold, // Color for the dropdown arrow
                            colorScheme: const ColorScheme.dark(primary: AppColors.luxGold),
                          ),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.luxGold.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: AppColors.luxGold, size: 22),
                            ),
                            title: Text(
                              data['title'] ?? "Notice",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'serif',
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  // Luxury Category Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      (data['category'] ?? 'General').toUpperCase(),
                                      style: const TextStyle(fontSize: 8, color: AppColors.luxGold, fontWeight: FontWeight.bold, letterSpacing: 1),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(timeStr.toUpperCase(), 
                                    style: TextStyle(fontSize: 10, color: AppColors.luxGold.withValues(alpha: 0.4), letterSpacing: 1)),
                                ],
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Divider(color: AppColors.luxGold.withValues(alpha: 0.1)),
                                    const SizedBox(height: 10),
                                    Text(
                                      data['message'] ?? "",
                                      style: TextStyle(
                                        fontSize: 14, 
                                        height: 1.6, 
                                        color: Colors.white.withValues(alpha: 0.8)
                                      ),
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