import 'package:flutter/material.dart';
import 'package:employee_system/config/constants/app_colors.dart';
import 'package:employee_system/models/emergency_model.dart';
import 'package:employee_system/services/emergency_service.dart';
import 'package:employee_system/screens/admin/emergency/emergency_dialog.dart';

class ManageEmergencyScreen extends StatefulWidget {
  const ManageEmergencyScreen({Key? key}) : super(key: key);

  @override
  State<ManageEmergencyScreen> createState() => _ManageEmergencyScreenState();
}

class _ManageEmergencyScreenState extends State<ManageEmergencyScreen> {
  final EmergencyService _service = EmergencyService();

  void _showEditor({EmergencyModel? contact}) {
    showDialog(
      context: context,
      builder: (context) => EmergencyDialog(
        existingContact: contact,
        onSave: (newContact) async {
          await _service.saveContact(newContact);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'medical': return Icons.health_and_safety_outlined;
      case 'police': return Icons.gavel_outlined;
      case 'fire': return Icons.local_fire_department_outlined;
      case 'hr': return Icons.badge_outlined;
      case 'security': return Icons.verified_user_outlined;
      default: return Icons.phone_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxDarkGreen,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 60, height: 60,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.luxGoldGradient),
          child: const Icon(Icons.add_call, color: AppColors.luxDarkGreen),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.luxBgGradient),
        child: StreamBuilder<List<EmergencyModel>>(
          stream: _service.getContacts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 60, color: AppColors.luxGold.withValues(alpha: 0.2)),
                    const SizedBox(height: 20),
                    Text("NO ACTIVE PROTOCOLS", 
                      style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.5), letterSpacing: 3, fontFamily: 'serif')),
                  ],
                ),
              );
            }

            final contacts = snapshot.data!;

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 15),
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.luxAccentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.2), width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.3)),
                        color: AppColors.luxGold.withValues(alpha: 0.05),
                      ),
                      child: Icon(_getIconForType(contact.type), color: AppColors.luxGold, size: 24),
                    ),
                    title: Text(contact.title.toUpperCase(), 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5, fontFamily: 'serif', fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(contact.phoneNumber, 
                          style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.7), fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.w300)),
                        const SizedBox(height: 4),
                        Text(contact.type.toUpperCase(), 
                          style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.luxGold, size: 20),
                          onPressed: () => _showEditor(contact: contact),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_sweep_outlined, color: Colors.redAccent.withValues(alpha: 0.6), size: 20),
                          onPressed: () {
                            _service.deleteContact(contact.id);
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