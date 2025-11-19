Here is the complete documentation for the **File & Photo Upload System**.

This feature allows employees to **upload evidence** (Photos of the site, Accident reports, Medical documents) to the cloud. The **Admin** can then view these files instantly for that specific employee during an emergency or routine check.

Save this file as **`File_Photo_Upload_System.md`**.

***

# File & Photo Upload System Documentation

**Overview:**
1.  **Employee App:** Can pick images from the Camera/Gallery or Files (PDF/Docs) and upload them to Firebase Storage.
2.  **Admin App:** Views a gallery of these uploads for the specific employee being monitored.
3.  **Storage:** Uses **Firebase Storage** for files and **Firestore** for metadata.

---

## 1. Configuration & Permissions

### Dependencies (`pubspec.yaml`)
Add these to handle camera, file picking, and storage.
```yaml
dependencies:
  image_picker: ^1.0.7  # For Camera/Gallery
  file_picker: ^6.1.1   # For PDFs/Docs
  firebase_storage: ^11.6.0 # To store the actual files
```

### Android Manifest (`android/app/src/main/AndroidManifest.xml`)
You need permissions to access the camera and storage.

```xml
<manifest ...>
    <!-- Camera & Storage -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
    <!-- Android 13+ Media -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
    
    <application ...>
       <!-- File Provider (Required for Camera on Android 11+) -->
       <!-- Note: Usually standard flutter packages handle this, 
            but ensure your compileSdkVersion is 33 or higher in build.gradle -->
    </application>
</manifest>
```

---

## 2. Database & Storage Structure

### A. Firebase Storage (The Bucket)
This is where the actual bytes of the image/file live.
*   **Path Structure:** `uploads/{employee_uid}/{timestamp}_{filename}`

### B. Firestore Database (The Metadata)
This allows us to list/filter files easily without downloading them all first.
*   **Collection:** `uploads`
*   **Fields:**
    *   `uid`: String (Employee ID)
    *   `url`: String (Download Link)
    *   `type`: String ('image' or 'file')
    *   `fileName`: String
    *   `timestamp`: Timestamp

---

## 3. Employee Side (The Uploader)

**File:** `lib/screens/employee/upload_screen.dart`

This screen provides two big buttons: "Take Photo" and "Upload Document".

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  // 1. Upload Logic (Generic)
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

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Upload Successful!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. Pick Image (Camera/Gallery)
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 50);
    if (image != null) {
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
            
            // Camera Button
            _buildBigButton(
              icon: Icons.camera_alt, 
              label: "Take Photo (Site/Accident)", 
              color: Colors.blue, 
              onTap: () => _pickImage(ImageSource.camera)
            ),
            const SizedBox(height: 15),
            
            // Gallery Button
            _buildBigButton(
              icon: Icons.photo_library, 
              label: "Upload from Gallery", 
              color: Colors.orange, 
              onTap: () => _pickImage(ImageSource.gallery)
            ),
            const SizedBox(height: 15),

            // File Button
            _buildBigButton(
              icon: Icons.attach_file, 
              label: "Upload Document (PDF/Doc)", 
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
```

### **How to link this?**
Add a button in the **Employee Dashboard** (Home Tab or Profile Tab):
```dart
_buildActionCard(Icons.upload_file, "Upload Evidence", Colors.teal, () {
  Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()));
}),
```

---

## 4. Admin Side (The Viewer)

**File:** `lib/screens/admin/employee_monitor_dashboard.dart` (Update the `_ImagesTab` we made earlier).

This tab fetches the list from Firestore and displays it.

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class GalleryTab extends StatelessWidget {
  final String employeeId;
  const GalleryTab({Key? key, required this.employeeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('uploads')
            .where('uid', isEqualTo: employeeId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No uploads found for this employee."));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 items per row
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              bool isImage = data['type'] == 'image';
              String date = data['timestamp'] != null 
                  ? DateFormat('MMM d, h:mm a').format(data['timestamp'].toDate())
                  : '...';

              return GestureDetector(
                onTap: () => launchUrl(Uri.parse(data['url'])), // Open in Browser
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 5)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Thumbnail
                      Expanded(
                        child: isImage
                            ? ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                child: Image.network(data['url'], fit: BoxFit.cover),
                              )
                            : Container(
                                color: Colors.blue.shade50,
                                child: const Icon(Icons.insert_drive_file, size: 50, color: Colors.blue),
                              ),
                      ),
                      // 2. Metadata
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['fileName'] ?? 'Unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(date, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                          ],
                        ),
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
```

---

## 5. Security Rules (Storage)

You need to set rules for **Firebase Storage** (not just Database) so files are safe. Go to **Firebase Console -> Storage -> Rules**:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /uploads/{userId}/{allPaths=**} {
      // Admin can read/write everything
      // Employee can read/write only their own folder
      allow read, write: if request.auth != null && (request.auth.uid == userId || request.auth.token.role == 'admin');
    }
  }
}
```
*(Note: If you haven't set up Custom Claims for 'role', just use `allow read: if request.auth != null` for simplicity in testing).*

---

## 6. Summary of Flow

1.  **Emergency Situation:** Admin calls employee (using Contact Sync) and says "Send me a photo of the site damage immediately."
2.  **Employee:** Opens App -> Dashboard -> Upload Evidence -> Clicks "Take Photo" -> Snaps picture -> Uploads.
3.  **Admin:** Opens Admin Dashboard -> Employee Monitor -> Selects Employee -> Clicks "Gallery" Tab.
4.  **Result:** Admin sees the photo instantly with the timestamp.