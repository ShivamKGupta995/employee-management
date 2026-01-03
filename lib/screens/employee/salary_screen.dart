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
        title: const Text("OFFICIAL STATEMENT", 
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
            radius: 1.2,
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
    
    // Core Parameters
    int present = (data['present'] ?? 0).toInt();
    int absent = (data['absent'] ?? 0).toInt();
    int late = (data['late'] ?? 0).toInt();
    int ot = (data['ot'] ?? 0).toInt();
    int others = (data['others'] ?? 0).toInt();

    // Weighted Score Logic (Consistent with Leaderboard)
    double rawScore = (present * 10.0) + (ot * 5.0) - (absent * 20.0) - (late * 5.0);
    // Normalize score for UI Progress Bar (Assume 250 is a 'perfect' month)
    double progressValue = (rawScore / 250).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 120, left: 24, right: 24, bottom: 40),
      child: Column(
        children: [
          // --- MAIN EXECUTIVE CARD ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(1.5), 
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [AppColors.luxGold.withValues(alpha: 0.6), Colors.transparent, AppColors.luxGold.withValues(alpha: 0.6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.luxDarkGreen.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified_outlined, color: AppColors.luxGold, size: 45),
                  const SizedBox(height: 15),
                  Text("PERFORMANCE CERTIFICATION", 
                    style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.5), letterSpacing: 2.5, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("$month $year",
                    style: const TextStyle(color: AppColors.luxGold, fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                  const SizedBox(height: 30),
                  
                  // New Dynamic Score Bar
                  _buildScoreIndicator(progressValue, rawScore.toInt()),
                  
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _headerDetail("STATUS", rawScore > 150 ? "ELITE" : "ACTIVE"),
                      Container(width: 1, height: 25, color: AppColors.luxGold.withValues(alpha: 0.2)),
                      _headerDetail("GRADE", rawScore > 200 ? "A+" : (rawScore > 100 ? "B" : "C")),
                    ],
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // --- ALL PARAMETERS GRID ---
          _sectionLabel("DETAILED METRICS"),
          const SizedBox(height: 15),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.2,
            children: [
              _buildMetricTile("PRESENT", "$present", Icons.calendar_today_outlined, Colors.white),
              _buildMetricTile("OVERTIME", "+$ot", Icons.bolt_rounded, AppColors.luxGold),
              _buildMetricTile("LATE ENTRY", "$late", Icons.timer_outlined, Colors.white),
              _buildMetricTile("ABSENT", "$absent", Icons.event_busy_outlined, Colors.redAccent.withValues(alpha: 0.7)),
              _buildMetricTile("TOTAL CYCLE", "${present + absent}", Icons.loop_rounded, Colors.white),
              _buildMetricTile("OTHERS", "$others", Icons.tune_rounded, Colors.white),
            ],
          ),

          const SizedBox(height: 50),
          
          // --- SECURITY FOOTER ---
          const Icon(Icons.lock_outline, color: AppColors.luxGold, size: 16),
          const SizedBox(height: 12),
          Text(
            "This statement is a confidential record generated for the authorized asset. Any unauthorized duplication is strictly prohibited.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.3), fontSize: 9, height: 1.8, letterSpacing: 0.5),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildScoreIndicator(double progress, int points) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("EFFICIENCY INDEX", style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.6), fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            Text("$points PTS", style: const TextStyle(color: AppColors.luxGold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.luxGold.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: AppColors.luxGoldGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: AppColors.luxGold.withValues(alpha: 0.3), blurRadius: 8)
                  ]
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerDetail(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.4), fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon, Color valColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.luxAccentGreen.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.luxGold.withValues(alpha: 0.5), size: 22),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: valColor, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'serif')),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.4), fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t) => Row(
    children: [
      Text(t, style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.6), letterSpacing: 3, fontSize: 10, fontWeight: FontWeight.bold)),
      const SizedBox(width: 15),
      Expanded(child: Divider(color: AppColors.luxGold.withValues(alpha: 0.1), thickness: 0.5)),
    ],
  );

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_motion_outlined, size: 60, color: AppColors.luxGold.withValues(alpha: 0.2)),
          const SizedBox(height: 20),
          const Text("DATA SYNCHRONIZING", style: TextStyle(color: AppColors.luxGold, fontSize: 16, letterSpacing: 3, fontFamily: 'serif')),
          const SizedBox(height: 10),
          Text("Waiting for the next official cycle release.", style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.4), fontSize: 11)),
        ],
      ),
    );
  }


}