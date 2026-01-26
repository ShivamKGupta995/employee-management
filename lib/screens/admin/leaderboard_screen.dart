import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:employee_system/config/constants/app_colors.dart';
import 'package:intl/intl.dart';

class PerformanceLeaderboard extends StatefulWidget {
  const PerformanceLeaderboard({super.key});

  @override
  State<PerformanceLeaderboard> createState() => _PerformanceLeaderboardState();
}

class _PerformanceLeaderboardState extends State<PerformanceLeaderboard> {
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;
  
  late String _selectedMonth;
  late String _selectedYear;

  // Generate a dynamic list of years (e.g., from 2023 to next year)
  List<String> _getYearList() {
    int currentYear = DateTime.now().year;
    List<String> years = [];
    for (int i = currentYear - 2; i <= currentYear + 1; i++) {
      years.add(i.toString());
    }
    return years;
  }

  final List<String> _months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateFormat('MMMM').format(DateTime.now());
    _selectedYear = DateTime.now().year.toString();
  }

  // Logic: Parallel Fetch + Weighted Sorting + Tie Breaking
  Future<List<Map<String, dynamic>>> _getOptimizedData(List<QueryDocumentSnapshot> slips) async {
    final userFutures = slips.map((s) => 
      FirebaseFirestore.instance.collection('user').doc(s['uid']).get()
    ).toList();

    final userDocs = await Future.wait(userFutures);
    final Map<String, dynamic> userMap = {};
    for (var doc in userDocs) { if (doc.exists) userMap[doc.id] = doc.data(); }

    List<Map<String, dynamic>> results = [];
    for (var slip in slips) {
      final slipData = slip.data() as Map<String, dynamic>;
      final userData = userMap[slipData['uid']];

      if (userData != null) {
        double p = (slipData['present'] ?? 0).toDouble();
        double a = (slipData['absent'] ?? 0).toDouble();
        double l = (slipData['late'] ?? 0).toDouble();
        double ot = (slipData['ot'] ?? 0).toDouble();
        
        double score = (p * 10.0) + (ot * 5.0) - (a * 20.0) - (l * 5.0);

        results.add({
          ...slipData,
          'name': userData['name'] ?? 'Asset',
          'photoUrl': userData['photoUrl'],
          'totalScore': score,
          'ot': ot,
          'absent': a,
        });
      }
    }

    results.sort((a, b) {
      int cmp = b['totalScore'].compareTo(a['totalScore']);
      if (cmp != 0) return cmp;
      int otCmp = b['ot'].compareTo(a['ot']);
      if (otCmp != 0) return otCmp;
      return a['absent'].compareTo(b['absent']);
    });

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxDarkGreen,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.luxBgGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernHeader(), 
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('salary_slips')
                      .where('month', isEqualTo: _selectedMonth)
                      .where('year', isEqualTo: _selectedYear)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildNoData();

                    return FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getOptimizedData(snapshot.data!.docs),
                      builder: (context, future) {
                        if (!future.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));
                        
                        final allData = future.data!;
                        final top3 = allData.take(3).toList();
                        final others = allData.skip(3).toList();

                        return CustomScrollView(
                          slivers: [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 20, bottom: 40),
                                child: _buildLuxuryPodium(top3),
                              ),
                            ),
                            SliverToBoxAdapter(child: _buildListTitle()),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) => _buildExecutiveRow(others[index], index + 4),
                                  childCount: others.length,
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(child: SizedBox(height: 100)),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.luxGold.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          const Text("EXECUTIVE HALL OF FAME", 
            style: TextStyle(letterSpacing: 4, fontSize: 14, color: AppColors.luxGold, fontWeight: FontWeight.w900, fontFamily: 'serif')),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _luxDrop(_selectedMonth, _months, (v) => setState(() => _selectedMonth = v!))),
              const SizedBox(width: 10),
              // Fixed: Using dynamic Year List
              Expanded(child: _luxDrop(_selectedYear, _getYearList(), (v) => setState(() => _selectedYear = v!))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _luxDrop(String val, List<String> items, Function(String?) onChg) {
    // Safety check: If the current value is not in the list, default to the first item
    // This prevents the "There should be exactly one item with value" crash.
    String dropdownValue = items.contains(val) ? val : items.first;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.luxAccentGreen.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.luxGold.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dropdownValue,
          isExpanded: true,
          dropdownColor: AppColors.luxAccentGreen,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.luxGold, size: 18),
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChg,
        ),
      ),
    );
  }

  // ... [Keep _buildLuxuryPodium, _podiumUnit, _buildExecutiveRow, _buildListTitle, _buildNoData exactly as they were] ...

  Widget _buildLuxuryPodium(List<Map<String, dynamic>> top3) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (top3.length > 1) _podiumUnit(top3[1], "2nd", 110),
        if (top3.isNotEmpty) _podiumUnit(top3[0], "1st", 150, isGold: true),
        if (top3.length > 2) _podiumUnit(top3[2], "3rd", 90),
      ],
    );
  }

  Widget _podiumUnit(Map<String, dynamic> data, String rank, double h, {bool isGold = false}) {
    return Column(
      children: [
        CircleAvatar(
          radius: isGold ? 38 : 30,
          backgroundColor: isGold ? AppColors.luxGold : AppColors.luxGold.withOpacity(0.2),
          child: CircleAvatar(
            radius: isGold ? 35 : 28,
            backgroundImage: data['photoUrl'] != null ? NetworkImage(data['photoUrl']) : null,
          ),
        ),
        const SizedBox(height: 10),
        Text(data['name'].toString().split(" ")[0].toUpperCase(), 
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 5),
        Container(
          width: 85, height: h,
          decoration: BoxDecoration(
            gradient: isGold ? AppColors.luxGoldGradient : null,
            color: isGold ? null : AppColors.luxAccentGreen.withOpacity(0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            border: Border.all(color: AppColors.luxGold.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(rank, style: TextStyle(color: isGold ? AppColors.luxDarkGreen : AppColors.luxGold, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'serif')),
              Text("${data['totalScore'].toInt()} PTS", style: TextStyle(color: isGold ? AppColors.luxDarkGreen : AppColors.luxGold.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExecutiveRow(Map<String, dynamic> data, int rank) {
    bool isMe = data['uid'] == currentUid;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.luxGold.withOpacity(0.15) : AppColors.luxAccentGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.luxGold.withOpacity(isMe ? 0.7 : 0.1)),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text("#$rank", style: const TextStyle(color: AppColors.luxGold, fontWeight: FontWeight.bold, fontFamily: 'serif'))),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.luxAccentGreen,
            backgroundImage: data['photoUrl'] != null ? NetworkImage(data['photoUrl']) : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'].toUpperCase(), 
                  style: TextStyle(color: Colors.white, fontSize: 13, letterSpacing: 1, fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
                Text("OT: ${data['ot']}  |  ABS: ${data['absent']}", 
                  style: TextStyle(color: AppColors.luxGold.withOpacity(0.4), fontSize: 9)),
              ],
            ),
          ),
          Text("${data['totalScore'].toInt()}", 
            style: const TextStyle(color: AppColors.luxGold, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildListTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Row(
        children: [
          Text("CURRENT STANDINGS", style: TextStyle(color: AppColors.luxGold.withOpacity(0.5), letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: AppColors.luxGold.withOpacity(0.1))),
        ],
      ),
    );
  }

  Widget _buildNoData() => Center(child: Text("NO CYCLE DATA FOUND", style: TextStyle(color: AppColors.luxGold.withOpacity(0.3), letterSpacing: 3, fontSize: 12)));
}