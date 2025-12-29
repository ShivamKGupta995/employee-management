import 'package:flutter/material.dart';
import 'package:employee_system/config/constants/app_colors.dart';
import 'package:employee_system/models/emergency_model.dart';
import 'package:employee_system/services/emergency_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final EmergencyService _service = EmergencyService();

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'medical': return Icons.health_and_safety_outlined;
      case 'police': return Icons.gavel_outlined;
      case 'fire': return Icons.local_fire_department_outlined;
      case 'hr': return Icons.badge_outlined;
      case 'security': return Icons.verified_user_outlined;
      default: return Icons.support_agent_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxDarkGreen,
      appBar: AppBar(
        title: const Text("CRISIS PROTOCOL", 
          style: TextStyle(letterSpacing: 4, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'serif')),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.luxGold,
        centerTitle: true,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.2,
            colors: [Color(0xFF1D322C), AppColors.luxDarkGreen],
          ),
        ),
        child: StreamBuilder<List<EmergencyModel>>(
          stream: _service.getContacts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final contacts = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.only(top: 130, left: 24, right: 24, bottom: 40),
              children: [
                // --- HEADER SECTION ---
                _buildSectionHeader(),
                const SizedBox(height: 30),

                // --- CONTACTS LIST ---
                ...contacts.map((contact) => _buildLuxuryContactCard(contact)).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text("SYSTEM STATUS: ACTIVE", 
              style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.6), letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        const Text("Verified Support Lines", 
          style: TextStyle(color: AppColors.luxGold, fontSize: 24, fontFamily: 'serif', fontWeight: FontWeight.w400)),
      ],
    );
  }

  Widget _buildLuxuryContactCard(EmergencyModel contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(1), // Border width
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [AppColors.luxGold.withValues(alpha: 0.3), Colors.transparent],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.luxDarkGreen.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(19),
        ),
        child: Row(
          children: [
            // Left Icon Column
            Column(
              children: [
                Icon(_getIconForType(contact.type), color: AppColors.luxGold, size: 30),
                const SizedBox(height: 8),
                Container(width: 1, height: 20, color: AppColors.luxGold.withValues(alpha: 0.2)),
              ],
            ),
            const SizedBox(width: 20),
            
            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.title.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'serif', letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(contact.phoneNumber,
                    style: TextStyle(color: AppColors.luxGold, fontSize: 14, letterSpacing: 2.5, fontWeight: FontWeight.w300)),
                ],
              ),
            ),

            // Premium Call Button
            InkWell(
              onTap: () => _service.makePhoneCall(contact.phoneNumber),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(color: AppColors.luxGold.withValues(alpha: 0.1), blurRadius: 10)
                  ]
                ),
                child: const Row(
                  children: [
                    Text("DIAL", style: TextStyle(color: AppColors.luxGold, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    SizedBox(width: 8),
                    Icon(Icons.north_east_rounded, color: AppColors.luxGold, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield_moon_outlined, size: 80, color: AppColors.luxGold),
          const SizedBox(height: 20),
          const Text("LINES SECURE", 
            style: TextStyle(color: AppColors.luxGold, fontSize: 18, letterSpacing: 3, fontFamily: 'serif')),
          const SizedBox(height: 10),
          Text("No emergency contacts currently registered.", 
            style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.5), fontSize: 12)),
        ],
      ),
    );
  }
}