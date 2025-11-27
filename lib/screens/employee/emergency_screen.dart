import 'package:flutter/material.dart';
import 'package:employee_system/config/constants/app_colors.dart';
import 'package:employee_system/config/constants/app_dimensions.dart';
import 'package:employee_system/models/emergency_model.dart';
import 'package:employee_system/services/emergency_service.dart';
import 'package:employee_system/widgets/common/common_widgets.dart'; // For EmptyState & Loading

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final EmergencyService _service = EmergencyService();

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

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'medical': return Colors.red;
      case 'police': return Colors.blue.shade800;
      case 'fire': return Colors.orange.shade800;
      case 'hr': return Colors.purple;
      default: return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        backgroundColor: AppColors.danger, // Red for Emergency
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<EmergencyModel>>(
        stream: _service.getContacts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: LoadingIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState.noData(
              title: "No Contacts Found",
              subtitle: "Emergency contacts have not been added yet."
            );
          }

          final contacts = snapshot.data!;

          return ListView.separated(
            padding: AppDimensions.paddingAll,
            itemCount: contacts.length,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final color = _getColorForType(contact.type);

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusMD),
                child: InkWell(
                  borderRadius: AppDimensions.borderRadiusMD,
                  onTap: () => _service.makePhoneCall(contact.phoneNumber),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        // Big Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getIconForType(contact.type), color: color, size: 32),
                        ),
                        const SizedBox(width: 20),
                        
                        // Text Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.title,
                                style: const TextStyle(
                                  fontSize: 18, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                contact.phoneNumber,
                                style: TextStyle(
                                  fontSize: 16, 
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Call Button
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.call, color: Colors.green),
                        ),
                      ],
                    ),
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