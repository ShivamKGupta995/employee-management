import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_core/firebase_core.dart'; // Uncomment if Firebase initialization is needed
// Usage later: excel_pkg.Border

class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({Key? key}) : super(key: key);

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  bool _isLoading = false;
  String _statusMessage = "Ready to upload";
  int _successCount = 0;
  List<String> _errors = [];

  // Function to Pick and Process File
  Future<void> _pickAndUploadFile() async {
    try {
      // 1. Pick File
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
      );

      if (result == null) return; // User canceled

      setState(() {
        _isLoading = true;
        _statusMessage = "Reading file...";
        _errors.clear();
        _successCount = 0;
      });

      // 2. Read File Bytes
      // On Mobile, we use path. On Web, we use bytes.
      var bytes = File(result.files.single.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      // 3. Get the first sheet
      final sheetName = excel.tables.keys.first;
      final table = excel.tables[sheetName];

      if (table == null) throw "No data found in Excel";

      int rowIndex = 0;

      // 4. Loop through rows
      for (var row in table.rows) {
        rowIndex++;
        
        // Skip Header Row (Row 1)
        if (rowIndex == 1) continue;

        // Skip empty rows
        if (row.isEmpty || row[0] == null) continue;

        try {
          // Extract Data from Columns (0=A, 1=B, etc.)
          String email = row[0]?.value.toString().trim() ?? "";
          String month = row[1]?.value.toString().trim() ?? "November";
          String year = row[2]?.value.toString().trim() ?? "2025";
          int present = int.tryParse(row[3]?.value.toString() ?? "0") ?? 0;
          int absent = int.tryParse(row[4]?.value.toString() ?? "0") ?? 0;
          int late = int.tryParse(row[5]?.value.toString() ?? "0") ?? 0;
          double overtime = double.tryParse(row[6]?.value.toString() ?? "0") ?? 0.0;
          double rate = double.tryParse(row[7]?.value.toString() ?? "0") ?? 0.0;

          if (email.isEmpty) continue;

          // 5. Find UID based on Email
          await _updateEmployeeData(email, month, year, present, absent, late, overtime, rate);
          
        } catch (e) {
          _errors.add("Row $rowIndex Error: $e");
        }
      }

      setState(() {
        _isLoading = false;
        _statusMessage = "Upload Complete!\nUpdated: $_successCount records.";
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Error: $e";
      });
    }
  }

  // Helper: Find User by Email & Update Stats
  Future<void> _updateEmployeeData(String email, String month, String year, int present, int absent, int late, double ot, double rate) async {
    
    // A. Lookup User
    final userSnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      _errors.add("Email not found: $email");
      return;
    }

    String uid = userSnapshot.docs.first.id;
    String docId = "${uid}_${month}_$year";

    // B. Update 'monthly_stats'
    await FirebaseFirestore.instance.collection('monthly_stats').doc(docId).set({
      'uid': uid,
      'month': month,
      'year': year,
      'present': present,
      'absent': absent,
      'late': late,
      'overtime': ot,
      'rate': rate,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _successCount++;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bulk Attendance Upload")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.table_view, size: 60, color: Colors.green),
            ),
            const SizedBox(height: 20),
            
            const Text(
              "Upload Excel (.xlsx)",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Columns: Email | Month | Year | Present | Absent | Late | Overtime | Rate",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // Upload Button
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _pickAndUploadFile,
                icon: const Icon(Icons.upload_file),
                label: const Text("Select Excel File"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),

            const SizedBox(height: 30),

            // Status Report
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (_errors.isNotEmpty)
                    Container(
                      height: 150,
                      child: ListView.builder(
                        itemCount: _errors.length,
                        itemBuilder: (ctx, i) => Text(
                          "⚠️ ${_errors[i]}",
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Excel File Format:A (Email)	B (Month)	C (Year)	D (Present)	E (Absent)	F (Late)	G (Overtime)	H (Rate)
// john@abc.com	November	2025	22	1	2	5.5	95
// jane@abc.com	November	2025	25	0	0	0	100