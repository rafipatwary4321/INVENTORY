import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around [FirebaseAuth] for tests and single place for auth calls.
class AuthService {
  AuthService({
    required FirebaseAuth? auth,
    required bool firebaseEnabled,
  })  : _auth = auth,
        _firebaseEnabled = firebaseEnabled;

  static const demoEmail = 'admin@inventory.com';
  static const demoPassword = '123456';
  static const demoOwnerEmail = 'owner@inventory.com';
  static const demoStaffEmail = 'staff@inventory.com';

  final FirebaseAuth? _auth;
  final bool _firebaseEnabled;
  bool _demoLoggedIn = false;
  String? _demoEmail;

  bool get isFirebaseEnabled => _firebaseEnabled;
  bool get isDemoLoggedIn => _demoLoggedIn;
  String? get activeDemoEmail => _demoEmail;

  Stream<User?> authStateChanges() {
    if (!_firebaseEnabled || _auth == null) {
      return const Stream<User?>.empty();
    }
    return _auth.authStateChanges();
  }

  User? get currentUser => _auth?.currentUser;

  Future<void> signIn(String email, String password) async {
    if (_firebaseEnabled && _auth != null) {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return;
    }
    final normalized = email.trim().toLowerCase();
    final isDemoMatch = password == demoPassword &&
        (normalized == demoEmail ||
            normalized == demoOwnerEmail ||
            normalized == demoStaffEmail);
    if (isDemoMatch) {
      _demoLoggedIn = true;
      _demoEmail = normalized;
      return;
    }
    throw FirebaseAuthException(
      code: 'invalid-credential',
      message: 'Invalid demo credentials.',
    );
  }

  Future<void> signOut() async {
    if (_firebaseEnabled && _auth != null) {
      await _auth.signOut();
      return;
    }
    _demoLoggedIn = false;
    _demoEmail = null;
  }
}
