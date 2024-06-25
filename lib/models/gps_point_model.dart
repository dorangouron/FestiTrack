import 'package:cloud_firestore/cloud_firestore.dart';

class GPSPoint {
  final double latitude;
  final double longitude;
  final DateTime creationDate;

  GPSPoint({
    required this.latitude,
    required this.longitude,
    required this.creationDate,
  });

  factory GPSPoint.fromMap(Map<String, dynamic> data) {
    return GPSPoint(
      latitude: data['latitude'] as double,
      longitude: data['longitude'] as double,
      creationDate: (data['creationDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'creationDate': Timestamp.fromDate(creationDate),
    };
  }
}