import 'package:festitrack/screens/home_screen.dart';
import 'package:festitrack/screens/sign_in_screen.dart';
import 'package:festitrack/services/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // Utilise addPostFrameCallback pour mettre à jour le UserProvider après la fin du build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<UserProvider>(context, listen: false).setUser(snapshot.data);
          });
          return const HomeScreen();
        } else {
          return const SignInScreen();
        }
      },
    );
  }
}
