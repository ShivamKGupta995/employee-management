import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:employee_system/config/constants/app_colors.dart'; // Adjust path

class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({Key? key}) : super(key: key);

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  // Logic Variables (Original)
  bool _isLoading = false;
  String _statusMessage = "SYSTEM READY FOR UPLOAD";
  int _successCount = 0;
  List<String> _errors = [];

  // ==========================================
  // LOGIC METHODS (ORIGINAL PRESERVED)
  // ==========================================

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
      );

      if (result == null) return;

      setState(() {
        _isLoading = true;
        _statusMessage = "DECRYPTING & READING DATA...";
        _errors.clear();
        _successCount = 0;
      });

      var bytes = File(result.files.single.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final table = excel.tables[sheetName];

      if (table == null) throw "Data structure not found";

      int rowIndex = 0;
      for (var row in table.rows) {
        rowIndex++;
        if (rowIndex == 1 || row.isEmpty || row[0] == null) continue;

        try {
          String email = row[0]?.value.toString().trim() ?? "";
          String month = row[1]?.value.toString().trim() ?? "December";
          String year = row[2]?.value.toString().trim() ?? "2025";
          int present = int.tryParse(row[3]?.value.toString() ?? "0") ?? 0;
          int absent = int.tryParse(row[4]?.value.toString() ?? "0") ?? 0;
          int late = int.tryParse(row[5]?.value.toString() ?? "0") ?? 0;
          double overtime = double.tryParse(row[6]?.value.toString() ?? "0") ?? 0.0;
          double rate = double.tryParse(row[7]?.value.toString() ?? "0") ?? 0.0;

          if (email.isNotEmpty) {
            await _updateEmployeeData(email, month, year, present, absent, late, overtime, rate);
          }
        } catch (e) {
          _errors.add("Row $rowIndex: Internal Error");
        }
      }

      setState(() {
        _isLoading = false;
        _statusMessage = "PROCESSING COMPLETE: $_successCount RECORDS UPDATED";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "SYSTEM ERROR: $e";
      });
    }
  }

  Future<void> _updateEmployeeData(String email, String month, String year, int present, int absent, int late, double ot, double rate) async {
    final userSnapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) {
      _errors.add("Not Found: $email");
      return;
    }

    String uid = userSnapshot.docs.first.id;
    String docId = "${uid}_${month}_$year";

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

  // ==========================================
  // UI BUILD (REDESIGNED FOR LUXURY THEME)
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxDarkGreen,
      appBar: AppBar(
        title: const Text("BATCH DATA PROTOCOL", 
          style: TextStyle(letterSpacing: 3, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'serif')),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.luxGold,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.luxBgGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),
                
                // Branded Central Icon
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.3), width: 1.5),
                    color: AppColors.luxGold.withValues(alpha: 0.05),
                  ),
                  child: const Icon(Icons.cloud_upload_outlined, size: 50, color: AppColors.luxGold),
                ),
                
                const SizedBox(height: 30),
                
                const Text(
                  "Data Synchronization",
                  style: TextStyle(color: AppColors.luxGold, fontSize: 24, fontFamily: 'serif', fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 10),
                Text(
                  "REQUIREMENTS: Email | Month | Year | Present | Absent | Late | OT | Rate",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                ),
                
                const SizedBox(height: 50),

                // Upload Action
                if (_isLoading)
                  const CircularProgressIndicator(color: AppColors.luxGold)
                else
                  GestureDetector(
                    onTap: _pickAndUploadFile,
                    child: Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: AppColors.luxGoldGradient,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
                        ]
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.file_present_outlined, color: AppColors.luxDarkGreen, size: 20),
                            SizedBox(width: 12),
                            Text("INITIALIZE EXCEL UPLOAD", 
                              style: TextStyle(color: AppColors.luxDarkGreen, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),

                // Status & Logs Console
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.luxAccentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(_statusMessage, 
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      
                      if (_errors.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Divider(color: AppColors.luxGold, thickness: 0.1),
                        ),
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            itemCount: _errors.length,
                            itemBuilder: (ctx, i) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(_errors[i], 
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Footer
                Text(
                  "SECURE ADMINISTRATIVE PORTAL",
                  style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.3), fontSize: 9, letterSpacing: 3, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}