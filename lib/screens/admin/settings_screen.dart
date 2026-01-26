import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:employee_system/config/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _deptController = TextEditingController();
  final CollectionReference _deptRef = FirebaseFirestore.instance.collection('departments');

  void _addDepartment() async {
    if (_deptController.text.trim().isEmpty) return;
    
    await _deptRef.add({
      'name': _deptController.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    _deptController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxDarkGreen,
      appBar: AppBar(
        title: const Text("SYSTEM SETTINGS", 
          style: TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif')),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.luxGold,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("MANAGE DEPARTMENTS", 
              style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.7), letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            // Input Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _deptController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter Department Name",
                      hintStyle: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: AppColors.luxAccentGreen.withValues(alpha: 0.2),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.luxGold.withValues(alpha: 0.2))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.luxGold)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _addDepartment,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(gradient: AppColors.luxGoldGradient, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add, color: AppColors.luxDarkGreen),
                  ),
                )
              ],
            ),
            
            const SizedBox(height: 30),
            
            // List of Departments
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _deptRef.orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.luxGold));
                  
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.luxAccentGreen.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.luxGold.withValues(alpha: 0.1))
                        ),
                        child: ListTile(
                          title: Text(doc['name'], style: const TextStyle(color: Colors.white)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                            onPressed: () => doc.reference.delete(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}