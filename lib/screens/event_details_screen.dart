import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:festitrack/models/event_model.dart';
import 'package:festitrack/screens/map_widget.dart';
import 'package:flutter/material.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                            "En cours...",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber,
                              fontWeight: FontWeight.w600
                            ),
                          ),
                          SizedBox(height: 4,),
                Text(
                  event.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: SizedBox(
                        height: 500,
                        width: double.infinity,
                        child: MapWidget(event: event),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          Text(
                            "Localisation des membres",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...event.participants.map((participant) {
                            return ListTile(
                              leading: Icon(
                                Icons.circle,
                                color: participant.id == event.participants.first.id
                                    ? Colors.blue
                                    : Colors.green,
                              ),
                              title: Text(
                                participant.id == event.participants.first.id ? "Toi" : participant.id,
                                style: const TextStyle(fontSize: 16),
                              ),
                              trailing: participant.id == event.participants.first.id
                                  ? null
                                  : const Text("à 5m"),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
