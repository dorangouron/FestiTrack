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


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()), // Fournir le UserProvider
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
  await Firebase.initializeApp();  // Assurez-vous que Firebase est bien initialisé
  await initializeService();       // Démarrer le service après l'initialisation de Firebase
  runApp(const MyApp());
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

// Fonction à exécuter en arrière-plan
void onStart(ServiceInstance service) async {
  // Initialiser Firebase dans le service d'arrière-plan
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print("Firebase initialized in background service");

  Location location = Location();

  // Récupérer les événements en cours et enregistrer la position
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print("No user is currently logged in. Exiting...");
      return;
    }

    print("User logged in: ${currentUser.uid}");

    LocationData locationData;
    try {
      locationData = await location.getLocation();
      print("Location obtained: ${locationData.latitude}, ${locationData.longitude}");
    } catch (e) {
      print("Error getting location: $e");
      return;
    }

    // Récupérer les événements où l'utilisateur est potentiellement un participant
    QuerySnapshot eventsSnapshot;
    try {
      eventsSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .get(); // Récupérer tous les événements (filtrer dans le code)
      print("Events snapshot retrieved: ${eventsSnapshot.size} events found");
    } catch (e) {
      print("Error retrieving events: $e");
      return;
    }

    if (eventsSnapshot.docs.isEmpty) {
      print("No events found.");
      return;
    }

    for (var eventDoc in eventsSnapshot.docs) {
      // Convertir l'événement Firestore en objet Event
      final eventData = eventDoc.data() as Map<String, dynamic>;
      Event event = Event.fromMap(eventData);
      final now = DateTime.now();
      print("Checking event: ${event.id}, start: ${event.start}, end: ${event.end}");

      // Vérifier si l'événement est en cours
      if (now.isAfter(event.start) && now.isBefore(event.end)) {
        print("Event ${event.id} is active");

        // Vérifier si l'utilisateur est un participant à cet événement
        bool isParticipant = event.participants.any((participant) => participant.id == currentUser.uid);
        if (!isParticipant) {
          print("User is not a participant in event: ${event.id}");
          continue; // Passer à l'événement suivant
        }

        print("User is a participant in event: ${event.id}");

        // Trouver le participant actuel
        Participant? currentParticipant = event.participants.firstWhere(
          (participant) => participant.id == currentUser.uid,
          orElse: () {
            print("Current participant not found, creating new participant");
            return Participant(id: currentUser.uid, gpsPoints: []);
          },
        );

        // Ajouter le nouveau GPSPoint
        GPSPoint newGpsPoint = GPSPoint(
          latitude: locationData.latitude!,
          longitude: locationData.longitude!,
          creationDate: DateTime.now(),
        );
        print("New GPS point: ${newGpsPoint.latitude}, ${newGpsPoint.longitude}");

        // Mettre à jour la liste des GPSPoints (conserver uniquement les 5 derniers)
        currentParticipant.gpsPoints.add(newGpsPoint);
        if (currentParticipant.gpsPoints.length > 5) {
          currentParticipant.gpsPoints.removeAt(0); // Supprimer le plus ancien point
          print("Old GPS point removed. Current number of points: ${currentParticipant.gpsPoints.length}");
        }

        // Mettre à jour la liste des participants
        event.participants.removeWhere((participant) => participant.id == currentUser.uid);
        event.participants.add(currentParticipant);

        // Mettre à jour l'événement dans Firestore avec les nouvelles positions
        try {
          await FirebaseFirestore.instance
              .collection('events')
              .doc(eventDoc.id)
              .update(event.toMap());
          print("Position saved and updated in Firestore for event: ${event.id}");
        } catch (e) {
          print("Error updating event in Firestore: $e");
        }
      } else {
        print("Event ${event.id} is not active. Skipping...");
      }
    }
  });
}





// iOS background handler (nécessaire pour iOS)
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  print('iOS background fetch');
  return true;
}

