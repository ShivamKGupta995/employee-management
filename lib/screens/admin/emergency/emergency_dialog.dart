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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingContact == null ? "Add Contact" : "Edit Contact"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title (e.g., Ambulance)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
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
              final contact = EmergencyModel(
                id: widget.existingContact?.id ?? '', // Empty ID tells service to Create
                title: _titleController.text.trim(),
                phoneNumber: _phoneController.text.trim(),
                type: _selectedType,
              );
              widget.onSave(contact);
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}