import 'package:cloud_firestore/cloud_firestore.dart';

/// LocationModel - Represents a GPS location point
class LocationModel {
  final String? id;
  final double lat;
  final double lng;
  final double? speed;
  final double? accuracy;
  final DateTime? timestamp;

  LocationModel({
    this.id,
    required this.lat,
    required this.lng,
    this.speed,
    this.accuracy,
    this.timestamp,
  });

  /// Create from Firestore document
  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LocationModel(
      id: doc.id,
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      speed: (data['speed'] as num?)?.toDouble(),
      accuracy: (data['accuracy'] as num?)?.toDouble(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'accuracy': accuracy,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  /// Get speed in km/h
  double get speedKmh => (speed ?? 0) * 3.6;

  /// Get formatted speed string
  String get speedFormatted => '${speedKmh.toStringAsFixed(1)} km/h';
}
