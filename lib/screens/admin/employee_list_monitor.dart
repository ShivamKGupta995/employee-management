import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:employee_system/config/constants/app_colors.dart'; // Adjust path
import 'employee_monitor_dashboard.dart';

class EmployeeListMonitor extends StatelessWidget {
  const EmployeeListMonitor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxDarkGreen,
      appBar: AppBar(
        title: const Text("ASSET MONITORING", 
          style: TextStyle(letterSpacing: 3, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.luxGold,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.luxBgGradient, // Your lux radial gradient
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('user').where('role', isEqualTo: 'employee').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var emp = snapshot.data!.docs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: AppColors.luxAccentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.2)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.5))),
                      child: CircleAvatar(
                        backgroundColor: AppColors.luxAccentGreen,
                        child: Text(emp['name'][0].toUpperCase(), style: const TextStyle(color: AppColors.luxGold, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    title: Text(emp['name'].toUpperCase(), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'serif', letterSpacing: 1)),
                    subtitle: Text(emp['department']?.toUpperCase() ?? 'GENERAL', 
                      style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 1.5)),
                    trailing: const Icon(Icons.radar, color: AppColors.luxGold, size: 20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmployeeMonitorDashboard(
                            employeeId: emp.id,
                            employeeName: emp['name'],
                          ),
                        ),
                      );
                    },
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