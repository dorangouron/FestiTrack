import 'dart:async';
import 'package:festitrack/models/app_colors.dart';
import 'package:festitrack/models/event_model.dart';
import 'package:festitrack/models/gps_point_model.dart';
import 'package:festitrack/models/participant_model.dart';
import 'package:festitrack/services/auth_wrapper.dart';
import 'package:festitrack/services/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // Import du package provider
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => UserProvider()), // Fournir le UserProvider
      ],
      child: const MaterialApp(
        color: AppColors.dominantColor,
        home: AuthWrapper(),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase
      .initializeApp(); // Assurez-vous que Firebase est bien initialisé
  await initializeService(); // Démarrer le service après l'initialisation de Firebase
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

void onStart(ServiceInstance service) async {
  // Initialiser Firebase dans le service d'arrière-plan
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print("Firebase initialized in background service");

  Location location = Location();

  // Fonction pour vérifier s'il y a des événements actifs
  Future<bool> hasActiveEvents() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("No user is currently logged in.");
      return false;
    }

    final now = DateTime.now();
    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThan: now)
        .get();

    for (var eventDoc in eventsSnapshot.docs) {
      final eventData = eventDoc.data() as Map<String, dynamic>;
      Event event = Event.fromMap(eventData);
      if (event.participants
          .any((participant) => participant.id == currentUser.uid)) {
        return true;
      }
    }

    return false;
  }

  // Fonction pour traiter les événements actifs
  Future<void> processActiveEvents() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    LocationData locationData;
    try {
      locationData = await location.getLocation();
      print(
          "Location obtained: ${locationData.latitude}, ${locationData.longitude}");
    } catch (e) {
      print("Error getting location: $e");
      return;
    }

    final now = DateTime.now();
    final eventsSnapshot = await FirebaseFirestore.instance
        .collection('events')
        .where('start', isLessThanOrEqualTo: now)
        .where('end', isGreaterThan: now)
        .get();

    for (var eventDoc in eventsSnapshot.docs) {
      final eventData = eventDoc.data() as Map<String, dynamic>;
      Event event = Event.fromMap(eventData);

      if (event.participants
          .any((participant) => participant.id == currentUser.uid)) {
        print("User is a participant in active event: ${event.id}");

        Participant currentParticipant = event.participants.firstWhere(
          (participant) => participant.id == currentUser.uid,
          orElse: () => Participant(id: currentUser.uid, gpsPoints: []),
        );

        GPSPoint newGpsPoint = GPSPoint(
          latitude: locationData.latitude!,
          longitude: locationData.longitude!,
          creationDate: DateTime.now(),
        );

        currentParticipant.gpsPoints.add(newGpsPoint);
        if (currentParticipant.gpsPoints.length > 5) {
          currentParticipant.gpsPoints.removeAt(0);
        }

        event.participants
            .removeWhere((participant) => participant.id == currentUser.uid);
        event.participants.add(currentParticipant);

        try {
          await FirebaseFirestore.instance
              .collection('events')
              .doc(eventDoc.id)
              .update(event.toMap());
          print("Position updated for event: ${event.id}");
        } catch (e) {
          print("Error updating event in Firestore: $e");
        }
      }
    }
  }

  // Boucle principale avec vérification des événements actifs
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (await hasActiveEvents()) {
      print("Active events found. Processing...");
      await processActiveEvents();
    } else {
      print("No active events. Skipping location update.");
    }
  });
}

// Initialiser le service d'arrière-plan
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Configurer le service pour Android
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// iOS background handler (nécessaire pour iOS)
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  print('iOS background fetch');
  return true;
}
