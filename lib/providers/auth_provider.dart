import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// Holds Firebase auth user + Firestore profile (`users/{uid}`).
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, this._userService) {
    if (_authService.isFirebaseEnabled) {
      _authSub = _authService.authStateChanges().listen(_onAuthUserChanged);
    } else {
      loading = false;
    }
  }

  final AuthService _authService;
  final UserService? _userService;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;

  User? firebaseUser;
  AppUser? appUser;
  static const _demoUid = 'demo-admin';
  bool _demoLoggedIn = false;
  bool loading = true;
  String? errorMessage;

  bool get isFirebaseEnabled => _authService.isFirebaseEnabled;
  bool get isLoggedIn =>
      isFirebaseEnabled ? firebaseUser != null : _demoLoggedIn;
  bool get isAdmin =>
      isFirebaseEnabled ? appUser?.role == UserRole.admin : _demoLoggedIn;
  String? get activeUid =>
      isFirebaseEnabled ? firebaseUser?.uid : (_demoLoggedIn ? _demoUid : null);

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
    errorMessage = null;
    notifyListeners();
    try {
      if (_userService == null) {
        loading = false;
        notifyListeners();
        return;
      }
      await _userService.ensureUserDocument(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? user.email?.split('@').first ?? 'User',
      );
      _profileSub = _userService.userStream(user.uid).listen(
        (profile) {
          appUser = profile;
          loading = false;
          notifyListeners();
        },
        onError: (Object error, StackTrace stackTrace) {
          errorMessage = error.toString();
          loading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      errorMessage = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    errorMessage = null;
    loading = true;
    notifyListeners();
    try {
      await _authService.signIn(email, password);
      if (!isFirebaseEnabled) {
        _demoLoggedIn = _authService.isDemoLoggedIn;
        if (_demoLoggedIn) {
          appUser = AppUser(
            uid: _demoUid,
            email: AuthService.demoEmail,
            role: UserRole.admin,
            displayName: 'Demo Admin',
          );
        }
        loading = false;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = e.toString();
      loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    if (!isFirebaseEnabled) {
      _demoLoggedIn = false;
      appUser = null;
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
