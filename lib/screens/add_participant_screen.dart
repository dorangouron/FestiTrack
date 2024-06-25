import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:festitrack/models/participant_model.dart'; // Import the Participant model

class AddParticipantScreen extends StatefulWidget {
  final String eventId;

  const AddParticipantScreen({super.key, required this.eventId});

  @override
  _AddParticipantScreenState createState() => _AddParticipantScreenState();
}

class _AddParticipantScreenState extends State<AddParticipantScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _results = [];

  void _searchUsers() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return;
    }

    // Assume that current user's Google account matches the query for demonstration
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null && user.displayName!.toLowerCase().contains(query)) {
      setState(() {
        _results = [user];
      });
    } else {
      setState(() {
        _results = [];
      });
    }
  }

  void _addUserToEvent(User user) async {
    final eventRef = FirebaseFirestore.instance.collection('events').doc(widget.eventId);
    final participant = Participant(id: user.uid, gpsPoints: []);

    await eventRef.update({
      'participants': FieldValue.arrayUnion([participant.toMap()]),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Participant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return ListTile(
                    title: Text(user.displayName ?? ''),
                    trailing: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () => _addUserToEvent(user),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
