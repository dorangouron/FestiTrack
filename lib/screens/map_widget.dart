import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:festitrack/models/gps_point_model.dart';
import 'package:festitrack/models/participant_model.dart';
import 'package:festitrack/models/event_model.dart';
import 'package:festitrack/services/location_permission_handlers.dart';
import 'package:festitrack/services/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

class MapWidget extends StatefulWidget {
  final Event event;
  final bool isInteractive;

  const MapWidget({super.key, required this.event, required this.isInteractive});

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _controller;
  LocationData? _currentPosition;
  final Location _location = Location();
  Timer? _timer;
  final Map<String, List<LatLng>> _participantPositions = {};
  final int _maxPositions = 5;
  LatLng? _lastKnownPosition;
  StreamSubscription? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _listenToFirestoreUpdates(); // Écoute les mises à jour de Firestore
  }

  @override
  void dispose() {
    _timer?.cancel(); // Annule le timer lorsque le widget est détruit
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // Vérifie et demande les permissions de localisation
  Future<void> _checkLocationPermission() async {
    bool hasPermission = await LocationPermissionHandler().checkAndRequestLocationPermission(context);
    if (hasPermission) {
      _startTracking();
    }
  }

  // Démarre le suivi de la position GPS toutes les deux minutes
  Future<void> _startTracking() async {
    // Récupère la position initiale
    _currentPosition = await _location.getLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _savePosition(_currentPosition!); // Enregistre immédiatement la position
    });

    // Démarre un timer qui met à jour la position toutes les deux minutes
    _timer = Timer.periodic(const Duration(minutes: 2), (Timer timer) async {
      LocationData newPosition = await _location.getLocation();
      setState(() {
        _currentPosition = newPosition;
      });
      _savePosition(newPosition); // Sauvegarde la nouvelle position
    });
  }

  // Sauvegarde la position de l'utilisateur dans Firestore en respectant la structure du modèle
  Future<void> _savePosition(LocationData position) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;

      if (user == null) {
        print("User not logged in yet.");
        return; // Ne rien faire si l'utilisateur n'est pas encore chargé
      }

      final participantId = user.uid; // ID du participant

      final gpsPoint = GPSPoint(
        latitude: position.latitude!,
        longitude: position.longitude!,
        creationDate: DateTime.now(),
      );

      // Récupère les positions actuelles du participant
      DocumentReference eventRef = FirebaseFirestore.instance.collection('events').doc(widget.event.id);
      DocumentSnapshot eventSnapshot = await eventRef.get();

      if (eventSnapshot.exists) {
        Map<String, dynamic> eventData = eventSnapshot.data() as Map<String, dynamic>;
        Event event = Event.fromMap(eventData);

        // Trouver le participant actuel
        Participant? currentParticipant = event.participants.firstWhere(
          (p) => p.id == participantId,
          orElse: () => Participant(id: participantId, gpsPoints: []),
        );

        // Met à jour les positions GPS du participant (conserve seulement les 5 dernières)
        currentParticipant.gpsPoints.add(gpsPoint);
        if (currentParticipant.gpsPoints.length > _maxPositions) {
          currentParticipant.gpsPoints.removeAt(0); // Supprime la plus ancienne
        }

        // Met à jour l'événement avec les nouvelles positions
        event.participants.removeWhere((p) => p.id == participantId);
        event.participants.add(currentParticipant);

        // Sauvegarde dans Firestore
        await eventRef.set(event.toMap());

        print("Position saved and updated in Firestore.");
      }
    } catch (e) {
      print("Error saving position: $e");
    }
  }

  // Écoute les mises à jour de la base de données Firestore en temps réel
  void _listenToFirestoreUpdates() {
    _positionStreamSubscription = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.event.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        Event event = Event.fromMap(data);

        setState(() {
          _participantPositions.clear(); // Réinitialise les positions des participants

          // Récupère uniquement la dernière position de chaque participant
          for (Participant participant in event.participants) {
            if (participant.gpsPoints.isNotEmpty) {
              GPSPoint lastPoint = participant.gpsPoints.last;
              LatLng lastPosition = LatLng(lastPoint.latitude, lastPoint.longitude);

              // Ajoute la dernière position du participant
              _participantPositions[participant.id] = [lastPosition];
            }
          }
        });

        // Centre la carte sur la dernière position connue de l'utilisateur
        if (_currentPosition != null) {
          _controller?.animateCamera(CameraUpdate.newLatLng(
              LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!)));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      body: GoogleMap(
        scrollGesturesEnabled: widget.isInteractive,
        onMapCreated: (controller) {
          _controller = controller;
          if (_currentPosition != null) {
            _controller?.animateCamera(CameraUpdate.newLatLng(
                LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!)));
          }
        },
        initialCameraPosition: CameraPosition(
          target: _lastKnownPosition ?? const LatLng(0.0, 0.0), // Default to (0, 0) if no position is known
          zoom: 15,
        ),
        myLocationButtonEnabled: false,
        markers: _buildMarkers(),
        polylines: _buildPolylines(),
      ),

      // Bouton pour rafraîchir les permissions de localisation
      floatingActionButton: widget.isInteractive
          ? FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _checkLocationPermission,
              child: const Icon(Icons.refresh, color: Colors.black),
            )
          : null,
    );
  }

  // Construit les marqueurs pour la dernière position de chaque participant
  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    _participantPositions.forEach((participantId, positions) {
      if (positions.isNotEmpty) {
        var position = positions.last; // Utilise uniquement la dernière position
        markers.add(Marker(
          markerId: MarkerId('$participantId-${position.latitude}-${position.longitude}'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ));
      }
    });

    return markers;
  }

  // Construit les polylines pour afficher les traces des participants
  Set<Polyline> _buildPolylines() {
    Set<Polyline> polylines = {};

    _participantPositions.forEach((participantId, positions) {
      if (positions.length > 1) {
        polylines.add(Polyline(
          polylineId: PolylineId(participantId),
          points: positions,
          color: _getColorForParticipant(participantId),
          width: 4,
        ));
      }
    });

    return polylines;
  }

  // Génère des couleurs différentes pour les traces de chaque participant
  Color _getColorForParticipant(String participantId) {
    return Colors.primaries[participantId.hashCode % Colors.primaries.length];
  }
}
