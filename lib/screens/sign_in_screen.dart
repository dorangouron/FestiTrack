import 'package:festitrack/models/app_colors.dart';
import 'package:festitrack/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> _signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final User? user = userCredential.user;
    return user;
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
              "Bienvenue sur FestiTrack",
              style: TextStyle(fontSize: 24,color: AppColors.secondaryColor,fontWeight: FontWeight.bold),
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