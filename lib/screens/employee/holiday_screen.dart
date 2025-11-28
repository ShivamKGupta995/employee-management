import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ✅ IMPORT THE MODEL
import 'package:employee_system/models/holiday_model.dart';
// ✅ IMPORT THE SERVICE
import 'package:employee_system/services/holiday_service.dart';

class HolidayScreen extends StatefulWidget {
  const HolidayScreen({Key? key}) : super(key: key);

  @override
  State<HolidayScreen> createState() => _HolidayScreenState();
}

class _HolidayScreenState extends State<HolidayScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HolidayService _service = HolidayService();
  
  // ✅ Variable to store the current year
  late int _currentYear;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // ✅ Initialize current year from system
    _currentYear = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Holiday Calendar"),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Year Selector
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              dropdownColor: Colors.blue.shade900,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              value: _selectedYear,
              items: [_currentYear - 1, _currentYear, _currentYear + 1].map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text("$year", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedYear = val!),
            ),
          ),
          const SizedBox(width: 15),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Public Holidays"),
            Tab(text: "Company Holidays"),
          ],
        ),
      ),
      // ✅ FIX: Use 'HolidayModel' generic type
      body: StreamBuilder<List<HolidayModel>>(
        // ✅ FIX: Use correct method 'getHolidaysForYear'
        stream: _service.getHolidaysForYear(_selectedYear),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final allHolidays = snapshot.data!;
          final public = allHolidays.where((h) => h.type == 'Public').toList();
          final company = allHolidays.where((h) => h.type == 'Company').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(public, Colors.red),
              _buildList(company, Colors.blue),
            ],
          );
        },
      ),
    );
  }

  // ✅ FIX: Ensure 'List<HolidayModel>' is recognized
  Widget _buildList(List<HolidayModel> holidays, Color themeColor) {
    if (holidays.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: holidays.length,
      itemBuilder: (context, index) {
        final holiday = holidays[index];
        // ✅ Check if holiday is in the past by comparing with current year and today's date
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final bool isPast = holiday.date.isBefore(today);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isPast ? Colors.grey[200] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isPast ? [] : [
              BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              // Date Box
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isPast ? Colors.grey[400] : themeColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat('dd').format(holiday.date), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isPast ? Colors.white : themeColor)),
                    Text(DateFormat('MMM').format(holiday.date).toUpperCase(), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isPast ? Colors.white : themeColor)),
                  ],
                ),
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(holiday.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isPast ? Colors.grey : Colors.black87, decoration: isPast ? TextDecoration.lineThrough : null)),
                      const SizedBox(height: 4),
                      // ✅ FIX: Use 'dayName' from the model helper we created
                      Text(holiday.dayName, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                ),
              ),
              // Badge
              if (!isPast)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text("Upcoming", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text("No holidays found", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }
}