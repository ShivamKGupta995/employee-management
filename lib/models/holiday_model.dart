import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HolidayModel {
  final String? id; // ✅ Nullable: It is null when creating a new holiday
  final String name;
  final DateTime date;
  final String type; // 'Public' or 'Company'

  HolidayModel({
    this.id, 
    required this.name, 
    required this.date, 
    required this.type
  });

  // Factory: Get ID from the Document Snapshot, not the data map
  factory HolidayModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return HolidayModel(
      id: doc.id, // ✅ ID comes from the document key
      name: data['name'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'] ?? 'Public',
    );
  }

  // toMap: Exclude ID (Firestore handles it)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': Timestamp.fromDate(date),
      'type': type,
      // ❌ Do not add 'id': id here
    };
  }

  String get dayName => DateFormat('EEEE').format(date);
}