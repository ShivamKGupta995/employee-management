import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryBackupService {
  static Future<void> startBackupIfEnabled() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef =
        FirebaseFirestore.instance.collection('user').doc(user.uid);

    final userDoc = await userRef.get();
    if (userDoc.data()?['backup_gallery'] != true) {
      print('🚫 Gallery backup disabled');
      return;
    }

    print('🔄 Gallery backup started');

    await userRef.update({
      'backup_status': 'running',
      'last_backup_check': FieldValue.serverTimestamp(),
    });

    final files = await _getAllMediaFiles();
    print('📸 Found ${files.length} images');

    for (final file in files) {
      final alreadyUploaded = await _isAlreadyUploaded(user.uid, file.path);
      if (alreadyUploaded) continue;

      await _uploadFile(
        file: file,
        uid: user.uid,
        source: 'auto_backup',
      );
    }

    await userRef.update({'backup_status': 'idle'});
    print('✅ Gallery backup finished');
  }

  // ---------- HELPERS ----------

  static Future<bool> _isAlreadyUploaded(String uid, String path) async {
    final snap = await FirebaseFirestore.instance
        .collection('uploads')
        .where('uid', isEqualTo: uid)
        .where('file_path', isEqualTo: path)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty;
  }

  static Future<void> _uploadFile({
    required File file,
    required String uid,
    required String source,
  }) async {
    final fileName = file.uri.pathSegments.last;

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('uploads/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName');

    final snapshot = await storageRef.putFile(file);
    final url = await snapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('uploads').add({
      'uid': uid,
      'url': url,
      'fileName': fileName,
      'type': 'image',
      'source': source,
      'file_path': file.path,
      'status': 'uploaded',
      'created_at': FieldValue.serverTimestamp(),
    });

    print('⬆️ Uploaded: $fileName');
  }

  static Future<List<File>> _getAllMediaFiles() async {
  final permission = await PhotoManager.requestPermissionExtend();
  if (!permission.isAuth) {
    print('❌ Gallery permission denied');
    return [];
  }

  final List<File> files = [];

  // 🔥 EXPLICIT FILTER (THIS FIXES SQL)
  final filter = FilterOptionGroup(
    imageOption: const FilterOption(
      needTitle: true,
      sizeConstraint: SizeConstraint(ignoreSize: true),
    ),
    orders: [
      const OrderOption(
        type: OrderOptionType.createDate,
        asc: false,
      ),
    ],
  );

  final albums = await PhotoManager.getAssetPathList(
    type: RequestType.image,
    filterOption: filter,
  );

  if (albums.isEmpty) return [];

  final album = albums.first;

  // Fetch assets in small batches safely
  int page = 0;
  const int size = 50;

  while (true) {
    final assets = await album.getAssetListPaged(
      page: page,
      size: size,
    );

    if (assets.isEmpty) break;

    for (final asset in assets) {
      final file = await asset.file;
      if (file != null) files.add(file);
    }

    page++;
  }

  return files;
}

}
