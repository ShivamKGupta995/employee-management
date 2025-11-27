import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:employee_system/config/constants/app_colors.dart';
import 'package:employee_system/config/constants/app_dimensions.dart';
import 'package:employee_system/models/holiday_model.dart';
import 'package:employee_system/services/holiday_service.dart';
import 'package:employee_system/widgets/common/common_widgets.dart'; // Using AppButton, AppTextField
import 'package:employee_system/utils/utils.dart'; // Using DateFormatter, SnackbarHelper
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
          SnackbarHelper.showSuccess(context, "Holiday saved successfully!");
        },
      ),
    );
  }

  void _confirmDelete(String id) {
    DialogHelper.showDeleteConfirmation(context, itemName: "this holiday").then((confirm) {
      if (confirm == true) {
        _service.deleteHoliday(id);
        SnackbarHelper.showSuccess(context, "Holiday deleted.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Manage Holidays"),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text("Add Holiday"),
        onPressed: () => _showHolidayDialog(),
      ),
      body: StreamBuilder<List<HolidayModel>>(
        stream: _service.getAllHolidays(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState.noData(title: "No holidays added yet.");
          }

          final holidays = snapshot.data!;

          return ListView.separated(
            padding: AppDimensions.paddingAll,
            itemCount: holidays.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final holiday = holidays[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusMD),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: holiday.type == 'Public' 
                        ? Colors.red.withAlpha(25) 
                        : Colors.blue.withAlpha(25),
                    child: Text(
                      holiday.date.day.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: holiday.type == 'Public' ? Colors.red : Colors.blue,
                      ),
                    ),
                  ),
                  title: Text(holiday.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${DateFormat.yMMMEd().format(holiday.date)} • ${holiday.type}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        onPressed: () => _showHolidayDialog(holiday: holiday),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(holiday.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}