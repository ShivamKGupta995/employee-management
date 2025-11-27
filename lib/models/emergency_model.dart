import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyModel {
  final String id;
  final String title;      // e.g., "Ambulance", "HR Hotline"
  final String phoneNumber; // e.g., "102", "+919876543210"
  final String type;       // 'Medical', 'Police', 'Fire', 'General'

  EmergencyModel({
    required this.id,
    required this.title,
    required this.phoneNumber,
    required this.type,
  });

  factory EmergencyModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EmergencyModel(
      id: doc.id,
      title: data['title'] ?? 'Emergency',
      phoneNumber: data['phoneNumber'] ?? '',
      type: data['type'] ?? 'General',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'phoneNumber': phoneNumber,
      'type': type,
    };
  }
}