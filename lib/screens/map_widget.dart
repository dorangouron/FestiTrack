import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:festitrack/models/participant_model.dart';
import 'package:festitrack/models/event_model.dart';

class MapWidget extends StatefulWidget {
  final String eventId;

  const MapWidget({super.key, required this.eventId});

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _controller;
  final Map<String, List<LatLng>> _participantPositions = {}; // Positions des participants

  @override
  void initState() {
    super.initState();
    _listenToFirestoreUpdates(); // Écoute les mises à jour de Firestore
  }

  // Écoute les mises à jour de la base de données Firestore en temps réel
  void _listenToFirestoreUpdates() {
    FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _participantPositions.clear(); // Réinitialise les positions des participants

          final eventData = snapshot.data() as Map<String, dynamic>;
          Event event = Event.fromMap(eventData);

          for (Participant participant in event.participants) {
            List<LatLng> positions = participant.gpsPoints
                .map((gpsPoint) => LatLng(gpsPoint.latitude, gpsPoint.longitude))
                .toList();
            _participantPositions[participant.id] = positions;
          }

          // Mise à jour de la caméra pour afficher toutes les positions
          _zoomToFitPositions();
        });
      }
    });
  }

  // Fonction pour zoomer et ajuster la caméra afin que toutes les positions soient visibles
  void _zoomToFitPositions() {
    if (_participantPositions.isEmpty) return;

    // Crée une "boîte" de limites (LatLngBounds) qui inclut toutes les positions
    LatLngBounds bounds;
    List<LatLng> allPositions = [];

    _participantPositions.forEach((participantId, positions) {
      allPositions.addAll(positions);
    });

    if (allPositions.length == 1) {
      // S'il n'y a qu'une seule position, centre la carte sur cette position
      bounds = LatLngBounds(
        southwest: allPositions[0],
        northeast: allPositions[0],
      );
    } else {
      // Trouve les positions "sud-ouest" et "nord-est" qui couvrent toutes les positions
      LatLng southwest = allPositions.reduce((a, b) => LatLng(
          a.latitude < b.latitude ? a.latitude : b.latitude,
          a.longitude < b.longitude ? a.longitude : b.longitude));
      LatLng northeast = allPositions.reduce((a, b) => LatLng(
          a.latitude > b.latitude ? a.latitude : b.latitude,
          a.longitude > b.longitude ? a.longitude : b.longitude));

      bounds = LatLngBounds(southwest: southwest, northeast: northeast);
    }

    // Appliquer les bounds à la caméra
    _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50)); // 50 pour padding
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: (controller) {
          _controller = controller;
          if (_participantPositions.isNotEmpty) {
            _zoomToFitPositions(); // Ajuste la carte dès sa création
          }
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(0.0, 0.0), // Par défaut
          zoom: 15,
        ),
        myLocationButtonEnabled: false,
        markers: _buildMarkers(),
        polylines: _buildPolylines(),
      ),
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    _participantPositions.forEach((participantId, positions) {
      if (positions.isNotEmpty) {
        var position = positions.last; // Utilise la dernière position

        markers.add(Marker(
          markerId: MarkerId('$participantId-${position.latitude}-${position.longitude}'),
          position: position,
        ));
      }
    });

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    Set<Polyline> polylines = {};

    _participantPositions.forEach((participantId, positions) {
      if (positions.length > 1) {
        polylines.add(Polyline(
          polylineId: PolylineId(participantId),
          points: positions,
          color: Colors.blue,
          width: 4,
          jointType: JointType.round,
          endCap: Cap.roundCap
        ));
      }
    });

    return polylines;
  }
}
