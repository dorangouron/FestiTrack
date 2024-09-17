import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:festitrack/models/app_colors.dart';
import 'package:festitrack/models/event_model.dart';
import 'package:festitrack/screens/create_event_screen.dart';
import 'package:festitrack/screens/event_details_screen.dart';
import 'package:festitrack/screens/sign_in_screen.dart';
import 'package:festitrack/services/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isEventOngoing = false;
  Event? _currentEvent;
  List<Event> _upcomingEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> signOut(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  Future<void> _fetchEvents() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;

    if (user == null) {
      print("L'utilisateur n'est pas encore défini.");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final userId = user.uid;
    final now = DateTime.now();

    try {
      final query = await FirebaseFirestore.instance.collection('events').get();

      final events = query.docs
          .map((doc) => Event.fromMap(doc.data()))
          .where((event) =>
              event.participants.any((participant) => participant.id == userId))
          .toList();

      final ongoingEvents = events.where((event) {
        return event.start.isBefore(now) && event.end.isAfter(now);
      }).toList();

      final upcomingEvents = events.where((event) {
        return event.start.isAfter(now);
      }).toList();

      setState(() {
        if (ongoingEvents.isNotEmpty) {
          _isEventOngoing = true;
          _currentEvent = ongoingEvents.first;
        } else if (upcomingEvents.isNotEmpty) {
          _isEventOngoing = false;
          _currentEvent = upcomingEvents.first;
        } else {
          _currentEvent = null;
        }
        _upcomingEvents = upcomingEvents;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (userProvider.isLoading || _isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = userProvider.user;
        if (user == null) {
          return const SignInScreen();
        }

        return Scaffold(
          backgroundColor: AppColors.dominantColor,
          appBar: AppBar(
            backgroundColor: AppColors.dominantColor,
            title: Text(
              "Hello ${user.displayName ?? 'Utilisateur'} !",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: AppColors.secondaryColor),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => signOut(context),
                color: AppColors.secondaryColor,
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _fetchEvents,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (_currentEvent != null) ...[
                      const SizedBox(height: 15),
                      const Text(
                        'Prochain évènement',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    EventDetailScreen(event: _currentEvent!)),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                child: SizedBox(
                                    height: 80,
                                    width: 80,
                                    child: GoogleMap(
                                      initialCameraPosition:
                                          const CameraPosition(
                                        target: LatLng(47.58676294336266,
                                            -3.0611525541114726),
                                        zoom: 15,
                                      ),
                                      myLocationButtonEnabled: false,
                                    )),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currentEvent!.name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.secondaryColor),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _isEventOngoing
                                          ? "En ce moment !"
                                          : "Prochain évènement",
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.accentColor,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Évènements à venir',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryColor),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentColor,
                              foregroundColor: AppColors.dominantColor),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateEventScreen()),
                            ).then((value) {
                              _fetchEvents();
                            });
                          },
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    _upcomingEvents.isEmpty
                        ? const Text("Rien de prévu, crée un évènement !")
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
                                title: Text(event.name,
                                    style: const TextStyle(
                                        color: AppColors.secondaryColor)),
                                subtitle: Text(
                                  event.participants.length > 1
                                      ? "${event.participants.length} participants"
                                      : "${event.participants.length} participant",
                                  style: const TextStyle(
                                    color: AppColors.secondaryColor,
                                  ),
                                ),
                                trailing: IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.share,
                                      color: AppColors.accentColor),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
