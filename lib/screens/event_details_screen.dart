import 'package:festitrack/models/app_colors.dart';
import 'package:festitrack/models/gps_point_model.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:festitrack/models/event_model.dart';
import 'package:festitrack/screens/map_widget.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:festitrack/screens/add_participant_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic> participantsData = {};

  @override
  void initState() {
    super.initState();
    _loadParticipantsData();
  }

  Future<void> _loadParticipantsData() async {
    for (var participant in widget.event.participants) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(participant.id).get();
      if (userDoc.exists) {
        participantsData[participant.id] =
            userDoc.data() as Map<String, dynamic>;
      }
    }
    setState(() {});
  }

  String _getParticipantName(String participantId) {
    if (participantId == _auth.currentUser?.uid) {
      return "Toi";
    }
    return participantsData[participantId]?['displayName'] ?? 'Inconnu';
  }

  Future<double> _calculateDistance(String participantId) async {
    if (participantId == _auth.currentUser?.uid) return 0;

    Position userPosition = await Geolocator.getCurrentPosition();
    List<GPSPoint> participantPoints = widget.event.participants
        .firstWhere((p) => p.id == participantId)
        .gpsPoints;

    if (participantPoints.isEmpty) {
      return double.infinity;
    }

    GPSPoint lastPoint = participantPoints.last;
    return Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      lastPoint.latitude,
      lastPoint.longitude,
    );
  }

  Future<void> _createDynamicLink(BuildContext context) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://festitrack.page.link',
      link: Uri.parse(
          'https://festitrack.page.link/invite?eventId=${widget.event.id}'),
      androidParameters: const AndroidParameters(
        packageName: 'com.festitrack.app',
        minimumVersion: 0,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.example.festitrack',
        minimumVersion: '0',
      ),
    );

    final ShortDynamicLink dynamicUrl =
        await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    final Uri shortUrl = dynamicUrl.shortUrl;

    Share.share('Join my event called ${widget.event.name}\n$shortUrl');
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "En ce moment !",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _createDynamicLink(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Carte du groupe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryColor,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxWidth;
                      return ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(15)),
                        child: SizedBox(
                          height: size,
                          width: size,
                          child: MapWidget(eventId: widget.event.id),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
                ...widget.event.participants.map((participant) {
                  return FutureBuilder<double>(
                    future: _calculateDistance(participant.id),
                    builder: (context, snapshot) {
                      return ListTile(
                        leading: Icon(
                          Icons.circle,
                          color: participant.id == _auth.currentUser?.uid
                              ? Colors.blue
                              : Colors.green,
                        ),
                        title: Text(
                          _getParticipantName(participant.id),
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: participant.id == _auth.currentUser?.uid
                            ? null
                            : Text(snapshot.hasData
                                ? "${snapshot.data!.toStringAsFixed(0)}m"
                                : "Calcul..."),
                      );
                    },
                  );
                }),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              MapWidget(eventId: widget.event.id)),
                    );
                  },
                  child: const Text(
                    'Voir en détails',
                    style: TextStyle(color: AppColors.accentColor),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Dates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryColor,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'du ${DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(widget.event.start)}',
                  style: const TextStyle(color: AppColors.secondaryColor),
                ),
                Text(
                  'au ${DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(widget.event.end)}',
                  style: const TextStyle(color: AppColors.secondaryColor),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Membres du groupe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentColor,
                        foregroundColor: AppColors.dominantColor,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddParticipantScreen(
                                  eventId: widget.event.id)),
                        );
                      },
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ...widget.event.participants.map((participant) {
                  return ListTile(
                    leading: const Icon(
                      Icons.person,
                      color: AppColors.secondaryColor,
                    ),
                    title: Text(
                      _getParticipantName(participant.id),
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
