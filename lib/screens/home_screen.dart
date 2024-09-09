import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:festitrack/models/event_model.dart';
import 'package:festitrack/screens/create_event_screen.dart';
import 'package:festitrack/screens/event_details_screen.dart';
import 'package:festitrack/screens/map_widget.dart';
import 'package:festitrack/screens/sign_in_screen.dart';
import 'package:festitrack/services/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isEventOngoing = false;
  Event? _currentEvent;
  List<Event> _upcomingEvents = [];
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Appelle _fetchEvents une seule fois après que les dépendances soient disponibles
    if (!_initialized) {
      _fetchEvents();
      _initialized = true;
    }
  }

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  Future<void> _fetchEvents() async {
    final now = DateTime.now();

    // Vérifie si l'utilisateur est défini avant de continuer
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) {
      print("L'utilisateur n'est pas encore défini.");
      return; // Retourne sans exécuter la logique de fetch si l'utilisateur est null
    }

    final userId = user.uid;

    try {
      print('Fetching events...');
      final query = await FirebaseFirestore.instance.collection('events').get();

      final events = query.docs.map((doc) => Event.fromMap(doc.data())).toList();

      final ongoingEvents = events.where((event) {
        return event.start.isBefore(now) && event.end.isAfter(now);
      }).toList();

      final upcomingEvents = events.where((event) {
        return event.start.isAfter(now);
      }).toList();

      final userUpcomingEvents = upcomingEvents.where((event) {
        return event.participants.any((participant) => participant.id == userId);
      }).toList();

      print('Ongoing events: ${ongoingEvents.length}');
      print('Upcoming events: ${userUpcomingEvents.length}');

      setState(() {
        if (ongoingEvents.isNotEmpty) {
          _isEventOngoing = true;
          _currentEvent = ongoingEvents.first;
        } else if (userUpcomingEvents.isNotEmpty) {
          _isEventOngoing = false;
          _currentEvent = userUpcomingEvents.first;
        }
        _upcomingEvents = userUpcomingEvents;
      });
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    // Assure-toi que l'utilisateur est défini avant de rendre l'écran
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              "Hello ${user.displayName ?? 'Utilisateur'} !",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => signOut(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: <Widget>[
              if (_currentEvent != null)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              EventDetailScreen(event: _currentEvent!)),
                    );
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = constraints.maxWidth;
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
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
                                height: size,
                                width: size,
                                child: MapWidget(
                                    event: _currentEvent!,
                                    isInteractive: false),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isEventOngoing
                                        ? "En cours..."
                                        : "À venir...",
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentEvent!.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 32),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Évènements à venir',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const CreateEventScreen()),
                          ).then((value) {
                            _fetchEvents(); // Rafraîchir les événements après la création
                          });
                        },
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  _upcomingEvents.isEmpty
                      ? const Text("Pas d'évènements à venir")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _upcomingEvents.length,
                          itemBuilder: (context, index) {
                            final event = _upcomingEvents[index];
                            return ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          EventDetailScreen(event: event)),
                                );
                              },
                              title: Text(event.name),
                              subtitle: Text(event.participants.length > 1
                                  ? "${event.participants.length} participants"
                                  : "${event.participants.length} participant"),
                              trailing: IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.share),
                              ),
                            );
                          },
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
