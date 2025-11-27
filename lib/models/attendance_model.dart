import 'package:cloud_firestore/cloud_firestore.dart';

/// AttendanceModel - Represents a clock in/out record
class AttendanceModel {
  final String? id;
  final String uid;
  final String name;
  final String type; // 'Clock In' or 'Clock Out'
  final String date;
  final DateTime? timestamp;

  AttendanceModel({
    this.id,
    required this.uid,
    required this.name,
    required this.type,
    required this.date,
    this.timestamp,
  });

  /// Create from Firestore document
  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      date: data['date'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'type': type,
      'date': date,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  /// Check if this is a clock in
  bool get isClockIn => type == 'Clock In';

  /// Check if this is a clock out
  bool get isClockOut => type == 'Clock Out';
}

/// MonthlyStatsModel - Represents monthly attendance statistics
class MonthlyStatsModel {
  final String? id;
  final String uid;
  final String month;
  final String year;
  final int present;
  final int absent;
  final int late;
  final double? overtime;
  final double? rate;
  final DateTime? updatedAt;

  MonthlyStatsModel({
    this.id,
    required this.uid,
    required this.month,
    required this.year,
    required this.present,
    required this.absent,
    required this.late,
    this.overtime,
    this.rate,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory MonthlyStatsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MonthlyStatsModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      month: data['month'] ?? '',
      year: data['year'] ?? '',
      present: (data['present'] ?? 0).toInt(),
      absent: (data['absent'] ?? 0).toInt(),
      late: (data['late'] ?? 0).toInt(),
      overtime: (data['overtime'] as num?)?.toDouble(),
      rate: (data['rate'] as num?)?.toDouble(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'month': month,
      'year': year,
      'present': present,
      'absent': absent,
      'late': late,
      'overtime': overtime,
      'rate': rate,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Get total working days
  int get totalDays => present + absent;

  /// Calculate attendance score percentage
  int get attendanceScore {
    if (totalDays == 0) return 0;
    return ((present / totalDays) * 100).toInt();
  }

  /// Get status based on score
  String get status {
    if (attendanceScore >= 90) return 'Excellent';
    if (attendanceScore >= 80) return 'Good';
    if (attendanceScore >= 70) return 'Average';
    return 'Needs Improvement';
  }
}
