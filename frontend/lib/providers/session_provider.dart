import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/identity/current_user.dart';
import '../services/identity/identity_service.dart';

enum SessionStatus { signedOut, loading, authenticated, onboarding, error }

class SessionProvider extends ChangeNotifier {
  final IdentityService _identityService;

  SessionProvider({IdentityService? identityService})
    : _identityService = identityService ?? IdentityService();

  SessionStatus _status = SessionStatus.loading;
  CurrentUser? _user;
  String? _error;

  bool _initialised = false;
  bool _identityLoading = false;

  StreamSubscription<User?>? _authSubscription;

  SessionStatus get status => _status;

  CurrentUser? get user => _user;

  String? get error => _error;

  bool get initialised => _initialised;

  bool get isAuthenticated =>
      _status == SessionStatus.authenticated ||
      _status == SessionStatus.onboarding;

  bool get needsOnboarding => _status == SessionStatus.onboarding;

  Future<void> initialize() async {
    if (_initialised) {
      return;
    }

    _initialised = true;
    _status = SessionStatus.loading;
    _error = null;
    notifyListeners();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthStateChanged,
      onError: _handleAuthStreamError,
    );
  }

  Future<void> _handleAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _error = null;
      _status = SessionStatus.signedOut;
      notifyListeners();
      return;
    }

    await loadIdentity();
  }

  void _handleAuthStreamError(Object error) {
    _user = null;
    _error = 'Firebase authentication state error: $error';
    _status = SessionStatus.error;
    notifyListeners();
  }

  Future<void> loadIdentity() async {
    if (_identityLoading) {
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      _user = null;
      _error = null;
      _status = SessionStatus.signedOut;
      notifyListeners();
      return;
    }

    _identityLoading = true;

    _status = SessionStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final user = await _identityService.getMe();

      if (user == null) {
        final created = await _identityService.bootstrap();
        _applyUser(created);
        return;
      }

      _applyUser(user);
    } on FirebaseAuthException catch (error) {
      _user = null;
      _error = error.message ?? 'Authentication session expired.';
      _status = SessionStatus.error;
      notifyListeners();
    } catch (error) {
      _error = error.toString();
      _status = SessionStatus.error;
      notifyListeners();
    } finally {
      _identityLoading = false;
    }
  }

  void _applyUser(CurrentUser user) {
    _user = user;
    _error = null;

    final profileIncomplete =
        user.name.trim().isEmpty ||
        user.company == null ||
        user.warehouse == null;

    _status = profileIncomplete
        ? SessionStatus.onboarding
        : SessionStatus.authenticated;

    notifyListeners();
  }

  Future<void> refresh() async {
    await loadIdentity();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    super.dispose();
  }
}
