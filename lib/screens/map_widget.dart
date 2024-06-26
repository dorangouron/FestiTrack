import 'package:festitrack/models/event_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatefulWidget {
  final Event event;

  const MapWidget({super.key, required this.event});

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _controller;
  static const LatLng _franceLatLng = LatLng(46.603354, 1.888334); // Center of France

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        onMapCreated: (controller) => _controller = controller,
        initialCameraPosition: const CameraPosition(
          target: _franceLatLng,
          zoom: 5, // Adjust the zoom level as needed
        ),
        myLocationEnabled: false, // Disable the my location feature
        myLocationButtonEnabled: false, // Disable the my location button
      ),
    );
  }
}
