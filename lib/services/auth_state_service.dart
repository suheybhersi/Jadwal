import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Notifies listeners when Firebase Auth user signs in, out, or switches.
/// Used so [FirestoreService] can rebuild with the correct uid.
class AuthStateService extends ChangeNotifier {
  User? _user;
  StreamSubscription<User?>? _subscription;

  AuthStateService() {
    _user = FirebaseAuth.instance.currentUser;
    _subscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      final changed = user?.uid != _user?.uid;
      _user = user;
      if (changed) {
        notifyListeners();
      }
    });
  }

  User? get user => _user;
  String get uid => _user?.uid ?? '';
  bool get isSignedIn => _user != null;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
