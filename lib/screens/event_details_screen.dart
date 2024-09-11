import 'package:festitrack/models/app_colors.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:festitrack/models/event_model.dart';
import 'package:festitrack/screens/map_widget.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'add_participant_screen.dart';  // Import the new screen

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  Future<void> _createDynamicLink(BuildContext context) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://festitrack.page.link',
      link: Uri.parse('https://festitrack.page.link/invite?eventId=${event.id}'),
      androidParameters: const AndroidParameters(
        packageName: 'com.festitrack.app',
        minimumVersion: 0,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.example.festitrack',
        minimumVersion: '0',
      ),
    );

    final ShortDynamicLink dynamicUrl = await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    final Uri shortUrl = dynamicUrl.shortUrl;

    Share.share('Join my event called ${event.name}\n$shortUrl');
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
                  event.name,
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
                  'Positions du groupe',
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
                      final size = constraints.maxWidth; // Prendre la largeur disponible maximale
                      return ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(15)),
                        child: SizedBox(
                          height: size,  // Utiliser la largeur maximale disponible pour la hauteur
                          width: size,   // Utiliser la largeur maximale disponible pour la largeur
                          child: MapWidget(eventId: event.id),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
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
                          }),
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
                                      'du ${DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(event.start)}',
                                      style: const TextStyle(color: AppColors.secondaryColor),
                                    ),
                                    Text(
                                      'du ${DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(event.end)}',
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
                          foregroundColor: AppColors.dominantColor
                        ),
                        onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AddParticipantScreen(eventId: event.id)),
                        );
                      },
                        child: const Icon(Icons.add),
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                ...event.participants.map((participant) {
                  return ListTile(
                    leading: const Icon(
                      Icons.person,
                      color: AppColors.secondaryColor
                    ),
                    title: Text(
                      participant.id == event.participants.first.id ? "Toi" : participant.id,
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
