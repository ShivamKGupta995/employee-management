import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'employee_monitor_dashboard.dart'; // We will create this next

class EmployeeListMonitor extends StatelessWidget {
  const EmployeeListMonitor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Employee to Track")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('user').where('role', isEqualTo: 'employee').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var emp = snapshot.data!.docs[index];
              return ListTile(
                leading: CircleAvatar(child: Text(emp['name'][0])),
                title: Text(emp['name']),
                subtitle: Text(emp['department'] ?? ''),
                trailing: const Icon(Icons.arrow_forward_ios),
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
              );
            },
          );
        },
      ),
    );
  }
}