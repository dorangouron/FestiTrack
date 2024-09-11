import 'dart:async';

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
  final Map<String, List<LatLng>> _participantPositions = {};
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;

  @override
  void initState() {
    super.initState();
    _listenToFirestoreUpdates();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _listenToFirestoreUpdates() {
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _participantPositions.clear();

          final eventData = snapshot.data() as Map<String, dynamic>;
          Event event = Event.fromMap(eventData);

          for (Participant participant in event.participants) {
            List<LatLng> positions = participant.gpsPoints
                .map((gpsPoint) => LatLng(gpsPoint.latitude, gpsPoint.longitude))
                .toList();
            _participantPositions[participant.id] = positions;
          }
        });

        _zoomToFitPositions();
      }
    });
  }

  void _zoomToFitPositions() {
    if (_participantPositions.isEmpty || _controller == null) return;

    LatLngBounds bounds;
    List<LatLng> allPositions = [];

    _participantPositions.forEach((participantId, positions) {
      allPositions.addAll(positions);
    });

    if (allPositions.length == 1) {
      bounds = LatLngBounds(
        southwest: allPositions[0],
        northeast: allPositions[0],
      );
    } else {
      LatLng southwest = allPositions.reduce((a, b) => LatLng(
          a.latitude < b.latitude ? a.latitude : b.latitude,
          a.longitude < b.longitude ? a.longitude : b.longitude));
      LatLng northeast = allPositions.reduce((a, b) => LatLng(
          a.latitude > b.latitude ? a.latitude : b.latitude,
          a.longitude > b.longitude ? a.longitude : b.longitude));

      bounds = LatLngBounds(southwest: southwest, northeast: northeast);
    }

    _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (controller) {
        setState(() {
          _controller = controller;
        });
        if (_participantPositions.isNotEmpty) {
          _zoomToFitPositions();
        }
      },
      initialCameraPosition: const CameraPosition(
        target: LatLng(0.0, 0.0),
        zoom: 15,
      ),
      myLocationButtonEnabled: false,
      markers: _buildMarkers(),
      polylines: _buildPolylines(),
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};

    _participantPositions.forEach((participantId, positions) {
      if (positions.isNotEmpty) {
        var position = positions.last;

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