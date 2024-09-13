import 'dart:async';
import 'dart:ui' as ui;

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
  final Map<String, Color> _participantColors = {};
  final Map<String, BitmapDescriptor> _participantIcons = {};
  Set<Marker> _markers = {};
  bool _initialZoomDone = false;

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
                .map(
                    (gpsPoint) => LatLng(gpsPoint.latitude, gpsPoint.longitude))
                .toList();
            _participantPositions[participant.id] = positions;
          }
        });
        _buildCustomMarkers();
        if (!_initialZoomDone) {
          _zoomToFitPositions();
          _initialZoomDone = true;
        }
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

  Future<BitmapDescriptor> _createCircleMarker(Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final double radius = 10.0;

    canvas.drawCircle(Offset(radius, radius), radius, paint);

    final img = await pictureRecorder
        .endRecording()
        .toImage(radius.toInt() * 2, radius.toInt() * 2);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _buildCustomMarkers() async {
    Set<Marker> markers = {};

    for (var entry in _participantPositions.entries) {
      String participantId = entry.key;
      List<LatLng> positions = entry.value;

      if (positions.isNotEmpty) {
        var position = positions.last;
        Color color = _getParticipantColor(participantId);

        if (!_participantIcons.containsKey(participantId)) {
          _participantIcons[participantId] = await _createCircleMarker(color);
        }

        markers.add(Marker(
          markerId: MarkerId(
              '$participantId-${position.latitude}-${position.longitude}'),
          position: position,
          icon: _participantIcons[participantId]!,
        ));
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  Color _getParticipantColor(String participantId) {
    if (!_participantColors.containsKey(participantId)) {
      _participantColors[participantId] =
          Colors.primaries[_participantColors.length % Colors.primaries.length];
    }
    return _participantColors[participantId]!;
  }

  Set<Polyline> _buildGradientPolylines() {
    Set<Polyline> polylines = {};

    _participantPositions.forEach((participantId, positions) {
      if (positions.length > 1) {
        Color baseColor = _getParticipantColor(participantId);
        List<Polyline> gradientPolylines = [];

        for (int i = 0; i < positions.length - 1; i++) {
          double opacity = i / (positions.length - 1);
          Color color = baseColor.withOpacity(opacity);

          gradientPolylines.add(Polyline(
            polylineId: PolylineId('$participantId-$i'),
            points: [positions[i], positions[i + 1]],
            color: color,
            width: 4,
            jointType: JointType.round,
            endCap: Cap.roundCap,
            startCap: Cap.roundCap,
          ));
        }

        polylines.addAll(gradientPolylines);
      }
    });

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) {
            setState(() {
              _controller = controller;
            });
            if (_participantPositions.isNotEmpty) {
              _zoomToFitPositions();
              _buildCustomMarkers();
            }
          },
          initialCameraPosition: const CameraPosition(
            target: LatLng(47.58, -3.08),
            zoom: 15,
          ),
          myLocationButtonEnabled: false,
          markers: _markers,
          polylines: _buildGradientPolylines(),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: _zoomToFitPositions,
            child: Icon(Icons.center_focus_strong),
          ),
        ),
      ],
    );
  }
}
