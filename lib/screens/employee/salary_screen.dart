import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:employee_system/config/constants/app_colors.dart';

class SalaryScreen extends StatelessWidget {
  const SalaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.luxDarkGreen,
      appBar: AppBar(
        title: const Text("MONTHLY STATEMENT", 
          style: TextStyle(letterSpacing: 4, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'serif')),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.luxGold,
        centerTitle: true,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.0,
            colors: [Color(0xFF1D322C), AppColors.luxDarkGreen],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('salary_slips')
              .where('uid', isEqualTo: user?.uid)
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildNoDataView();
            }

            final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            return _buildPremiumReport(data);
          },
        ),
      ),
    );
  }

  Widget _buildPremiumReport(Map<String, dynamic> data) {
    String month = data['month'] ?? "--";
    String year = data['year'] ?? "--";
    int present = (data['present'] ?? 0).toInt();
    int absent = (data['absent'] ?? 0).toInt();
    int late = (data['late'] ?? 0).toInt();
    double totalDays = (present + absent).toDouble();
    int score = totalDays > 0 ? ((present / totalDays) * 100).toInt() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 120, left: 24, right: 24, bottom: 40),
      child: Column(
        children: [
          // --- MAIN CERTIFICATE CARD ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(2), // Outer border spacing
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [AppColors.luxGold.withValues(alpha: 0.5), Colors.transparent, AppColors.luxGold.withValues(alpha: 0.5)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.luxDarkGreen.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified_user, color: AppColors.luxGold, size: 40),
                  const SizedBox(height: 20),
                  Text("OFFICIAL ATTENDANCE REPORT", 
                    style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.5), letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text("$month, $year",
                    style: const TextStyle(color: AppColors.luxGold, fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                  const SizedBox(height: 30),
                  
                  // Score Indicator
                  _buildScoreIndicator(score),
                  
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _headerDetail("STATUS", score > 80 ? "EXCELLENT" : "GOOD"),
                      Container(width: 1, height: 30, color: AppColors.luxGold.withValues(alpha: 0.2)),
                      _headerDetail("RATING", score > 90 ? "A+" : "B"),
                    ],
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // --- SECTION HEADER ---
          Row(
            children: [
              const Text("METRICS", style: TextStyle(color: AppColors.luxGold, letterSpacing: 3, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Expanded(child: Divider(color: AppColors.luxGold.withValues(alpha: 0.2))),
            ],
          ),
          const SizedBox(height: 10),

          // --- REFINED STATS GRID ---
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildMetricTile("PRESENT", "$present", Icons.calendar_today_outlined),
              _buildMetricTile("ABSENT", "$absent", Icons.event_busy_outlined),
              _buildMetricTile("LATE", "$late", Icons.timer_outlined),
              _buildMetricTile("TOTAL", "${present + absent}", Icons.analytics_outlined),
            ],
          ),

          const SizedBox(height: 50),
          
          // --- FOOTER ---
          const Icon(Icons.shield, color: AppColors.luxGold, size: 18),
          const SizedBox(height: 10),
          Text(
            "This report is an official record generated by the Human Resources Management System. All data is timestamped and verified.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.4), fontSize: 10, height: 1.8, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(int score) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("PERFORMANCE SCORE", style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.7), fontSize: 10, letterSpacing: 1)),
            Text("$score%", style: const TextStyle(color: AppColors.luxGold, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 6,
            backgroundColor: AppColors.luxGold.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.luxGold),
          ),
        ),
      ],
    );
  }

  Widget _headerDetail(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.4), fontSize: 9, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.luxGold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.luxAccentGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.luxGold.withValues(alpha: 0.6), size: 24),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'serif')),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_empty_rounded, size: 60, color: AppColors.luxGold),
          const SizedBox(height: 20),
          const Text("PENDING RELEASE", style: TextStyle(color: AppColors.luxGold, fontSize: 18, letterSpacing: 2, fontFamily: 'serif')),
          const SizedBox(height: 10),
          Text("We haven't received your latest report yet.", style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.5), fontSize: 12)),
        ],
      ),
    );
  }
}