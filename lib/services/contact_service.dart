import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactService {
  // This is the missing function causing the error
  static Future<String> syncContactsToCloud() async {
    // 1. Request Permission
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      return 'Permission Denied. Please enable contacts in settings.';
    }

    // 2. Get Local Contacts
    List<Contact> contacts = await FlutterContacts.getContacts(withProperties: true);
    
    if (contacts.isEmpty) return 'No contacts found on device';

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'User not logged in';

    // 3. Upload to Firebase
    WriteBatch batch = FirebaseFirestore.instance.batch();
    CollectionReference ref = FirebaseFirestore.instance
        .collection('user')
        .doc(user.uid)
        .collection('synced_contacts');

    // Cleanup old contacts (Optional: delete old ones before adding new)
    var snapshots = await ref.get();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }

    int count = 0;
    for (var contact in contacts) {
      if (contact.phones.isNotEmpty) {
        var newDoc = ref.doc();
        batch.set(newDoc, {
          'name': contact.displayName,
          'phone': contact.phones.first.number,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        count++;
        
        // Batch limit is 500, commit if we reach 400 to be safe
        if (count % 400 == 0) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
        }
      }
    }

    await batch.commit();
    return 'Success: $count contacts synced!';
  }
}