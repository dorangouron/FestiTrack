import 'package:festitrack/models/app_colors.dart';
import 'package:festitrack/models/event_model.dart';
import 'package:festitrack/models/participant_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate() && _startDate != null && _endDate != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final participant = Participant(
          id: user.uid,
          gpsPoints: [],
        );

        final eventId = const Uuid().v4();
        final event = Event(
          id: eventId,
          name: _nameController.text,
          start: _startDate!,
          end: _endDate!,
          participants: [participant],
        );

        await FirebaseFirestore.instance.collection('events').doc(eventId).set(event.toMap());
        Navigator.pop(context);
      } else {
        // Handle user not logged in case
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dominantColor,
      appBar: AppBar(
        backgroundColor: AppColors.dominantColor,
        foregroundColor: AppColors.secondaryColor,
        title: Row(
        children: [
          const Text("Ajouter un évènement", style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),),
        ],
      )),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom de lévènement'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ListTile(
                title: Text(_startDate == null
                    ? 'Date de début'
                    : DateFormat.yMd().format(_startDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, true),
              ),
              const SizedBox(width: 20),
              ListTile(
                title: Text(_endDate == null
                    ? 'Date de fin'
                    : DateFormat.yMd().format(_endDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context, false),
              ),
              
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
           onPressed: _createEvent,
            child: SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  'Terminer',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.dominantColor,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
