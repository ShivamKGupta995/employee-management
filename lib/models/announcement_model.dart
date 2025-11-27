import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// AnnouncementModel - Represents a company announcement/notification
class AnnouncementModel {
  final String? id;
  final String title;
  final String message;
  final String category;
  final String? senderId;
  final DateTime? timestamp;

  AnnouncementModel({
    this.id,
    required this.title,
    required this.message,
    required this.category,
    this.senderId,
    this.timestamp,
  });

  /// Create from Firestore document
  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      category: data['category'] ?? 'General',
      senderId: data['senderId'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'category': category,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  /// Get category color
  Color get categoryColor => AppColors.getCategoryColor(category);

  /// Get category icon
  IconData get categoryIcon {
    switch (category.toLowerCase()) {
      case 'urgent':
        return Icons.warning_amber_rounded;
      case 'holiday':
        return Icons.beach_access;
      case 'event':
        return Icons.event;
      case 'policy':
        return Icons.policy;
      default:
        return Icons.info_outline;
    }
  }

  /// Check if announcement is urgent
  bool get isUrgent => category.toLowerCase() == 'urgent';

  /// Get formatted time string
  String get timeAgo {
    if (timestamp == null) return 'Just now';
    
    final now = DateTime.now();
    final difference = now.difference(timestamp!);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
