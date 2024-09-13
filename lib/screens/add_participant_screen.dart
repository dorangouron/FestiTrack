import 'package:festitrack/models/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:festitrack/models/participant_model.dart';

class AddParticipantScreen extends StatefulWidget {
  final String eventId;

  const AddParticipantScreen({super.key, required this.eventId});

  @override
  _AddParticipantScreenState createState() => _AddParticipantScreenState();
}

class _AddParticipantScreenState extends State<AddParticipantScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _searchUsers();
    } else {
      setState(() {
        _results = [];
      });
    }
  }

  void _searchUsers() async {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }

    final usersRef = FirebaseFirestore.instance.collection('users');
    final querySnapshot = await usersRef
        .where('searchTerms', arrayContains: query)
        .limit(10)
        .get();

    setState(() {
      _results =
          querySnapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
    });
  }

  void _addUserToEvent(Map<String, dynamic> user) async {
    final eventRef =
        FirebaseFirestore.instance.collection('events').doc(widget.eventId);
    final participant = Participant(id: user['id'], gpsPoints: []);

    await eventRef.update({
      'participants': FieldValue.arrayUnion([participant.toMap()]),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dominantColor,
      appBar: AppBar(
        backgroundColor: AppColors.dominantColor,
        foregroundColor: AppColors.secondaryColor,
        title: const Text('Ajouter un participant',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Rechercher par nom ou email',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return ListTile(
                    title: Text(user['displayName'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
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
