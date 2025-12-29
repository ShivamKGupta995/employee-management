import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:employee_system/config/constants/app_colors.dart'; // Adjust path if needed

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // ==========================================
  // LOGIC (KEEPING YOUR ORIGINAL CODE)
  // ==========================================
  Future<void> _uploadFile(File file, String fileType, String fileName) async {
    setState(() => _isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      String uniqueName = "${DateTime.now().millisecondsSinceEpoch}_$fileName";
      Reference ref = FirebaseStorage.instance.ref().child('uploads/${user.uid}/$uniqueName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('uploads').add({
        'uid': user.uid,
        'url': downloadUrl,
        'type': fileType,
        'fileName': fileName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Documentation Submitted Successfully"), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _isGalleryBackupEnabled() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance.collection('user').doc(user.uid).get();
    return doc.data()?['backup_gallery'] == true;
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 50);
    if (image == null) return;
    if (source == ImageSource.camera) {
      await _uploadFile(File(image.path), 'image', image.name);
      return;
    }
    bool autoBackup = await _isGalleryBackupEnabled();
    await _uploadFile(File(image.path), 'image', image.name);
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null) {
      File file = File(result.files.single.path!);
      await _uploadFile(file, 'file', result.files.single.name);
    }
  }

  // ==========================================
  // UI BUILD (REDESIGNED FOR LUXURY THEME)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.luxDarkGreen,
      appBar: AppBar(
        title: const Text("MEDICAL CLEARANCE",
            style: TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif')),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.luxGold,
        centerTitle: true,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF1D322C), AppColors.luxDarkGreen],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Professional Header Icon
                const Icon(Icons.health_and_safety_outlined, size: 80, color: AppColors.luxGold),
                const SizedBox(height: 20),
                
                const Text(
                  "Documentation Required",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.luxGold, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'serif'),
                ),
                const SizedBox(height: 10),
                Text(
                  "Please submit your medical NOC, Doctor reports, or fitness certifications for absence verification.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.luxGold.withValues(alpha: 0.6), height: 1.5),
                ),
                
                const Spacer(),

                if (_isLoading) 
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Center(child: CircularProgressIndicator(color: AppColors.luxGold)),
                  ),

                // Button 1: Gradient Action
                _buildLuxuryButton(
                  icon: Icons.camera_enhance_outlined,
                  label: "CAPTURE REPORT",
                  isPrimary: true,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(height: 20),

                // Button 2: Outlined Action
                _buildLuxuryButton(
                  icon: Icons.photo_library_outlined,
                  label: "SELECT FROM GALLERY",
                  isPrimary: false,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                const SizedBox(height: 20),

                // Button 3: Outlined Action
                _buildLuxuryButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: "UPLOAD PDF / DOCUMENT",
                  isPrimary: false,
                  onTap: _pickDocument,
                ),
                
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLuxuryButton({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: isPrimary ? AppColors.luxGoldGradient : null,
          color: isPrimary ? null : AppColors.luxAccentGreen.withValues(alpha: 0.3),
          border: isPrimary ? null : Border.all(color: AppColors.luxGold.withValues(alpha: 0.4), width: 1.2),
          boxShadow: isPrimary ? [
            BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isPrimary ? AppColors.luxDarkGreen : AppColors.luxGold, size: 24),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? AppColors.luxDarkGreen : AppColors.luxGold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}