import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactService {

  // Internal check for specific contact updates
  static const int updateIntervalDays = 30;

  static Future<String> syncContactsToCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "User not logged in";

    try {
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        return "Permission denied";
      }

      List<Contact> localContacts =
          await FlutterContacts.getContacts(withProperties: true);
      if (localContacts.isEmpty) return "No contacts found on phone";

      CollectionReference contactsRef = FirebaseFirestore.instance
          .collection('user')
          .doc(user.uid)
          .collection('synced_contacts');

      QuerySnapshot snapshot = await contactsRef.get();

      Map<String, Map<String, dynamic>> existingDataMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String docId = doc.id;
        Timestamp? lastUpdated = data['lastUpdated'];

        if (data.containsKey('phones')) {
          List<dynamic> phones = data['phones'];
          for (var phone in phones) {
            String normPhone = _normalizePhone(phone.toString());
            existingDataMap[normPhone] = {
              'docId': docId,
              'lastUpdated':
                  lastUpdated?.toDate() ?? DateTime(2000, 1, 1),
            };
          }
        }
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      int operationCount = 0;
      int addedCount = 0;
      int updatedCount = 0;

      for (var contact in localContacts) {
        if (contact.phones.isEmpty) continue;

        List<String> phoneNumbers =
            contact.phones.map((e) => e.number).toList();

        String? matchingDocId;
        DateTime? storedDate;

        for (var phone in phoneNumbers) {
          String norm = _normalizePhone(phone);
          if (existingDataMap.containsKey(norm)) {
            matchingDocId = existingDataMap[norm]!['docId'];
            storedDate = existingDataMap[norm]!['lastUpdated'];
            break;
          }
        }

        Map<String, dynamic> contactData = {
          'displayName': contact.displayName,
          'phones': phoneNumbers,
          'emails': contact.emails.map((e) => e.address).toList(),
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        if (matchingDocId == null) {
          DocumentReference newDoc = contactsRef.doc();
          batch.set(newDoc, {
            ...contactData,
            'createdAt': FieldValue.serverTimestamp(),
          });
          addedCount++;
          operationCount++;
        } else {
          final difference =
              DateTime.now().difference(storedDate!).inDays;
          if (difference >= updateIntervalDays) {
            batch.update(
                contactsRef.doc(matchingDocId), contactData);
            updatedCount++;
            operationCount++;
          }
        }

        if (operationCount >= 450) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          operationCount = 0;
        }
      }

      if (operationCount > 0) {
        await batch.commit();
      }

      await FirebaseFirestore.instance
          .collection('user')
          .doc(user.uid)
          .update({
        'lastContactSync': FieldValue.serverTimestamp(),
      });

      if (addedCount == 0 && updatedCount == 0) {
        return "✅ Contacts up to date";
      }

      return "✅ Synced: $addedCount new, $updatedCount updated";

    } catch (e) {
      return "Error: $e";
    }
  }

  static String _normalizePhone(String phone) {
    return phone.replaceAll(RegExp(r'\D'), '');
  }
}
