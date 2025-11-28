import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Required for the Secondary App fix

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({Key? key}) : super(key: key);

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection('user');

  final List<String> roleList = ['admin', 'employee'];
  final List<String> departmentList = [
    'HR',
    'Finance',
    'Engineering',
    'Sales',
    'Marketing',
    'General',
  ];

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController isFrozenController  = TextEditingController();
  

  // Opens the dialog to Add or Edit
  void _openEmployeeDialog({DocumentSnapshot? employee}) {
    if (employee != null) {
      // Edit mode: Pre-fill data
      final data = employee.data() as Map<String, dynamic>;
      nameController.text = data['name'] ?? '';
      emailController.text = data['email'] ?? '';
      phoneController.text = data['phone'] ?? '';
      isFrozenController.text = data['isFrozen']?.toString() ?? 'false';
      departmentController.text = data['department'] ?? departmentList.first;
      roleController.text = data['role'] ?? roleList.last;
    } else {
      // Add mode: Clear fields
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      isFrozenController.text = 'false';
      // Set defaults
      departmentController.text = departmentList.first; 
      roleController.text = roleList.last; 
    }

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing while loading
      builder: (_) => AlertDialog(
        title: Text(employee == null ? 'Add Employee' : 'Edit Employee'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              // Only allow editing email if it's a new user
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                enabled: employee == null, 
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: isFrozenController,
                decoration: const InputDecoration(labelText: 'Is Frozen'),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: departmentList.contains(departmentController.text) 
                    ? departmentController.text 
                    : departmentList.first,
                items: departmentList.map((department) {
                  return DropdownMenuItem(
                    value: department,
                    child: Text(department),
                  );
                }).toList(),
                onChanged: (value) {
                  departmentController.text = value ?? '';
                },
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: roleList.contains(roleController.text) 
                    ? roleController.text 
                    : roleList.last,
                items: roleList.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (value) {
                  roleController.text = value ?? '';
                },
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _handleSave(employee),
            child: Text(employee == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  // The Main Logic Function
  Future<void> _handleSave(DocumentSnapshot? employee) async {
    // 1. Show Loading Indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (employee == null) {
        // ============================================
        // LOGIC: ADD NEW EMPLOYEE (Secondary App Method)
        // ============================================
        
        // A. Create a temporary Firebase App instance
        // This allows us to create a user WITHOUT logging out the Admin
        FirebaseApp secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );

        // B. Create the user on the secondary app
        UserCredential userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
            .createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: "123456", // Default Password
        );

        // C. Get the new UID
        String uid = userCredential.user!.uid;

        // D. Clean up the secondary app
        await secondaryApp.delete();

        // E. Save details to Firestore using the MAIN app (Admin's permission)
        await usersRef.doc(uid).set({
          'uid': uid,
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'department': departmentController.text.trim(),
          'role': roleController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'isFrozen': isFrozenController.text.toLowerCase() == 'true' ? true : false, 
        });

        if (!mounted) return;
        Navigator.pop(context); // Close Loading
        Navigator.pop(context); // Close Form
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Employee Added Successfully")),
        );

      } else {
        // ============================================
        // LOGIC: UPDATE EXISTING EMPLOYEE
        // ============================================
        await usersRef.doc(employee.id).update({
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'department': departmentController.text.trim(),
          'role': roleController.text.trim(),
        });

        if (!mounted) return;
        Navigator.pop(context); // Close Loading
        Navigator.pop(context); // Close Form
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Employee Updated")),
        );
      }
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close Loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Auth Error: ${e.message}")),
      );
    } catch (e) {
      Navigator.pop(context); // Close Loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _deleteEmployee(String docId) async {
    // Optional: Add confirmation dialog here
    await usersRef.doc(docId).delete();
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Employee Deleted")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // NOTE: Keep AppBar commented out if this screen is inside AdminDashboard
      // appBar: AppBar(title: const Text("Manage Employees")),
      
      // ✅ FIXED: Button is now visible
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEmployeeDialog(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          // 1. Handle Error
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // 2. Handle Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final employees = snapshot.data!.docs;

          // 3. Handle Empty List
          if (employees.isEmpty) {
            return const Center(child: Text('No employees found'));
          }

          // 4. Show List
          return ListView.builder(
            itemCount: employees.length,
            padding: const EdgeInsets.only(bottom: 80), // Padding for FAB
            itemBuilder: (context, index) {
              final employee = employees[index];
              final data = employee.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      (data['name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  title: Text(data['name'] ?? 'No Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${data['department']} • ${data['role']}'),
                      Text(data['email'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _openEmployeeDialog(employee: employee),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteEmployee(employee.id),
                      ),
                    ],
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