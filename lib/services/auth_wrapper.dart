import 'package:festitrack/screens/home_screen.dart';
import 'package:festitrack/screens/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'user_provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Affiche le chargement tant que Firebase n'a pas répondu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si l'utilisateur est connecté, met à jour le UserProvider
        if (snapshot.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<UserProvider>(context, listen: false).setUser(snapshot.data);
          });
          return const HomeScreen();
        }

        // Si l'utilisateur n'est pas connecté, affiche l'écran de connexion
        return const SignInScreen();
      },
    );
  }
}
