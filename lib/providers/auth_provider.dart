import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../core/context/business_scope.dart';
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
  static const _demoOwnerUid = 'demo-owner';
  static const _demoStaffUid = 'demo-staff';
  bool _demoLoggedIn = false;
  UserRole _demoRole = UserRole.owner;
  String _businessId = AppConstants.demoBusinessId;
  bool loading = true;
  String? errorMessage;

  bool get isFirebaseEnabled => _authService.isFirebaseEnabled;
  bool get isLoggedIn =>
      isFirebaseEnabled ? firebaseUser != null : _demoLoggedIn;
  String get businessId => _businessId;
  bool get isOwner => appUser?.role == UserRole.owner;
  bool get isAdmin => appUser?.isAdmin ?? false;
  bool get canManageUsers => isOwner;
  bool get canManageBusinessSettings => isOwner;
  bool get canDeleteProducts => isOwner || isAdmin;
  bool get canViewProfitLoss => isOwner || isAdmin;
  String? get activeUid =>
      isFirebaseEnabled
          ? firebaseUser?.uid
          : (_demoLoggedIn
              ? (_demoRole == UserRole.staff ? _demoStaffUid : _demoOwnerUid)
              : null);

  Future<void> _onAuthUserChanged(User? user) async {
    firebaseUser = user;
    await _profileSub?.cancel();
    _profileSub = null;
    if (user == null) {
      appUser = null;
      _businessId = AppConstants.demoBusinessId;
      BusinessScope.setBusinessId(_businessId);
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
      final membership = await _userService.findMembership(user.uid);
      if (membership == null) {
        final businessId = 'biz_${user.uid}';
        await _userService.ensureBusinessDefaults(
          businessId: businessId,
          ownerId: user.uid,
        );
        await _userService.ensureUserMembership(
          businessId: businessId,
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? user.email?.split('@').first ?? 'Owner',
          role: UserRole.owner.firestoreValue,
          isActive: true,
        );
        _businessId = businessId;
      } else {
        _businessId = membership.businessId;
      }
      BusinessScope.setBusinessId(_businessId);
      _profileSub = _userService.userStream(_businessId, user.uid).listen(
        (profile) {
          appUser = profile;
          if ((profile?.businessId ?? '').isNotEmpty) {
            _businessId = profile!.businessId;
            BusinessScope.setBusinessId(_businessId);
          }
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
          final demoEmail = _authService.activeDemoEmail ?? AuthService.demoOwnerEmail;
          _demoRole = demoEmail == AuthService.demoStaffEmail
              ? UserRole.staff
              : UserRole.owner;
          appUser = AppUser(
            uid: _demoRole == UserRole.staff ? _demoStaffUid : _demoOwnerUid,
            email: demoEmail,
            role: _demoRole,
            displayName: _demoRole == UserRole.staff ? 'Demo Staff' : 'Demo Owner',
            businessId: AppConstants.demoBusinessId,
          );
          _businessId = AppConstants.demoBusinessId;
          BusinessScope.setBusinessId(_businessId);
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
      _businessId = AppConstants.demoBusinessId;
      BusinessScope.setBusinessId(_businessId);
      loading = false;
      notifyListeners();
    }
  }

  void setDemoRole(UserRole role) {
    if (isFirebaseEnabled || !_demoLoggedIn || appUser == null) return;
    _demoRole = role;
    appUser = AppUser(
      uid: role == UserRole.staff ? _demoStaffUid : _demoOwnerUid,
      email: role == UserRole.staff
          ? AuthService.demoStaffEmail
          : AuthService.demoOwnerEmail,
      role: role,
      displayName: role == UserRole.staff ? 'Demo Staff' : 'Demo Owner',
      businessId: AppConstants.demoBusinessId,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
