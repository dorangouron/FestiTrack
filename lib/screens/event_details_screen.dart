import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:festitrack/models/event_model.dart';
import 'package:festitrack/screens/map_widget.dart';
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
      appBar: AppBar(
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
                    color: Colors.green,
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
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius:  BorderRadius.all(Radius.circular(15)
                        ),
                        child: SizedBox(
                          height: 500,
                          width: double.infinity,
            
                          child: MapWidget(eventId: event.id),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Localisation de mon groupe",
                            style: TextStyle(
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
                          }),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AddParticipantScreen(eventId: event.id)),
                              );
                            },
                            child: const Text('Ajouter un pote'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
