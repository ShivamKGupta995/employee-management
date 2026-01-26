import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:employee_system/config/constants/app_colors.dart';

// ... imports remain the same

class BirthdayMonthScreen extends StatelessWidget {
  const BirthdayMonthScreen({super.key});

  // HELPER FUNCTION: Safely convert dob (String or Timestamp) to DateTime
  DateTime? _parseDate(dynamic input) {
    if (input == null) return null;
    if (input is Timestamp) return input.toDate();
    if (input is String) return DateTime.tryParse(input);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final int currentMonth = DateTime.now().month;
    final String monthName = DateFormat('MMMM').format(DateTime.now());

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.luxBgGradient),
      child: Column(
        children: [
          // Header Section (Same as before)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                const Icon(Icons.cake_outlined, color: AppColors.luxGold, size: 30),
                const SizedBox(height: 10),
                Text("CELEBRATIONS: $monthName", 
                  style: const TextStyle(color: AppColors.luxGold, letterSpacing: 4, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'serif')),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('user').where('role', isEqualTo: 'employee').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));

                // SAFE FILTERING
                final birthdayList = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final DateTime? dob = _parseDate(data['dob']); // Use helper
                  return dob != null && dob.month == currentMonth;
                }).toList();

                if (birthdayList.isEmpty) {
                  return Center(child: Text("NO BIRTHDAYS IN $monthName", style: TextStyle(color: AppColors.withValues(AppColors.luxGold, 0.3), letterSpacing: 2)));
                }

                // SAFE SORTING
                birthdayList.sort((a, b) {
                  final DateTime dobA = _parseDate(a['dob']) ?? DateTime.now();
                  final DateTime dobB = _parseDate(b['dob']) ?? DateTime.now();
                  return dobA.day.compareTo(dobB.day);
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: birthdayList.length,
                  itemBuilder: (context, index) {
                    final data = birthdayList[index].data() as Map<String, dynamic>;
                    final DateTime dob = _parseDate(data['dob'])!; // Safe because of filter above
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.withValues(AppColors.luxAccentGreen, 0.3),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: AppColors.withValues(AppColors.luxGold, 0.1)),
                      ),
                      child: Row(
                        children: [
                          _buildDateBadge(dob),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name']?.toString().toUpperCase() ?? "N/A", 
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13)),
                                Text("Executive Team Member", 
                                  style: TextStyle(color: AppColors.withValues(AppColors.luxGold, 0.5), fontSize: 9, letterSpacing: 1)),
                              ],
                            ),
                          ),
                          Icon(Icons.auto_awesome, color: AppColors.withValues(AppColors.luxGold, 0.3), size: 16),
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

  // Date Badge (Same as before)
  Widget _buildDateBadge(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppColors.luxGoldGradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(DateFormat('dd').format(date), 
            style: const TextStyle(color: AppColors.luxDarkGreen, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'serif')),
          Text(DateFormat('MMM').format(date).toUpperCase(), 
            style: const TextStyle(color: AppColors.luxDarkGreen, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }
}