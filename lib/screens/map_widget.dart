import 'package:festitrack/models/event_model.dart';
import 'package:festitrack/services/location_permission_handlers.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapWidget extends StatefulWidget {
  final Event event;
  final bool isInteractive;

  const MapWidget(
      {super.key, required this.event, required this.isInteractive});

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _controller;
  LocationData? _currentPosition;
  final Location _location = Location();
  final List<LatLng> _positions = [];

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  // Vérifie et demande les permissions de localisation
  Future<void> _checkLocationPermission() async {
    bool hasPermission = await LocationPermissionHandler()
        .checkAndRequestLocationPermission(context);
    print(hasPermission);

    if (hasPermission) {
      _startTracking();
    } else {
      // Si l'utilisateur a refusé les permissions, afficher un message ou ne pas démarrer le suivi
    }
  }

  // Démarre le suivi de la position GPS
  Future<void> _startTracking() async {
    // Récupère la position initiale
    _currentPosition = await _location.getLocation();
    print(_currentPosition);

    // Écoute les changements de position en temps réel
    _location.onLocationChanged.listen((LocationData newPosition) {
      setState(() {
        _currentPosition = newPosition;
        _positions.add(LatLng(newPosition.latitude!, newPosition.longitude!));
      });
      _savePosition(
          newPosition); // Sauvegarde la position dans Firestore ou autre
    });
  }

  // Sauvegarde la position dans la base de données (Firestore, etc.)
  Future<void> _savePosition(LocationData position) async {
    // Ajoute ici ta logique pour sauvegarder les positions des utilisateurs
    // Par exemple, enregistrer dans Firestore
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? const Center(
              child:
                  CircularProgressIndicator()) // Si la position n'est pas encore disponible
          : GoogleMap(
              scrollGesturesEnabled: widget.isInteractive,
              onMapCreated: (controller) => _controller = controller,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                    _currentPosition!.latitude!, _currentPosition!.longitude!),
                zoom: 15, // Zoom de départ, ajusté à la position actuelle
              ),
              myLocationButtonEnabled: false,
              markers: _positions.map((position) {
                return Marker(
                  markerId: MarkerId(position.toString()),
                  position: position,
                );
              }).toSet(),
            ),

      // Affiche le bouton si la carte est interactive
      floatingActionButton: widget.isInteractive
          ? FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _checkLocationPermission,
              child: const Icon(Icons.refresh, color: Colors.black),
            )
          : null,
    );
  }
}
