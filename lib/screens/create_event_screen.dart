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
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate() &&
        _startDate != null &&
        _endDate != null &&
        _startTime != null &&
        _endTime != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final participant = Participant(
          id: user.uid,
          gpsPoints: [],
        );

        final eventId = const Uuid().v4();
        final startDateTime = DateTime(
          _startDate!.year,
          _startDate!.month,
          _startDate!.day,
          _startTime!.hour,
          _startTime!.minute,
        );
        final endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );

        final event = Event(
          id: eventId,
          name: _nameController.text,
          start: startDateTime,
          end: endDateTime,
          participants: [participant],
        );

        await FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .set(event.toMap());
        Navigator.pop(context);
      } else {
        // Handle user not logged in case
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Vous devez être connecté pour créer un événement.')),
        );
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

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
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
          title: const Row(
            children: [
              Text(
                "Ajouter un évènement",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration:
                      const InputDecoration(labelText: 'Nom de l\'évènement'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: Text(_startDate == null
                      ? 'Date de début'
                      : DateFormat('dd/MM/yyyy').format(_startDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, true),
                ),
                ListTile(
                  title: Text(_startTime == null
                      ? 'Heure de début'
                      : _startTime!.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _selectTime(context, true),
                ),
                const SizedBox(height: 20),
                ListTile(
                  title: Text(_endDate == null
                      ? 'Date de fin'
                      : DateFormat('dd/MM/yyyy').format(_endDate!)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, false),
                ),
                ListTile(
                  title: Text(_endTime == null
                      ? 'Heure de fin'
                      : _endTime!.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _selectTime(context, false),
                ),
              ],
            ),
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
            child: const SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  'Terminer',
                  style: TextStyle(
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
