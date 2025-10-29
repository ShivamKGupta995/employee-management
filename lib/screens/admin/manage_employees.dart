import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({Key? key}) : super(key: key);

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'user',
  );

  final List<String> roleList = ['admin', 'employee'];
  final List<String> departmentList = [
    'HR',
    'Finance',
    'Engineering',
    'Sales',
    'Marketing',
  ];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  String adminEmail = ""; // Store admin email for re-login
  String adminPassword = ""; // Store admin password for re-login
  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      setState(() {
        adminEmail = savedEmail;
        adminPassword = savedPassword;
      });

      // Optional auto-login
      // await _login();
    }
  }

  void _openEmployeeDialog({DocumentSnapshot? employee}) {
    if (employee != null) {
      // Edit mode
      nameController.text = employee['name'];
      emailController.text = employee['email'];
      phoneController.text = employee['phone'];
      departmentController.text = employee['department'];
      roleController.text = employee['role'];
    } else {
      // Add mode
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      departmentController.clear();
      roleController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(employee == null ? 'Add Employee' : 'Edit Employee'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              DropdownButtonFormField<String>(
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
              DropdownButtonFormField<String>(
                items: roleList.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (value) {
                  roleController.text = value ?? '';
                },
                decoration: const InputDecoration(
                  labelText: 'Role (admin/employee)',
                ),
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
            onPressed: () async {
              if (employee == null) {
                try {
                  // Create employee user
                  UserCredential userCredential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: "123456",
                      );

                  String uid = userCredential.user!.uid;

                  await FirebaseAuth.instance.signOut();

                  // Re-login as admin
                  UserCredential adminCredential = await FirebaseAuth.instance
                      .signInWithEmailAndPassword(
                        email: adminEmail,
                        password: adminPassword,
                      );

                  // Force token refresh to re-enable Firestore access
                  await adminCredential.user?.getIdToken(true);

                  // Wait briefly to ensure authentication is restored
                  await Future.delayed(const Duration(seconds: 5));

                  // Now safely write to Firestore
                  await usersRef.doc(uid).set({
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'department': departmentController.text.trim(),
                    'role': roleController.text.trim(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("✅ Employee added successfully"),
                    ),
                  );

                  Navigator.pop(context);
                  // Trigger a rebuild so the StreamBuilder reconnects and shows the new user.
                  // This helps in situations where the auth state changed briefly while creating the user
                  // and the real-time listener needs a quick refresh.
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (mounted) setState(() {});
                } on FirebaseAuthException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Auth Error: ${e.message}")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              } else {
                // Update existing employee
                await usersRef.doc(employee.id).update({
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'department': departmentController.text.trim(),
                  'role': roleController.text.trim(),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Employee added successfully"),
                  ),
                );
                await Future.delayed(const Duration(milliseconds: 300));
                Navigator.pop(context);
                if (mounted) setState(() {});
              }
            },

            child: Text(employee == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEmployee(String docId) async {
    await usersRef.doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEmployeeDialog(),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final errorObj = snapshot.error;
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error loading employees:\n${errorObj.toString()}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        // Rebuild to re-subscribe to the stream (useful after transient auth changes)
                        setState(() {});
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final employees = snapshot.data!.docs;

          if (employees.isEmpty) {
            return const Center(child: Text('No employees found'));
          }

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                elevation: 2,
                child: ListTile(
                  title: Text(employee['name']),
                  subtitle: Text(
                    '${employee['department']} • ${employee['role']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () =>
                            _openEmployeeDialog(employee: employee),
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
