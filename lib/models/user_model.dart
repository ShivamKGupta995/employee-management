import 'package:cloud_firestore/cloud_firestore.dart';

/// UserModel - Represents a user (employee or admin) in the system
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? department;
  final bool isFrozen;
  final DateTime? createdAt;
  
  // Location fields (for employees)
  final double? currentLat;
  final double? currentLng;
  final DateTime? lastSeen;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final bool? isMocked;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.department,
    this.isFrozen = false,
    this.createdAt,
    this.currentLat,
    this.currentLng,
    this.lastSeen,
    this.speed,
    this.heading,
    this.accuracy,
    this.isMocked,
  });

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      role: data['role'] ?? 'employee',
      department: data['department'],
      isFrozen: data['isFrozen'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      currentLat: (data['current_lat'] as num?)?.toDouble(),
      currentLng: (data['current_lng'] as num?)?.toDouble(),
      lastSeen: (data['last_seen'] as Timestamp?)?.toDate(),
      speed: (data['speed'] as num?)?.toDouble(),
      heading: (data['heading'] as num?)?.toDouble(),
      accuracy: (data['accuracy'] as num?)?.toDouble(),
      isMocked: data['is_mocked'],
    );
  }

  /// Create from Map
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      role: map['role'] ?? 'employee',
      department: map['department'],
      isFrozen: map['isFrozen'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      currentLat: (map['current_lat'] as num?)?.toDouble(),
      currentLng: (map['current_lng'] as num?)?.toDouble(),
      lastSeen: (map['last_seen'] as Timestamp?)?.toDate(),
      speed: (map['speed'] as num?)?.toDouble(),
      heading: (map['heading'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      isMocked: map['is_mocked'],
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'department': department,
      'isFrozen': isFrozen,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Check if user is admin
  bool get isAdmin => role == 'admin';

  /// Check if user is employee
  bool get isEmployee => role == 'employee';

  /// Check if user is online (last seen within 5 minutes)
  bool get isOnline {
    if (lastSeen == null) return false;
    return DateTime.now().difference(lastSeen!).inMinutes < 5;
  }

  /// Get initials for avatar
  String get initials {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Copy with method
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? department,
    bool? isFrozen,
    DateTime? createdAt,
    double? currentLat,
    double? currentLng,
    DateTime? lastSeen,
    double? speed,
    double? heading,
    double? accuracy,
    bool? isMocked,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      department: department ?? this.department,
      isFrozen: isFrozen ?? this.isFrozen,
      createdAt: createdAt ?? this.createdAt,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      lastSeen: lastSeen ?? this.lastSeen,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      accuracy: accuracy ?? this.accuracy,
      isMocked: isMocked ?? this.isMocked,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, role: $role)';
  }
}
