import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:employee_system/models/emergency_model.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyService {
  final CollectionReference _ref = FirebaseFirestore.instance.collection('emergency_contacts');

  // 1. READ (Stream)
  Stream<List<EmergencyModel>> getContacts() {
    return _ref.snapshots().map((snapshot) => 
      snapshot.docs.map((doc) => EmergencyModel.fromFirestore(doc)).toList()
    );
  }

  // 2. CREATE & UPDATE
  Future<void> saveContact(EmergencyModel contact) async {
    final data = contact.toMap();
    if (contact.id.isEmpty) {
      // Create New (Auto-ID)
      await _ref.add(data);
    } else {
      // Update Existing
      await _ref.doc(contact.id).update(data);
    }
  }

  // 3. DELETE
  Future<void> deleteContact(String id) async {
    await _ref.doc(id).delete();
  }

  // 4. CALL (Utility)
  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}