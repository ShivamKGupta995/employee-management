import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:employee_system/config/constants/app_colors.dart'; // Adjust path
import 'package:employee_system/models/holiday_model.dart';
import 'package:employee_system/services/holiday_service.dart';

class HolidayScreen extends StatefulWidget {
  const HolidayScreen({Key? key}) : super(key: key);

  @override
  State<HolidayScreen> createState() => _HolidayScreenState();
}

class _HolidayScreenState extends State<HolidayScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HolidayService _service = HolidayService();
  
  late int _currentYear;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentYear = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxDarkGreen,
      appBar: AppBar(
        title: const Text("HOLIDAY CALENDAR", 
          style: TextStyle(letterSpacing: 3, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif')),
        backgroundColor: AppColors.luxDarkGreen,
        foregroundColor: AppColors.luxGold,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Year Selector Styled for Luxury
          Theme(
            data: Theme.of(context).copyWith(canvasColor: AppColors.luxAccentGreen),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                icon: const Icon(Icons.calendar_month, color: AppColors.luxGold, size: 20),
                value: _selectedYear,
                items: [_currentYear - 1, _currentYear, _currentYear + 1].map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(" $year ", style: const TextStyle(color: AppColors.luxGold, fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedYear = val!),
              ),
            ),
          ),
          const SizedBox(width: 15),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.luxGold,
          indicatorWeight: 3,
          labelColor: AppColors.luxGold,
          unselectedLabelColor: AppColors.luxGold.withValues(alpha: 0.4),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: 'serif'),
          tabs: const [
            Tab(text: "PUBLIC"),
            Tab(text: "COMPANY"),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF1D322C), AppColors.luxDarkGreen],
          ),
        ),
        child: StreamBuilder<List<HolidayModel>>(
          stream: _service.getHolidaysForYear(_selectedYear),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));
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
                _buildList(public),
                _buildList(company),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<HolidayModel> holidays) {
    if (holidays.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      itemCount: holidays.length,
      itemBuilder: (context, index) {
        final holiday = holidays[index];
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final bool isPast = holiday.date.isBefore(today);

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isPast 
                ? AppColors.luxAccentGreen.withValues(alpha: 0.1) 
                : AppColors.luxAccentGreen.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isPast ? AppColors.luxGold.withValues(alpha: 0.1) : AppColors.luxGold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Date Badge
                Container(
                  width: 75,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: isPast 
                        ? Colors.transparent 
                        : AppColors.luxGold.withValues(alpha: 0.05),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
                    border: Border(right: BorderSide(color: AppColors.luxGold.withValues(alpha: 0.1))),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(DateFormat('dd').format(holiday.date), 
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.bold, 
                          fontFamily: 'serif',
                          color: isPast ? AppColors.luxGold.withValues(alpha: 0.3) : AppColors.luxGold
                        )),
                      Text(DateFormat('MMM').format(holiday.date).toUpperCase(), 
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1,
                          color: isPast ? AppColors.luxGold.withValues(alpha: 0.2) : AppColors.luxGold.withValues(alpha: 0.7)
                        )),
                    ],
                  ),
                ),
                
                // Details
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(holiday.name, 
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold, 
                            fontFamily: 'serif',
                            color: isPast ? AppColors.luxGold.withValues(alpha: 0.3) : Colors.white,
                            decoration: isPast ? TextDecoration.lineThrough : null
                          )),
                        const SizedBox(height: 6),
                        Text(holiday.dayName.toUpperCase(), 
                          style: TextStyle(
                            color: AppColors.luxGold.withValues(alpha: 0.4), 
                            fontSize: 10, 
                            letterSpacing: 1.5
                          )),
                      ],
                    ),
                  ),
                ),

                // Status Indicator
                if (!isPast)
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.5)),
                      ),
                      child: const Text("UPCOMING", 
                        style: TextStyle(fontSize: 8, color: AppColors.luxGold, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  )
              ],
            ),
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
          Icon(Icons.event_busy_outlined, size: 60, color: AppColors.luxGold.withValues(alpha: 0.2)),
          const SizedBox(height: 20),
          Text("NO SCHEDULED EVENTS", 
            style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.5), fontSize: 14, letterSpacing: 2, fontFamily: 'serif')),
        ],
      ),
    );
  }
}