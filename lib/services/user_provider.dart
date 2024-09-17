import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoading => _isLoading;

  UserProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = FirebaseAuth.instance.currentUser;
    } catch (e) {
      print('Error loading user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Configure l'écouteur après l'initialisation
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setUser(user);
    });
  }

  void setUser(User? user) {
    if (_user?.uid != user?.uid) {
      _user = user;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      setUser(userCredential.user);
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      setUser(userCredential.user);
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      setUser(null);
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error resetting password: $e');
      rethrow;
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (_user != null) {
        await _user!
            .updateProfile(displayName: displayName, photoURL: photoURL);
        // Recharger l'utilisateur pour obtenir les informations mises à jour
        await _user!.reload();
        setUser(FirebaseAuth.instance.currentUser);
      }
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  bool get isAuthenticated => _user != null;
}
