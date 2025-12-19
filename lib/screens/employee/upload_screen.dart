import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Add image_picker to pubspec
import 'package:file_picker/file_picker.dart';   // Add file_picker to pubspec
import 'package:firebase_storage/firebase_storage.dart'; // Add firebase_storage
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // 1. Generic Upload Logic
  Future<void> _uploadFile(File file, String fileType, String fileName) async {
    setState(() => _isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String uniqueName = "${DateTime.now().millisecondsSinceEpoch}_$fileName";
      
      // A. Upload to Storage Bucket
      Reference ref = FirebaseStorage.instance.ref().child('uploads/${user.uid}/$uniqueName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // B. Save Metadata to Firestore
      await FirebaseFirestore.instance.collection('uploads').add({
        'uid': user.uid,
        'url': downloadUrl,
        'type': fileType, // 'image' or 'file'
        'fileName': fileName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Upload Successful!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }


  Future<bool> _isGalleryBackupEnabled() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance
      .collection('user')
      .doc(user.uid)
      .get();

  return doc.data()?['backup_gallery'] == true;
}


  // 2. Pick Image
  Future<void> _pickImage(ImageSource source) async {
  final XFile? image = await _picker.pickImage(
    source: source,
    imageQuality: 50,
  );

  if (image == null) return;

  // Camera images → always upload manually
  if (source == ImageSource.camera) {
    await _uploadFile(File(image.path), 'image', image.name);
    return;
  }

  // Gallery images → check backup flag
  bool autoBackup = await _isGalleryBackupEnabled();

  if (autoBackup) {
    debugPrint("📸 Auto gallery backup enabled");
    await _uploadFile(File(image.path), 'image', image.name);
  } else {
    debugPrint("📸 Auto gallery backup disabled");
    await _uploadFile(File(image.path), 'image', image.name);
  }
}

  // 3. Pick Document
  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      File file = File(result.files.single.path!);
      await _uploadFile(file, 'file', result.files.single.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Evidence")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) const Center(child: LinearProgressIndicator()),
            const SizedBox(height: 20),
            
            _buildBigButton(
              icon: Icons.camera_alt, 
              label: "Take Photo", 
              color: Colors.blue, 
              onTap: () => _pickImage(ImageSource.camera)
            ),
            const SizedBox(height: 15),
            
            _buildBigButton(
              icon: Icons.photo_library, 
              label: "Gallery", 
              color: Colors.orange, 
              onTap: () => _pickImage(ImageSource.gallery)
            ),
            const SizedBox(height: 15),

            _buildBigButton(
              icon: Icons.attach_file, 
              label: "Upload Document", 
              color: Colors.green, 
              onTap: _pickDocument
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onTap,
      icon: Icon(icon, size: 28),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }
}