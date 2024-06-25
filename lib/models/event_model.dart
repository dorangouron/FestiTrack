import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  String id;
  String name;
  DateTime start;
  DateTime end;

  Event({required this.id, required this.name, required this.start, required this.end});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start': start,
      'end': end,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      name: map['name'],
      start: (map['start'] as Timestamp).toDate(),
      end: (map['end'] as Timestamp).toDate(),
    );
  }
}
