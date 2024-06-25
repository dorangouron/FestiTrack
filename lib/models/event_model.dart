import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:festitrack/models/participant_model.dart';




class Event {
  final String id;
  final String name;
  final DateTime start;
  final DateTime end;
  final List<Participant> participants;

  Event({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    required this.participants,
  });

  factory Event.fromMap(Map<String, dynamic> data) {
    return Event(
      id: data['id'] as String,
      name: data['name'] as String,
      start: (data['start'] as Timestamp).toDate(),
      end: (data['end'] as Timestamp).toDate(),
      participants: (data['participants'] as List)
          .map((participant) => Participant.fromMap(participant as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'participants': participants.map((participant) => participant.toMap()).toList(),
    };
  }
}
