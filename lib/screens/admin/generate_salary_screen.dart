import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
// FIX 1: Hide Border to prevent conflict with Material Border
import 'package:excel/excel.dart' hide Border;

class GenerateSalaryScreen extends StatefulWidget {
  // FIX 2: Use super parameter
  const GenerateSalaryScreen({super.key});

  @override
  State<GenerateSalaryScreen> createState() => _GenerateSalaryScreenState();
}

class _GenerateSalaryScreenState extends State<GenerateSalaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- SINGLE ENTRY VARIABLES ---
  String? _selectedEmployeeId;
  String _selectedMonth = "November";
  String _selectedYear = "2025";
  
  // Attendance Fields ONLY
  final _presentController = TextEditingController();
  final _absentController = TextEditingController();
  final _lateController = TextEditingController();

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
  }

  // ==========================================
  // LOGIC 1: SINGLE UPLOAD
  // ==========================================
  Future<void> _uploadSingleSalary() async {
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an employee")));
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
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Salary/Attendance Slip Published")));
        _clearControllers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSingleLoading = false);
    }
  }

  void _clearControllers() {
    _presentController.clear();
    _absentController.clear();
    _lateController.clear();
  }

  // ==========================================
  // LOGIC 2: BULK UPLOAD (EXCEL)
  // ==========================================
  Future<void> _pickAndUploadBulk() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        allowMultiple: false,
      );

      if (result == null) return;

      setState(() {
        _isBulkLoading = true;
        _bulkStatus = "Processing File...";
        _bulkLogs.clear();
        _successCount = 0;
      });

      var bytes = File(result.files.single.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.first;
      final table = excel.tables[sheetName];

      if (table == null) throw "No data found";

      int rowIndex = 0;

      for (var row in table.rows) {
        rowIndex++;
        if (rowIndex == 1) continue; // Skip Header
        if (row.isEmpty || row[0] == null) continue;

        try {
          String email = row[0]?.value.toString().trim() ?? "";
          String month = row[1]?.value.toString().trim() ?? "November";
          String year = row[2]?.value.toString().trim() ?? "2025";
          
          int present = int.tryParse(row[3]?.value.toString() ?? "0") ?? 0;
          int absent = int.tryParse(row[4]?.value.toString() ?? "0") ?? 0;
          int late = int.tryParse(row[5]?.value.toString() ?? "0") ?? 0;

          final userSnap = await FirebaseFirestore.instance.collection('user').where('email', isEqualTo: email).limit(1).get();
          
          if (userSnap.docs.isNotEmpty) {
            String uid = userSnap.docs.first.id;
            
            await FirebaseFirestore.instance.collection('salary_slips').add({
              'uid': uid,
              'month': month,
              'year': year,
              'present': present,
              'absent': absent,
              'late': late,
              'timestamp': FieldValue.serverTimestamp(),
            });
            _successCount++;
          } else {
            _bulkLogs.add("Row $rowIndex: Email not found ($email)");
          }
        } catch (e) {
          _bulkLogs.add("Row $rowIndex Error: $e");
        }
      }

      // FIX 3: Check mounted before using context/setState after async
      if (!mounted) return;

      setState(() {
        _isBulkLoading = false;
        _bulkStatus = "✅ Processed! Success: $_successCount";
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBulkLoading = false;
        _bulkStatus = "Error: $e";
      });
    }
  }

  // ==========================================
  // UI BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generate Slip (No Amount)"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Single Entry", icon: Icon(Icons.person)),
            Tab(text: "Bulk Upload", icon: Icon(Icons.table_view)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSingleForm(),
          _buildBulkForm(),
        ],
      ),
    );
  }

  Widget _buildSingleForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('user').where('role', isEqualTo: 'employee').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Select Employee", border: OutlineInputBorder()),
                value: _selectedEmployeeId,
                items: snapshot.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc['name']))).toList(),
                onChanged: (val) => setState(() => _selectedEmployeeId = val),
              );
            },
          ),
          const SizedBox(height: 15),
          
          Row(children: [
            Expanded(child: DropdownButtonFormField(value: _selectedMonth, items: ["October", "November", "December"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) => setState(() => _selectedMonth = v.toString()))),
            const SizedBox(width: 10),
            Expanded(child: DropdownButtonFormField(value: _selectedYear, items: ["2024", "2025"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) => setState(() => _selectedYear = v.toString()))),
          ]),
          
          const SizedBox(height: 20),
          const Text("📅 Attendance Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),

          TextField(controller: _presentController, decoration: const InputDecoration(labelText: "Present Days", border: OutlineInputBorder(), prefixIcon: Icon(Icons.check_circle_outline)), keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          TextField(controller: _absentController, decoration: const InputDecoration(labelText: "Absent Days", border: OutlineInputBorder(), prefixIcon: Icon(Icons.cancel_outlined)), keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          TextField(controller: _lateController, decoration: const InputDecoration(labelText: "Late Days", border: OutlineInputBorder(), prefixIcon: Icon(Icons.access_time)), keyboardType: TextInputType.number),

          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: _isSingleLoading ? null : _uploadSingleSalary,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[900],
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isSingleLoading 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text("PUBLISH SLIP"),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.file_upload_outlined, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          const Text(
            "Excel Format Required:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey[100],
            child: const Text(
              "Email | Month | Year | Present | Absent | Late",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87, fontSize: 12),
            ),
          ),
          const SizedBox(height: 30),
          
          if (_isBulkLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton.icon(
              onPressed: _pickAndUploadBulk,
              icon: const Icon(Icons.folder_open),
              label: const Text("Select Excel File"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            
          const SizedBox(height: 20),
          Text(_bulkStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
          
          const SizedBox(height: 10),
          if (_bulkLogs.isNotEmpty)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.red.shade50,
                child: ListView.builder(
                  itemCount: _bulkLogs.length,
                  itemBuilder: (context, index) => Text("⚠️ ${_bulkLogs[index]}", style: const TextStyle(color: Colors.red)),
                ),
              ),
            )
        ],
      ),
    );
  }
}