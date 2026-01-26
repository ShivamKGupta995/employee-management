import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:employee_system/config/constants/app_colors.dart';

enum AnalyticsView { monthly, yearly }

class AttendanceIntelScreen extends StatefulWidget {
  const AttendanceIntelScreen({super.key});

  @override
  State<AttendanceIntelScreen> createState() => _AttendanceIntelScreenState();
}

class _AttendanceIntelScreenState extends State<AttendanceIntelScreen> {
  AnalyticsView _viewMode = AnalyticsView.monthly;
  String _selMonth = DateFormat('MMMM').format(DateTime.now());
  String _selYear = DateTime.now().year.toString();

  Map<String, String> _userNames = {};

  List<String> get _yearOptions {
    int currentYear = DateTime.now().year;
    return List.generate((currentYear - 2024) + 3, (index) => (2024 + index).toString());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.luxBgGradient),
      child: SafeArea(
        child: Column(
          children: [
            _buildExecutiveToggle(),
            _buildSelectionHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));
                  final slips = snapshot.data!.docs;
                  if (slips.isEmpty) return _buildNoData();

                  return FutureBuilder(
                    future: _resolveNamesAndAggregate(slips),
                    builder: (context, AsyncSnapshot<Map<String, dynamic>> data) {
                      if (!data.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));
                      return _buildGraphicalDashboard(data.data!);
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
    var query = FirebaseFirestore.instance.collection('salary_slips').where('year', isEqualTo: _selYear);
    if (_viewMode == AnalyticsView.monthly) {
      query = query.where('month', isEqualTo: _selMonth);
    }
    return query.snapshots();
  }

  Future<Map<String, dynamic>> _resolveNamesAndAggregate(List<QueryDocumentSnapshot> slips) async {
    Map<String, Map<String, double>> aggregated = {};
    
    for (var doc in slips) {
      String uid = doc['uid'];
      double p = (doc['present'] ?? 0).toDouble();
      double a = (doc['absent'] ?? 0).toDouble();
      double l = (doc['late'] ?? 0).toDouble();
      double ot = (doc['ot'] ?? 0).toDouble();
      double score = (p * 10) + (ot * 5) - (a * 20) - (l * 5);

      if (!aggregated.containsKey(uid)) {
        aggregated[uid] = {'p': 0, 'a': 0, 'l': 0, 'ot': 0, 'score': 0};
      }
      aggregated[uid]!['p'] = aggregated[uid]!['p']! + p;
      aggregated[uid]!['a'] = aggregated[uid]!['a']! + a;
      aggregated[uid]!['l'] = aggregated[uid]!['l']! + l;
      aggregated[uid]!['ot'] = aggregated[uid]!['ot']! + ot;
      aggregated[uid]!['score'] = aggregated[uid]!['score']! + score;
    }

    List<String> missingUids = aggregated.keys.where((id) => !_userNames.containsKey(id)).toList();
    if (missingUids.isNotEmpty) {
      final userDocs = await Future.wait(missingUids.map((id) => FirebaseFirestore.instance.collection('user').doc(id).get()));
      for (var doc in userDocs) {
        if (doc.exists) {
          _userNames[doc.id] = (doc.data() as Map<String, dynamic>)['name'] ?? "Unknown";
        }
      }
    }
    return aggregated;
  }

  Widget _buildGraphicalDashboard(Map<String, dynamic> aggregatedData) {
    double totalP = 0, totalA = 0, totalL = 0, totalOt = 0;
    List<Map<String, dynamic>> performanceList = [];

    aggregatedData.forEach((uid, stats) {
      totalP += stats['p'];
      totalA += stats['a'];
      totalL += stats['l'];
      totalOt += stats['ot'];
      performanceList.add({
        'name': _userNames[uid] ?? 'Asset',
        'score': stats['score'],
        'ot': stats['ot'],
      });
    });

    performanceList.sort((a, b) => b['score'].compareTo(a['score']));
    var topPerformer = performanceList.take(5).toList();
    
    // OT Sort
    var otKings = List<Map<String, dynamic>>.from(performanceList)
      ..sort((a, b) => b['ot'].compareTo(a['ot']));
    var topOt = otKings.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildQuickStats(totalP, totalA, totalL, totalOt),
        const SizedBox(height: 25),
        
        // 1. Attendance Composition
        _buildChartContainer(
          title: "ATTENDANCE COMPOSITION",
          subtitle: "Visual split of active vs lost days",
          chart: SizedBox(height: 200, child: _buildAttendancePie(totalP, totalA, totalL)),
        ),
        
        const SizedBox(height: 20),

        // 2. Performance Index (Vertical)
        _buildChartContainer(
          title: "EXECUTIVE PERFORMANCE INDEX",
          subtitle: "Ranking based on attendance & punctuality",
          chart: SizedBox(height: 250, child: _buildPerformanceBar(topPerformer)),
        ),

        const SizedBox(height: 20),

        // 3. Overtime Analysis (Horizontal Style / Visual change)
        _buildChartContainer(
          title: "OVERTIME UTILIZATION",
          subtitle: "Hours contributed above standard cycle",
          chart: SizedBox(height: 200, child: _buildOtChart(topOt)),
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  // --- OVERTIME CHART ---
  Widget _buildOtChart(List<Map<String, dynamic>> otData) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: otData.isEmpty ? 10 : otData.first['ot'] + 5,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
            if (v.toInt() >= otData.length) return const SizedBox();
            return Text(otData[v.toInt()]['name'].split(" ")[0], style: const TextStyle(color: Colors.white54, fontSize: 8));
          })),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: otData.asMap().entries.map((e) {
          return BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(toY: e.value['ot'], color: Colors.blueAccent, width: 12, borderRadius: BorderRadius.circular(2))
          ]);
        }).toList(),
      ),
    );
  }

  // --- PERFORMANCE BAR ---
  Widget _buildPerformanceBar(List<Map<String, dynamic>> topData) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: topData.isEmpty ? 100 : topData.first['score'] * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (v, m) {
                if (v.toInt() >= topData.length) return const SizedBox();
                String name = topData[v.toInt()]['name'].split(" ")[0];
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(name.toUpperCase(), style: const TextStyle(color: AppColors.luxGold, fontSize: 8, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: topData.asMap().entries.map((e) {
          return BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(toY: e.value['score'] < 0 ? 0 : e.value['score'], gradient: AppColors.luxGoldGradient, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildQuickStats(double p, double a, double l, double ot) {
    double eff = (p + a + l == 0) ? 0 : (p / (p + a + l)) * 100;
    return Column(
      children: [
        Row(
          children: [
            _statBox("EFFICIENCY", "${eff.toInt()}%", AppColors.luxGold),
            const SizedBox(width: 15),
            _statBox("TOTAL OT", "${ot.toInt()}h", Colors.blueAccent),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _statBox("ABSENTEEISM", "${a.toInt()}", Colors.redAccent),
            const SizedBox(width: 15),
            _statBox("LATE MARKS", "${l.toInt()}", Colors.orangeAccent),
          ],
        ),
      ],
    );
  }

  // --- REUSABLE UI ---

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: AppColors.withValues(AppColors.luxAccentGreen, 0.4), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(children: [
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'serif')),
          Text(label, style: TextStyle(color: color.withOpacity(0.5), fontSize: 8, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildChartContainer({required String title, required String subtitle, required Widget chart}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.withValues(AppColors.luxAccentGreen, 0.4), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.withValues(AppColors.luxGold, 0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppColors.luxGold, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold, fontFamily: 'serif')),
        Text(subtitle, style: TextStyle(color: AppColors.withValues(AppColors.luxGold, 0.3), fontSize: 8)),
        const SizedBox(height: 30),
        chart,
        if (title.contains("ATTENDANCE")) _buildLegend(),
      ],),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legItem("Present", AppColors.luxGold),
          _legItem("Absent", Colors.redAccent),
          _legItem("Late", Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _legItem(String t, Color c) => Row(children: [CircleAvatar(radius: 4, backgroundColor: c), const SizedBox(width: 5), Text(t, style: const TextStyle(color: Colors.white54, fontSize: 9))]);

  Widget _buildExecutiveToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(color: AppColors.luxAccentGreen.withOpacity(0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.luxGold.withOpacity(0.1))),
        child: Row(children: [
          _toggleBtn("MONTHLY", AnalyticsView.monthly),
          _toggleBtn("YEARLY", AnalyticsView.yearly),
        ]),
      ),
    );
  }

  Widget _toggleBtn(String label, AnalyticsView mode) {
    bool isSel = _viewMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewMode = mode),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: isSel ? AppColors.luxGoldGradient : null),
          child: Center(child: Text(label, style: TextStyle(color: isSel ? AppColors.luxDarkGreen : AppColors.luxGold.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2))),
        ),
      ),
    );
  }

  Widget _buildSelectionHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          if (_viewMode == AnalyticsView.monthly)
            Expanded(child: _luxDrop(_selMonth, ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"], (v) => setState(() => _selMonth = v!))),
          if (_viewMode == AnalyticsView.monthly) const SizedBox(width: 10),
          Expanded(child: _luxDrop(_selYear, _yearOptions, (v) => setState(() => _selYear = v!))),
        ],
      ),
    );
  }

  Widget _luxDrop(String val, List<String> items, Function(String?) onChg) {
    return Container(
      decoration: BoxDecoration(color: AppColors.withValues(AppColors.luxAccentGreen, 0.4), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.withValues(AppColors.luxGold, 0.2))),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: val, isExpanded: true, dropdownColor: AppColors.luxAccentGreen,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.luxGold, size: 16),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          onChanged: onChg,
        ),
      ),
    );
  }

  Widget _buildAttendancePie(double p, double a, double l) {
    if (p + a + l == 0) return const Center(child: Text("NO DATA", style: TextStyle(color: Colors.white24)));
    return PieChart(PieChartData(sectionsSpace: 4, centerSpaceRadius: 40, sections: [
      PieChartSectionData(value: p, color: AppColors.luxGold, radius: 45, title: ''),
      PieChartSectionData(value: a, color: Colors.redAccent, radius: 40, title: ''),
      PieChartSectionData(value: l, color: Colors.orangeAccent, radius: 35, title: ''),
    ]));
  }

  Widget _buildNoData() => Center(child: Text("NO RECORDS FOUND", style: TextStyle(color: AppColors.withValues(AppColors.luxGold, 0.2), letterSpacing: 2)));
}