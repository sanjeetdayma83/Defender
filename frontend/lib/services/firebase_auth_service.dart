import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  FirebaseAuthService._();

  static final FirebaseAuthService instance = FirebaseAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createAccountWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final name = displayName?.trim();

    if (credential.user != null && name != null && name.isNotEmpty) {
      await credential.user!.updateDisplayName(name);
      await credential.user!.reload();
    }

    return credential;
  }

  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider();

    provider.setCustomParameters({'prompt': 'select_account'});

    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
      return;
    }

    await _auth.signInWithProvider(provider);
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserCredential?> getRedirectResult() async {
    if (!kIsWeb) {
      return null;
    }

    return _auth.getRedirectResult();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
