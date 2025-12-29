import 'package:flutter/material.dart';
import 'package:employee_system/models/emergency_model.dart';
import 'package:employee_system/config/constants/app_colors.dart';

class EmergencyDialog extends StatefulWidget {
  final EmergencyModel? existingContact;
  final Function(EmergencyModel) onSave;

  const EmergencyDialog({Key? key, this.existingContact, required this.onSave}) : super(key: key);

  @override
  State<EmergencyDialog> createState() => _EmergencyDialogState();
}

class _EmergencyDialogState extends State<EmergencyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _phoneController;
  String _selectedType = 'General';

  final List<String> _types = ['Medical', 'Police', 'Fire', 'HR', 'Security', 'General'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingContact?.title ?? '');
    _phoneController = TextEditingController(text: widget.existingContact?.phoneNumber ?? '');
    if (widget.existingContact != null) {
      _selectedType = widget.existingContact!.type;
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
        widget.existingContact == null ? "NEW SUPPORT LINE" : "UPDATE PROTOCOL",
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.luxGold, fontFamily: 'serif', letterSpacing: 3, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // Title Field
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: _luxInput("Entity Name", Icons.badge_outlined),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, letterSpacing: 2),
                decoration: _luxInput("Contact Number", Icons.phone_outlined),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),

              // Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                dropdownColor: AppColors.luxAccentGreen,
                style: const TextStyle(color: Colors.white),
                decoration: _luxInput("Protocol Category", Icons.category_outlined),
                items: _types.map((type) => DropdownMenuItem(
                  value: type, 
                  child: Text(type.toUpperCase(), style: const TextStyle(fontSize: 12, letterSpacing: 1))
                )).toList(),
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
              final contact = EmergencyModel(
                id: widget.existingContact?.id ?? '',
                title: _titleController.text.trim(),
                phoneNumber: _phoneController.text.trim(),
                type: _selectedType,
              );
              widget.onSave(contact);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: AppColors.luxGoldGradient,
            ),
            child: const Text(
              "AUTHORIZE",
              style: TextStyle(color: AppColors.luxDarkGreen, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}