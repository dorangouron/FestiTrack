import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:festitrack/screens/create_event_screen.dart';
import 'package:festitrack/screens/map_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isEventOngoing = false;
  String? _eventId;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _checkEventStatus();
    _requestLocationPermission();
  }

  Future<void> _checkEventStatus() async {
    final now = DateTime.now();
    final query = await FirebaseFirestore.instance
        .collection('events')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThanOrEqualTo: now)
        .get();

    if (query.docs.isNotEmpty) {
      setState(() {
        _isEventOngoing = true;
        _eventId = query.docs.first.id;
      });
    } else {
      setState(() {
        _isEventOngoing = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus permission = await Permission.location.request();

    if (permission.isGranted) {
      setState(() {
        _hasLocationPermission = true;
      });
    } else {
      // Handle the case when permission is not granted
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required to use this feature.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Row(
        children: [
          Text("Hello username !", style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24
          ),),
        ],
      )),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: <Widget>[
                                              //if (_isEventOngoing)
              Column(
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: _hasLocationPermission
                        ? MapScreen(eventId: _eventId)
                        : const Center(child: CircularProgressIndicator()),
                  ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("En cours",style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber
                        ),),
                        SizedBox(height: 4,),
                        Text("eventName",style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600
                        ),),
                        SizedBox(height: 8,)
                      ],
                    ),
                ],
              ),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('À venir',style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600
                        ),),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CreateEventScreen()),
                            ).then((value) {
                              _checkEventStatus();
                            });
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),

            ],
          ),
        ),
      ),
    );
  }
}
