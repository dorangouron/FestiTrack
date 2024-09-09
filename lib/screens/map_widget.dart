import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:festitrack/models/event_model.dart';
import 'package:festitrack/services/location_permission_handlers.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

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

  @override
  void initState() {
    super.initState();
    print("MapWidget initialized"); // Log 1: Initialisation
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Vérifie et demande les permissions de localisation
  Future<void> _checkLocationPermission() async {
    print("Checking location permission..."); // Log 2: Vérification des permissions
    bool hasPermission = await LocationPermissionHandler().checkAndRequestLocationPermission(context);

    print("Location permission status: $hasPermission"); // Log 3: Résultat de la vérification des permissions

    if (hasPermission) {
      _startTracking();
    } else {
      print("Location permission denied."); // Log 4: Permission refusée
    }
  }

  // Démarre le suivi de la position GPS toutes les 2 minutes, si l'événement est en cours
  Future<void> _startTracking() async {
    print("Starting GPS tracking..."); // Log 5: Démarrage du suivi

    if (DateTime.now().isAfter(widget.event.start) && DateTime.now().isBefore(widget.event.end)) {
      print("Event is currently active."); // Log 6: L'événement est en cours

      _currentPosition = await _location.getLocation();
      print("Initial location: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}"); // Log 7: Position initiale

      setState(() {}); // Met à jour l'interface avec la position initiale

      // Sauvegarde les positions toutes les 2 minutes
      _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        LocationData newPosition = await _location.getLocation();
        print("New position: ${newPosition.latitude}, ${newPosition.longitude}"); // Log 8: Nouvelle position
        setState(() {
          _currentPosition = newPosition;
        });

        await _savePosition(newPosition);
      });
    } else {
      print("Event is not active."); // Log 9: L'événement n'est pas en cours
    }
  }

  // Sauvegarde la position dans Firestore et conserve uniquement les 5 dernières
  Future<void> _savePosition(LocationData position) async {
    try {
      print("Saving position to Firestore..."); // Log 10: Début de la sauvegarde

      String participantId = 'participant-id'; // Remplace par l'ID actuel du participant
      LatLng latLng = LatLng(position.latitude!, position.longitude!);

      // Ajoute la position à la liste des positions du participant
      if (_participantPositions.containsKey(participantId)) {
        _participantPositions[participantId]!.add(latLng);
        if (_participantPositions[participantId]!.length > _maxPositions) {
          _participantPositions[participantId]!.removeAt(0);
        }
      } else {
        _participantPositions[participantId] = [latLng];
      }

      // Sauvegarde dans Firestore
      await FirebaseFirestore.instance.collection('events').doc(widget.event.id).collection('positions').add({
        'participantId': participantId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("Position saved successfully!"); // Log 11: Sauvegarde réussie
    } catch (e) {
      print("Error saving position: $e"); // Log 12: Erreur de sauvegarde
    }
  }

  // Génère des couleurs différentes pour les traces de chaque participant
  Color _getColorForParticipant(String participantId) {
    return Colors.primaries[participantId.hashCode % Colors.primaries.length];
  }

  @override
  Widget build(BuildContext context) {
    print("Building the map..."); // Log 13: Construction de la carte
    return Scaffold(
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator()) // Si la position n'est pas encore disponible
          : GoogleMap(
              scrollGesturesEnabled: widget.isInteractive,
              onMapCreated: (controller) {
                _controller = controller;
                print("Map created."); // Log 14: Carte créée
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentPosition!.latitude!, _currentPosition!.longitude!),
                zoom: 15,
              ),
              //myLocationButtonEnabled: false,
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
            ),

    );
  }

  // Construit les marqueurs pour chaque position enregistrée
  Set<Marker> _buildMarkers() {
    print("Building markers..."); // Log 15: Construction des marqueurs
    Set<Marker> markers = {};

    _participantPositions.forEach((participantId, positions) {
      for (var position in positions) {
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
    print("Building polylines..."); // Log 16: Construction des polylines
    Set<Polyline> polylines = {};

    _participantPositions.forEach((participantId, positions) {
      polylines.add(Polyline(
        polylineId: PolylineId(participantId),
        points: positions,
        color: _getColorForParticipant(participantId),
        width: 4,
      ));
    });

    return polylines;
  }
}
