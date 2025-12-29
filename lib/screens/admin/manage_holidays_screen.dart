import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:employee_system/config/constants/app_colors.dart';
import 'package:employee_system/models/holiday_model.dart';
import 'package:employee_system/services/holiday_service.dart';
import 'package:employee_system/screens/admin/holidays/holiday_dialog.dart';

class ManageHolidaysScreen extends StatefulWidget {
  const ManageHolidaysScreen({Key? key}) : super(key: key);

  @override
  State<ManageHolidaysScreen> createState() => _ManageHolidaysScreenState();
}

class _ManageHolidaysScreenState extends State<ManageHolidaysScreen> {
  final HolidayService _service = HolidayService();

  void _showHolidayDialog({HolidayModel? holiday}) {
    showDialog(
      context: context,
      builder: (context) => HolidayDialog(
        existingHoliday: holiday,
        onSave: (newHoliday) async {
          await _service.saveHoliday(newHoliday);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxDarkGreen,
      appBar: AppBar(
        title: const Text("HOLIDAY MANAGEMENT", 
          style: TextStyle(letterSpacing: 3, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif')),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.luxGold,
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHolidayDialog(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 60, height: 60,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.luxGoldGradient),
          child: const Icon(Icons.add, color: AppColors.luxDarkGreen),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.luxBgGradient),
        child: StreamBuilder<List<HolidayModel>>(
          stream: _service.getAllHolidays(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy_outlined, size: 60, color: AppColors.luxGold.withValues(alpha: 0.2)),
                    const SizedBox(height: 20),
                    Text("NO RECORDS FOUND", 
                      style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.5), letterSpacing: 3, fontFamily: 'serif')),
                  ],
                ),
              );
            }

            final holidays = snapshot.data!;

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: holidays.length,
              separatorBuilder: (_, __) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                final holiday = holidays[index];
                final bool isPublic = holiday.type == 'Public';

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.luxAccentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.2), width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    leading: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.3)),
                        color: AppColors.luxGold.withValues(alpha: 0.05),
                      ),
                      child: Center(
                        child: Text(
                          holiday.date.day.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.luxGold, fontSize: 18, fontFamily: 'serif'),
                        ),
                      ),
                    ),
                    title: Text(holiday.name.toUpperCase(), 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1, fontFamily: 'serif')),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(DateFormat.yMMMEd().format(holiday.date).toUpperCase(), 
                          style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(holiday.type.toUpperCase(), 
                          style: TextStyle(color: isPublic ? Colors.redAccent.withValues(alpha: 0.7) : Colors.blueAccent.withValues(alpha: 0.7), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.luxGold, size: 20),
                          onPressed: () => _showHolidayDialog(holiday: holiday),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.redAccent.withValues(alpha: 0.6), size: 20),
                          onPressed: () {
                            _service.deleteHoliday(holiday.id!);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}