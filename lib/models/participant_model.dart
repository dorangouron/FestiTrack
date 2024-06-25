
import 'package:festitrack/models/gps_point_model.dart';

class Participant {
  final String id;
  final List<GPSPoint> gpsPoints;

  Participant({
    required this.id,
    required this.gpsPoints,
  });

  factory Participant.fromMap(Map<String, dynamic> data) {
    return Participant(
      id: data['id'] as String,
      gpsPoints: (data['gpsPoints'] as List)
          .map((point) => GPSPoint.fromMap(point as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gpsPoints': gpsPoints.map((point) => point.toMap()).toList(),
    };
  }
}