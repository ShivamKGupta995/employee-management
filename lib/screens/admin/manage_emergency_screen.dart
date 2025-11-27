import 'package:flutter/material.dart';
import 'package:employee_system/config/constants/app_colors.dart';
import 'package:employee_system/config/constants/app_dimensions.dart';
import 'package:employee_system/models/emergency_model.dart';
import 'package:employee_system/services/emergency_service.dart';
import 'package:employee_system/widgets/common/common_widgets.dart'; // AppButton, LoadingIndicator
import 'package:employee_system/utils/utils.dart'; // DialogHelper, SnackbarHelper

// Import the Dialog (created in next step)
import 'package:employee_system/screens/admin/emergency/emergency_dialog.dart'; 

class ManageEmergencyScreen extends StatefulWidget {
  const ManageEmergencyScreen({Key? key}) : super(key: key);

  @override
  State<ManageEmergencyScreen> createState() => _ManageEmergencyScreenState();
}

class _ManageEmergencyScreenState extends State<ManageEmergencyScreen> {
  final EmergencyService _service = EmergencyService();

  // Open Dialog for Add or Edit
  void _showEditor({EmergencyModel? contact}) {
    showDialog(
      context: context,
      builder: (context) => EmergencyDialog(
        existingContact: contact,
        onSave: (newContact) async {
          await _service.saveContact(newContact);
          if (mounted) Navigator.pop(context); // Close dialog
          SnackbarHelper.showSuccess(context, "Contact saved successfully!");
        },
      ),
    );
  }

  // Confirm and Delete
  void _confirmDelete(String id) {
    DialogHelper.showDeleteConfirmation(context, itemName: "this contact").then((confirm) {
      if (confirm == true) {
        _service.deleteContact(id);
        SnackbarHelper.showSuccess(context, "Contact deleted.");
      }
    });
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'medical': return Icons.medical_services;
      case 'police': return Icons.local_police;
      case 'fire': return Icons.fire_truck;
      case 'hr': return Icons.support_agent;
      case 'security': return Icons.security;
      default: return Icons.phone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Manage Emergency Contacts"),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.danger,
        icon: const Icon(Icons.add_call),
        label: const Text("Add Contact"),
        onPressed: () => _showEditor(),
      ),
      body: StreamBuilder<List<EmergencyModel>>(
        stream: _service.getContacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState.noData(title: "No contacts added yet.");
          }

          final contacts = snapshot.data!;

          return ListView.separated(
            padding: AppDimensions.paddingAll,
            itemCount: contacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusMD),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(_getIconForType(contact.type), color: AppColors.primary),
                  ),
                  title: Text(contact.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${contact.phoneNumber} • ${contact.type}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditor(contact: contact),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(contact.id),
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