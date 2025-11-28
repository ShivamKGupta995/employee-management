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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingHoliday == null ? "Add Holiday" : "Edit Holiday"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Holiday Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.celebration),
                ),
                validator: (val) => val!.isEmpty ? "Enter a name" : null,
              ),
              const SizedBox(height: 15),

              // Date Picker
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2024), // Allow past
                    lastDate: DateTime(2030), // Allow future years
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Date",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat.yMMMEd().format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 15),

              // Type Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: "Holiday Type",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: ['Public', 'Company'].map((type) {
                  return DropdownMenuItem(value: type, child: Text("$type Holiday"));
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
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newHoliday = HolidayModel(
  id: widget.existingHoliday?.id, // ✅ If null, Service will use .add() (Auto-ID)
                name: _nameController.text,
                date: _selectedDate,
                type: _selectedType,
              );
              widget.onSave(newHoliday);
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}