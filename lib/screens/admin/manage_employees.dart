import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:employee_system/config/constants/app_colors.dart'; // Ensure path is correct

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({Key? key}) : super(key: key);

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  final CollectionReference usersRef = FirebaseFirestore.instance.collection(
    'user',
  );
  final Reference storageRef = FirebaseStorage.instance.ref();

  final List<String> roleList = ['admin', 'employee'];
  final List<String> departmentList = [
    'HR',
    'Finance',
    'Engineering',
    'Sales',
    'Marketing',
    'General',
  ];
  List<String> dynamicDepartments = ['General']; // Default value

  @override
  void initState() {
    super.initState();
    _listenToDepartments();
  }

  void _listenToDepartments() {
    FirebaseFirestore.instance.collection('departments').snapshots().listen((
      snapshot,
    ) {
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          dynamicDepartments = snapshot.docs
              .map((doc) => doc['name'] as String)
              .toList();
          // Ensure 'General' is always an option if you want
          if (!dynamicDepartments.contains('General')) {
            dynamicDepartments.add('General');
          }
        });
      }
    });
  }

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController joiningDateController = TextEditingController();
  final TextEditingController anniversaryController = TextEditingController();

  // Local state for the dialog
  String _selectedDept = 'General';
  String _selectedRole = 'employee';
  bool _isFrozen = false;
  bool _backupGallery = false;
  File? _selectedImage;
  String? _currentImageUrl;

  final ImagePicker _picker = ImagePicker();

  // ==========================================
  // UI HELPERS
  // ==========================================

  Widget sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.luxGold.withValues(alpha: 0.7),
        letterSpacing: 2,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  InputDecoration _luxInput(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.6)),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.luxGold.withValues(alpha: 0.3)),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.luxGold, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    filled: true,
    fillColor: AppColors.luxAccentGreen.withValues(alpha: 0.2),
  );

  // ==========================================
  // LOGIC (ORIGINAL LOGIC PRESERVED)
  // ==========================================

  Future<void> _pickImage(StateSetter setState) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.luxGold,
            onPrimary: AppColors.luxDarkGreen,
            surface: AppColors.luxAccentGreen,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<String?> _uploadImageToStorage(String uid, File imageFile) async {
    Reference ref = storageRef.child('profile_images').child('$uid.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // ==========================================
  // DIALOG UI
  // ==========================================

  void _openEmployeeDialog({DocumentSnapshot? employee}) {
    _selectedImage = null;
    if (employee != null) {
      final data = employee.data() as Map<String, dynamic>;
      nameController.text = data['name'] ?? '';
      emailController.text = data['email'] ?? '';
      phoneController.text = data['phone'] ?? '';
      _selectedDept = data['department'] ?? 'General';
      _selectedRole = data['role'] ?? 'employee';
      dobController.text = data['dob'] ?? '';
      joiningDateController.text = data['joiningDate'] ?? '';
      anniversaryController.text = data['anniversary'] ?? '';
      _isFrozen = data['isFrozen'] ?? false;
      _backupGallery = data['backup_gallery'] ?? false;
      _currentImageUrl = data['photoUrl'];
    } else {
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      dobController.clear();
      joiningDateController.clear();
      anniversaryController.clear();
      _selectedDept = 'General';
      _selectedRole = 'employee';
      _isFrozen = false;
      _backupGallery = false;
      _currentImageUrl = null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.luxDarkGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.luxGold.withValues(alpha: 0.3)),
          ),
          title: Text(
            employee == null ? 'NEW ONBOARDING' : 'EDIT CREDENTIALS',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.luxGold,
              letterSpacing: 2,
              fontSize: 16,
              fontFamily: 'serif',
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Avatar Picker
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.luxGold,
                            width: 1,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.luxAccentGreen,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_currentImageUrl != null
                                        ? NetworkImage(_currentImageUrl!)
                                        : null)
                                    as ImageProvider?,
                          child:
                              (_selectedImage == null &&
                                  _currentImageUrl == null)
                              ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: AppColors.luxGold,
                                )
                              : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _pickImage(setDialogState),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.luxGold,
                          child: Icon(
                            Icons.edit,
                            size: 14,
                            color: AppColors.luxDarkGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                sectionTitle('Identity'),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _luxInput('Full Name'),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: emailController,
                  enabled: employee == null,
                  style: const TextStyle(color: Colors.white),
                  decoration: _luxInput('Email Address'),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _luxInput('Contact Number'),
                ),

                sectionTitle('Schedules'),
                TextField(
                  controller: dobController,
                  readOnly: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _luxInput('Birth Date'),
                  onTap: () => _selectDate(context, dobController),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: joiningDateController,
                  readOnly: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _luxInput('Joining Date'),
                  onTap: () => _selectDate(context, joiningDateController),
                ),

                sectionTitle('Compliance'),
                DropdownButtonFormField<String>(
                  value: dynamicDepartments.contains(_selectedDept)
                      ? _selectedDept
                      : dynamicDepartments.first, // Safety check
                  dropdownColor: AppColors.luxAccentGreen,
                  style: const TextStyle(color: Colors.white),
                  decoration: _luxInput('Department'),
                  items: dynamicDepartments
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => _selectedDept = v!),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  dropdownColor: AppColors.luxAccentGreen,
                  style: const TextStyle(color: Colors.white),
                  decoration: _luxInput('System Role'),
                  items: roleList
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => _selectedRole = v!),
                ),

                sectionTitle('Permissions'),
                SwitchListTile(
                  title: const Text(
                    'Account Frozen',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  value: _isFrozen,
                  activeColor: AppColors.luxGold,
                  onChanged: (v) => setDialogState(() => _isFrozen = v),
                ),
                SwitchListTile(
                  title: const Text(
                    'Backup Services',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  value: _backupGallery,
                  activeColor: AppColors.luxGold,
                  onChanged: (v) => setDialogState(() => _backupGallery = v),
                ),

                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () => _handleSave(employee),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: AppColors.luxGoldGradient,
                    ),
                    child: Center(
                      child: Text(
                        employee == null ? 'ONBOARD EMPLOYEE' : 'UPDATE RECORD',
                        style: const TextStyle(
                          color: AppColors.luxDarkGreen,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave(DocumentSnapshot? employee) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.luxGold),
      ),
    );

    try {
      String uid = employee?.id ?? '';
      String? photoUrl = _currentImageUrl;

      if (employee == null) {
        FirebaseApp app = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
        UserCredential cred = await FirebaseAuth.instanceFor(app: app)
            .createUserWithEmailAndPassword(
              email: emailController.text,
              password: '123456',
            );
        uid = cred.user!.uid;
        await app.delete();
      }

      if (_selectedImage != null) {
        photoUrl = await _uploadImageToStorage(uid, _selectedImage!);
      }

      await usersRef.doc(uid).set({
        'uid': uid,
        'name': nameController.text,
        'email': emailController.text,
        'phone': phoneController.text,
        'department': _selectedDept,
        'role': _selectedRole,
        'dob': dobController.text,
        'joiningDate': joiningDateController.text,
        'anniversary': anniversaryController.text,
        'photoUrl': photoUrl,
        'isFrozen': _isFrozen,
        'backup_gallery': _backupGallery,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Close dialog
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // ==========================================
  // LIST UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxDarkGreen,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEmployeeDialog(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.luxGoldGradient,
          ),
          child: const Icon(Icons.add, color: AppColors.luxDarkGreen),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(color: AppColors.luxGold),
            );

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              bool frozen = data['isFrozen'] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: AppColors.luxAccentGreen.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.luxGold.withValues(
                      alpha: frozen ? 0.1 : 0.2,
                    ),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.luxGold.withValues(alpha: 0.5),
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: AppColors.luxAccentGreen,
                      backgroundImage: data['photoUrl'] != null
                          ? NetworkImage(data['photoUrl'])
                          : null,
                      child: data['photoUrl'] == null
                          ? Text(
                              data['name'][0],
                              style: const TextStyle(color: AppColors.luxGold),
                            )
                          : null,
                    ),
                  ),
                  title: Text(
                    data['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                    ),
                  ),
                  subtitle: Text(
                    '${data['department']} • ${data['role'].toString().toUpperCase()}',
                    style: TextStyle(
                      color: AppColors.luxGold.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  trailing: PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: AppColors.luxGold),
                    color: AppColors.luxAccentGreen,
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Edit Record',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete User',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') _openEmployeeDialog(employee: doc);
                      if (v == 'delete') usersRef.doc(doc.id).delete();
                    },
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
