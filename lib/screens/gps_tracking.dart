import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GpsTracking extends StatefulWidget {
  final String eventId;

  const GpsTracking({super.key, required this.eventId});

  @override
  _GpsTrackingState createState() => _GpsTrackingState();
}

class _GpsTrackingState extends State<GpsTracking> {
  GoogleMapController? _controller;
  Position? _currentPosition;
  final List<LatLng> _positions = [];

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );

    Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) async {
        setState(() {
          _currentPosition = position;
          _positions.add(LatLng(position.latitude, position.longitude));
        });
        await _savePosition(position);
            },
    );

    // Timer to ensure positions are collected every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (Timer t) async {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _positions.add(LatLng(position.latitude, position.longitude));
      });
      await _savePosition(position);
    });
  }

  Future<void> _savePosition(Position position) async {
    await FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('positions')
        .add({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tracking")),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) => _controller = controller,
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                zoom: 15,
              ),
              markers: _positions.map((position) {
                return Marker(
                  markerId: MarkerId(position.toString()),
                  position: position,
                );
              }).toSet(),
            ),
    );
  }
}
