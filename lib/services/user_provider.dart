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
    await loadUser();
    // Listen to auth state changes after initial load
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setUser(user);
    });
  }

  void setUser(User? user) {
    _user = user;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUser() async {
    try {
      _user = FirebaseAuth.instance.currentUser;
    } catch (e) {
      print('Error loading user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    setUser(null);
  }
}