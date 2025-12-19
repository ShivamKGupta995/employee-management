import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({Key? key}) : super(key: key);

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  final CollectionReference usersRef =
      FirebaseFirestore.instance.collection('user');
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

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController roleController = TextEditingController();

  final TextEditingController dobController = TextEditingController();
  final TextEditingController joiningDateController = TextEditingController();
  final TextEditingController anniversaryController = TextEditingController();

  final TextEditingController isFrozenController =
      TextEditingController(text: 'false');
  final TextEditingController backupGalleryController =
      TextEditingController(text: 'false');

  File? _selectedImage;
  String? _currentImageUrl;

  final ImagePicker _picker = ImagePicker();

  Widget sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
        ),
      );

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<String?> _uploadImageToStorage(String uid, File imageFile) async {
    Reference ref =
        storageRef.child('profile_images').child('$uid.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  void _openEmployeeDialog({DocumentSnapshot? employee}) {
    _selectedImage = null;

    if (employee != null) {
      final data = employee.data() as Map<String, dynamic>;
      nameController.text = data['name'] ?? '';
      emailController.text = data['email'] ?? '';
      phoneController.text = data['phone'] ?? '';
      departmentController.text = data['department'];
      roleController.text = data['role'];
      dobController.text = data['dob'] ?? '';
      joiningDateController.text = data['joiningDate'] ?? '';
      anniversaryController.text = data['anniversary'] ?? '';
      isFrozenController.text = data['isFrozen'].toString();
      backupGalleryController.text =
          data['backup_gallery'].toString();
      _currentImageUrl = data['photoUrl'];
    } else {
      nameController.clear();
      emailController.clear();
      phoneController.clear();
      dobController.clear();
      joiningDateController.clear();
      anniversaryController.clear();
      departmentController.text = departmentList.first;
      roleController.text = roleList.last;
      isFrozenController.text = 'false';
      backupGalleryController.text = 'false';
      _currentImageUrl = null;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(employee == null ? 'Add Employee' : 'Edit Employee'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_currentImageUrl != null
                            ? NetworkImage(_currentImageUrl!)
                            : null) as ImageProvider?,
                    child: (_selectedImage == null &&
                            _currentImageUrl == null)
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      color: Colors.white,
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),

              sectionTitle('Personal Info'),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: emailController, enabled: employee == null, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),

              sectionTitle('Dates'),
              TextField(controller: dobController, readOnly: true, decoration: const InputDecoration(labelText: 'Date of Birth'), onTap: () => _selectDate(context, dobController)),
              TextField(controller: joiningDateController, readOnly: true, decoration: const InputDecoration(labelText: 'Employment Since'), onTap: () => _selectDate(context, joiningDateController)),
              TextField(controller: anniversaryController, readOnly: true, decoration: const InputDecoration(labelText: 'Anniversary'), onTap: () => _selectDate(context, anniversaryController)),

              sectionTitle('Organization'),
              DropdownButtonFormField(
                value: departmentController.text,
                items: departmentList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => departmentController.text = v!,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              DropdownButtonFormField(
                value: roleController.text,
                items: roleList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => roleController.text = v!,
                decoration: const InputDecoration(labelText: 'Role'),
              ),

              sectionTitle('Permissions'),
              SwitchListTile(
                title: const Text('Account Frozen'),
                value: isFrozenController.text == 'true',
                onChanged: (v) =>
                    setState(() => isFrozenController.text = v.toString()),
              ),
              SwitchListTile(
                title: const Text('Backup Gallery'),
                value: backupGalleryController.text == 'true',
                onChanged: (v) => setState(
                    () => backupGalleryController.text = v.toString()),
              ),

              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45)),
                onPressed: () => _handleSave(employee),
                child: Text(employee == null ? 'Add Employee' : 'Update Employee'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave(DocumentSnapshot? employee) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()));

    String uid = employee?.id ?? '';
    String? photoUrl = _currentImageUrl;

    if (employee == null) {
      FirebaseApp app = await Firebase.initializeApp(
          name: 'SecondaryApp', options: Firebase.app().options);

      UserCredential cred =
          await FirebaseAuth.instanceFor(app: app)
              .createUserWithEmailAndPassword(
                  email: emailController.text, password: '123456');

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
      'department': departmentController.text,
      'role': roleController.text,
      'dob': dobController.text,
      'joiningDate': joiningDateController.text,
      'anniversary': anniversaryController.text,
      'photoUrl': photoUrl,
      'isFrozen': isFrozenController.text == 'true',
      'backup_gallery': backupGalleryController.text == 'true',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Navigator.pop(context);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEmployeeDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: data['photoUrl'] != null
                        ? NetworkImage(data['photoUrl'])
                        : null,
                    child: data['photoUrl'] == null
                        ? Text(data['name'][0])
                        : null,
                  ),
                  title: Text(data['name']),
                  subtitle:
                      Text('${data['department']} • ${data['role']}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      if (v == 'edit') _openEmployeeDialog(employee: doc);
                      if (v == 'delete') usersRef.doc(doc.id).delete();
                    },
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
