import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:employee_system/models/holiday_model.dart';
import 'package:employee_system/config/constants/app_colors.dart';

class HolidayDialog extends StatefulWidget {
  final HolidayModel? existingHoliday;
  final Function(HolidayModel) onSave;

  const HolidayDialog({super.key, this.existingHoliday, required this.onSave});

  @override
  State<HolidayDialog> createState() => _HolidayDialogState();
}

class _HolidayDialogState extends State<HolidayDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'Public';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingHoliday?.name ?? '');
    if (widget.existingHoliday != null) {
      _selectedDate = widget.existingHoliday!.date;
      _selectedType = widget.existingHoliday!.type;
    }
  }

  InputDecoration _luxInput(String label, IconData icon) => InputDecoration(
    labelText: label.toUpperCase(),
    labelStyle: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.6), letterSpacing: 2, fontSize: 11),
    prefixIcon: Icon(icon, color: AppColors.luxGold, size: 20),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.luxGold.withValues(alpha: 0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.luxGold, width: 1.5),
    ),
    filled: true,
    fillColor: AppColors.luxAccentGreen.withValues(alpha: 0.2),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.luxDarkGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.luxGold.withValues(alpha: 0.3), width: 1),
      ),
      title: Text(
        widget.existingHoliday == null ? "NEW HOLIDAY ENTRY" : "EDIT HOLIDAY RECORD",
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.luxGold, fontFamily: 'serif', letterSpacing: 2, fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // Name Field
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _luxInput("Holiday Name", Icons.celebration_outlined),
                validator: (val) => val!.isEmpty ? "Enter a valid name" : null,
              ),
              const SizedBox(height: 15),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                    builder: (context, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.luxGold,
                          onPrimary: AppColors.luxDarkGreen,
                          surface: AppColors.luxAccentGreen,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: _luxInput("Date Selection", Icons.calendar_today_outlined),
                  child: Text(
                    DateFormat.yMMMEd().format(_selectedDate),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: AppColors.luxAccentGreen,
                style: const TextStyle(color: Colors.white),
                decoration: _luxInput("Holiday Category", Icons.category_outlined),
                items: ['Public', 'Company'].map((type) {
                  return DropdownMenuItem(
                    value: type, 
                    child: Text("$type Holiday", style: const TextStyle(fontSize: 14))
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCEL", style: TextStyle(color: AppColors.luxGold, letterSpacing: 1.5, fontSize: 12)),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            if (_formKey.currentState!.validate()) {
              final newHoliday = HolidayModel(
                id: widget.existingHoliday?.id,
                name: _nameController.text,
                date: _selectedDate,
                type: _selectedType,
              );
              widget.onSave(newHoliday);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: AppColors.luxGoldGradient,
            ),
            child: const Text(
              "SAVE RECORD",
              style: TextStyle(color: AppColors.luxDarkGreen, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}