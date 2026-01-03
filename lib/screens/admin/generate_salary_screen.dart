import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:intl/intl.dart'; // ✅ Required for current month name
import 'package:employee_system/config/constants/app_colors.dart';

class GenerateSalaryScreen extends StatefulWidget {
  const GenerateSalaryScreen({super.key});

  @override
  State<GenerateSalaryScreen> createState() => _GenerateSalaryScreenState();
}

class _GenerateSalaryScreenState extends State<GenerateSalaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- SINGLE ENTRY VARIABLES ---
  String? _selectedEmployeeId;
  late String _selectedMonth;
  late String _selectedYear;
  late List<String> _yearList;

  final _presentController = TextEditingController();
  final _absentController = TextEditingController();
  final _lateController = TextEditingController();
  final _otController = TextEditingController();
  final _othersController = TextEditingController();

  bool _isSingleLoading = false;

  // --- BULK UPLOAD VARIABLES ---
  bool _isBulkLoading = false;
  String _bulkStatus = "Upload Excel File (.xlsx)";
  List<String> _bulkLogs = [];
  int _successCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // ✅ AUTO SELECT CURRENT MONTH & YEAR
    DateTime now = DateTime.now();
    _selectedMonth = DateFormat('MMMM').format(now); // e.g., "December"
    _selectedYear = now.year.toString(); // e.g., "2025"
    
    // ✅ YEAR LIST: CURRENT & PREVIOUS
    _yearList = [
      now.year.toString(),
      (now.year - 1).toString(),
    ];
  }

  // ==========================================
  // LOGIC (UNCHANGED BUT UPDATED FOR OT/OTHERS)
  // ==========================================
  Future<void> _uploadSingleSalary() async {
    if (_selectedEmployeeId == null) {
      _showSnackBar("Please select an employee");
      return;
    }
    setState(() => _isSingleLoading = true);
    try {
      await FirebaseFirestore.instance.collection('salary_slips').add({
        'uid': _selectedEmployeeId,
        'month': _selectedMonth,
        'year': _selectedYear,
        'present': int.tryParse(_presentController.text) ?? 0,
        'absent': int.tryParse(_absentController.text) ?? 0,
        'late': int.tryParse(_lateController.text) ?? 0,
        'ot': int.tryParse(_otController.text) ?? 0,
        'others': int.tryParse(_othersController.text) ?? 0,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        _showSnackBar("✅ Statement Published Successfully");
        _clearControllers();
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => _isSingleLoading = false);
    }
  }

  void _clearControllers() {
    _presentController.clear();
    _absentController.clear();
    _lateController.clear();
    _otController.clear();
    _othersController.clear();
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.luxAccentGreen,
    ));
  }

  Future<void> _pickAndUploadBulk() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
      if (result == null) return;

      setState(() {
        _isBulkLoading = true;
        _bulkStatus = "Processing Secure Data...";
        _bulkLogs.clear();
        _successCount = 0;
      });

      var bytes = File(result.files.single.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final table = excel.tables[sheetName];

      if (table == null) throw "Empty dataset";

      int rowIndex = 0;
      for (var row in table.rows) {
        rowIndex++;
        if (rowIndex == 1) continue;
        if (row.isEmpty || row[0] == null) continue;

        try {
          String email = row[0]?.value.toString().trim() ?? "";
          String month = row[1]?.value.toString().trim() ?? _selectedMonth;
          String year = row[2]?.value.toString().trim() ?? _selectedYear;
          int present = int.tryParse(row[3]?.value.toString() ?? "0") ?? 0;
          int absent = int.tryParse(row[4]?.value.toString() ?? "0") ?? 0;
          int late = int.tryParse(row[5]?.value.toString() ?? "0") ?? 0;
          int ot = int.tryParse(row[6]?.value.toString() ?? "0") ?? 0;
          int others = int.tryParse(row[7]?.value.toString() ?? "0") ?? 0;

          final userSnap = await FirebaseFirestore.instance.collection('user').where('email', isEqualTo: email).limit(1).get();
          if (userSnap.docs.isNotEmpty) {
            await FirebaseFirestore.instance.collection('salary_slips').add({
              'uid': userSnap.docs.first.id,
              'month': month, 'year': year,
              'present': present, 'absent': absent, 'late': late,
              'ot': ot, 'others': others,
              'timestamp': FieldValue.serverTimestamp(),
            });
            _successCount++;
          }
        } catch (e) { _bulkLogs.add("Row $rowIndex: $e"); }
      }
      setState(() { _isBulkLoading = false; _bulkStatus = "COMPLETED: $_successCount ENTRIES"; });
    } catch (e) { setState(() { _isBulkLoading = false; _bulkStatus = "Error: $e"; }); }
  }

  // ==========================================
  // UI BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxDarkGreen,
      appBar: AppBar(
        title: const Text("ATTENDANCE GENERATOR", 
          style: TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif')),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.luxGold,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.luxGold,
          labelColor: AppColors.luxGold,
          tabs: const [
            Tab(text: "MANUAL ENTRY", icon: Icon(Icons.person_outline)),
            Tab(text: "BULK PROTOCOL", icon: Icon(Icons.table_rows_outlined)),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.luxBgGradient),
        child: TabBarView(
          controller: _tabController,
          children: [ _buildSingleForm(), _buildBulkForm() ],
        ),
      ),
    );
  }

  Widget _buildSingleForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle("TARGET EMPLOYEE"),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('user').where('role', isEqualTo: 'employee').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator(color: AppColors.luxGold);
              return DropdownButtonFormField<String>(
                isExpanded: true, // ✅ FIX: Prevents RenderFlex overflow
                dropdownColor: AppColors.luxAccentGreen,
                style: const TextStyle(color: Colors.white, overflow: TextOverflow.ellipsis),
                decoration: _luxInput("Select Identity", Icons.badge_outlined),
                value: _selectedEmployeeId,
                items: snapshot.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc['name']))).toList(),
                onChanged: (val) => setState(() => _selectedEmployeeId = val),
              );
            },
          ),
          const SizedBox(height: 20),
          
          _sectionTitle("CYCLE SELECTION"),
          Row(children: [
            Expanded(child: _buildLuxDropdown(_selectedMonth, ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"], (v) => setState(() => _selectedMonth = v!))),
            const SizedBox(width: 15),
            Expanded(child: _buildLuxDropdown(_selectedYear, _yearList, (v) => setState(() => _selectedYear = v!))),
          ]),
          
          const SizedBox(height: 30),
          _sectionTitle("METRIC DETAILS"),
          
          Row(children: [
            Expanded(child: _luxTextField(_presentController, "Present", Icons.check_circle_outline)),
            const SizedBox(width: 15),
            Expanded(child: _luxTextField(_absentController, "Absent", Icons.cancel_outlined)),
          ]),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _luxTextField(_lateController, "Late", Icons.timer_outlined)),
            const SizedBox(width: 15),
            Expanded(child: _luxTextField(_otController, "O.T.", Icons.add_alarm_outlined)),
          ]),
          const SizedBox(height: 15),
          _luxTextField(_othersController, "Others / Adjustment", Icons.edit_note_outlined),

          const SizedBox(height: 40),
          _buildGoldButton("PUBLISH STATEMENT", _isSingleLoading ? null : _uploadSingleSalary, _isSingleLoading),
        ],
      ),
    );
  }

  Widget _buildBulkForm() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          const Icon(Icons.shield_outlined, size: 80, color: AppColors.luxGold),
          const SizedBox(height: 20),
          const Text("EXCEL PROTOCOL REQUIRED", style: TextStyle(color: AppColors.luxGold, letterSpacing: 2, fontFamily: 'serif', fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.luxAccentGreen.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.1))),
            child: Text("Column Order: Email | Month | Year | Present | Absent | Late | OT | Others", 
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.6), fontSize: 10, letterSpacing: 1)),
          ),
          const Spacer(),
          _buildGoldButton("INITIATE FILE UPLOAD", _isBulkLoading ? null : _pickAndUploadBulk, _isBulkLoading),
          const SizedBox(height: 20),
          Text(_bulkStatus.toUpperCase(), style: const TextStyle(color: AppColors.luxGold, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
          if (_bulkLogs.isNotEmpty) _buildErrorLogs(),
        ],
      ),
    );
  }

  // --- HELPERS ---
  Widget _sectionTitle(String t) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(t, style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.7), letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)));

  InputDecoration _luxInput(String label, IconData icon) => InputDecoration(
    labelText: label, labelStyle: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.5), fontSize: 12),
    prefixIcon: Icon(icon, color: AppColors.luxGold, size: 18),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.luxGold.withValues(alpha: 0.2))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.luxGold)),
    filled: true,
    fillColor: AppColors.luxAccentGreen.withValues(alpha: 0.2),
  );

  Widget _luxTextField(TextEditingController ctrl, String label, IconData icon) => TextField(controller: ctrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _luxInput(label, icon));

  Widget _buildLuxDropdown(String val, List<String> items, Function(String?) onChange) => DropdownButtonFormField<String>(
    isExpanded: true, // ✅ FIX: Prevents RenderFlex overflow
    value: val, dropdownColor: AppColors.luxAccentGreen, style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: _luxInput("Cycle", Icons.calendar_today_outlined),
    items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, overflow: TextOverflow.ellipsis))).toList(),
    onChanged: onChange,
  );

  Widget _buildGoldButton(String label, VoidCallback? onTap, bool loading) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, height: 55,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: AppColors.luxGoldGradient),
      child: Center(child: loading ? const CircularProgressIndicator(color: AppColors.luxDarkGreen) : Text(label, style: const TextStyle(color: AppColors.luxDarkGreen, fontWeight: FontWeight.bold, letterSpacing: 2))),
    ),
  );

  Widget _buildErrorLogs() => Expanded(child: Container(margin: const EdgeInsets.only(top: 20), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)), child: ListView.builder(itemCount: _bulkLogs.length, itemBuilder: (context, index) => ListTile(dense: true, leading: const Icon(Icons.error_outline, color: Colors.red, size: 16), title: Text(_bulkLogs[index], style: const TextStyle(color: Colors.red, fontSize: 11))))));
}