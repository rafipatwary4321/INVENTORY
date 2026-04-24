import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// Holds Firebase auth user + Firestore profile (`users/{uid}`).
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, this._userService) {
    _authSub = _authService.authStateChanges().listen(_onAuthUserChanged);
  }

  final AuthService _authService;
  final UserService _userService;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  User? firebaseUser;
  AppUser? appUser;
  bool loading = true;
  String? errorMessage;

  bool get isLoggedIn => firebaseUser != null;

  Future<void> _onAuthUserChanged(User? user) async {
    firebaseUser = user;
    await _profileSub?.cancel();
    _profileSub = null;
    if (user == null) {
      appUser = null;
      loading = false;
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    await _userService.ensureUserDocument(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
    );
    _profileSub = _userService.userStream(user.uid).listen((profile) {
      appUser = profile;
      loading = false;
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    errorMessage = null;
    loading = true;
    notifyListeners();
    try {
      await _authService.signIn(email, password);
    } catch (e) {
      errorMessage = e.toString();
      loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() => _authService.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
