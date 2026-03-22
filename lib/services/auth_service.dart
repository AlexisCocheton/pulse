import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  /// Inscription → retourne le uid Firebase
  Future<String> signUp(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user!.uid;
  }

  /// Connexion avec email/mot de passe
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // Compatibilité avec l'ancien code (no-op)
  Future<void> setCurrentUserId(String userId) async {}
}
