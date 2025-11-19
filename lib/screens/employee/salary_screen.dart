import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class SalaryScreen extends StatelessWidget {
  const SalaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Latest Salary Slip"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 1. THE MAGIC QUERY:
        // Get slips for this user -> Sort by Newest -> Take only ONE.
        stream: FirebaseFirestore.instance
            .collection('salary_slips')
            .where('uid', isEqualTo: user?.uid)
            .orderBy('timestamp', descending: true) 
            .limit(1) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return _buildNoDataView();
          }

          // Get the Single Latest Document
          final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          
          return _buildSalarySlip(data);
        },
      ),
    );
  }

  Widget _buildSalarySlip(Map<String, dynamic> data) {
    final currency = NumberFormat.currency(symbol: "₹", decimalDigits: 0, locale: "en_IN");
    
    // Calculate Totals (if not stored in DB)
    double basic = (data['basic'] ?? 0).toDouble();
    double hra = (data['hra'] ?? 0).toDouble();
    double allowance = (data['allowance'] ?? 0).toDouble();
    double deductions = (data['deductions'] ?? 0).toDouble();
    double netSalary = (basic + hra + allowance) - deductions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[900],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const Text("PAYSLIP FOR", style: TextStyle(color: Colors.white70, letterSpacing: 1.5)),
                const SizedBox(height: 5),
                Text(
                  "${data['month']} ${data['year']}",
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text("NET PAYABLE", style: TextStyle(color: Colors.white70)),
                Text(
                  currency.format(netSalary),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Earnings", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const Divider(),
                _row("Basic Salary", currency.format(basic)),
                _row("HRA", currency.format(hra)),
                _row("Special Allowance", currency.format(allowance)),
                
                const SizedBox(height: 20),
                
                const Text("Deductions", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                const Divider(),
                _row("PF / Tax / Other", "- ${currency.format(deductions)}"),

                const Divider(thickness: 2, height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Net Pay", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(currency.format(netSalary), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          const Text(
            "Note: You can only view your most recent salary slip.\nContact HR for older records.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("No Salary Slip Generated", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}