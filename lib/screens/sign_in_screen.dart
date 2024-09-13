import 'package:festitrack/models/app_colors.dart';
import 'package:festitrack/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        await _createOrUpdateUserDocument(user);
      }

      return user;
    } catch (error) {
      print('Error during Google sign in: $error');
      return null;
    }
  }

  Future<void> _createOrUpdateUserDocument(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    final userData = {
      'displayName': user.displayName,
      'email': user.email,
      'photoURL': user.photoURL,
      'lastSignInTime': FieldValue.serverTimestamp(),
      'searchTerms': _generateSearchTerms(user),
    };

    await userRef.set(userData, SetOptions(merge: true));
  }

  List<String> _generateSearchTerms(User user) {
    final List<String> searchTerms = [];
    if (user.displayName != null) {
      searchTerms.addAll(user.displayName!.toLowerCase().split(' '));
    }
    if (user.email != null) {
      searchTerms.add(user.email!.toLowerCase());
      searchTerms.addAll(user.email!.split('@')[0].toLowerCase().split('.'));
    }
    return searchTerms;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Bienvenue sur FestiTrack",
                style: TextStyle(
                    fontSize: 24,
                    color: AppColors.secondaryColor,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                "Ne perds plus jamais tes potes lors d'un festival !",
                style: TextStyle(color: AppColors.secondaryColor),
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: () async {
              User? user = await _signInWithGoogle();
              if (user != null) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              }
            },
            child: const SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  'Connexion avec Google',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.dominantColor,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
