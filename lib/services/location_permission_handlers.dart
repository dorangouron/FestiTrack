import 'package:flutter/material.dart';
import 'package:location/location.dart';

class LocationPermissionHandler {
  final Location _location = Location();

  // Vérifie et demande la permission de localisation avec la pop-up
  Future<bool> checkAndRequestLocationPermission(BuildContext context) async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Vérifie si le service de localisation est activé
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      // Demande d'activer la localisation
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        _showServiceDisabledDialog(context);
        return false;
      }
    }

    // Vérifie les permissions de localisation
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      // Demande la permission
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        _showPermissionDeniedDialog(context);
        return false;
      }
    } else if (permissionGranted == PermissionStatus.deniedForever) {
      // L'utilisateur a refusé définitivement, proposer d'ouvrir les paramètres
      _showOpenSettingsDialog(context);
      return false;
    }

    return true; // La permission a été accordée
  }

  // Affiche un message lorsque le service de localisation est désactivé
  void _showServiceDisabledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Service de localisation désactivé'),
          content: const Text(
              'Le service de localisation est désactivé. Veuillez l\'activer pour utiliser cette application.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Affiche une boîte de dialogue si la permission est refusée
  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Accès à la localisation nécessaire'),
          content: const Text(
              'Cette application a besoin d\'accéder à votre localisation pour fonctionner. Veuillez accorder l\'accès.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Demander à nouveau'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _location.requestPermission();
              },
            ),
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Affiche une boîte de dialogue pour ouvrir les paramètres de l'application
  void _showOpenSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Autorisation refusée définitivement'),
          content: const Text(
              'Vous devez activer l\'accès à la localisation dans les paramètres pour utiliser cette fonctionnalité.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Continuer'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _location.requestPermission();
              },
            ),
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
