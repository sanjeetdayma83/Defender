import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/identity/current_user.dart';
import '../services/identity/identity_service.dart';

enum SessionStatus {
  signedOut,
  loading,
  authenticated,
  onboarding,
  error,
}

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

    debugPrint('SESSION: initialize');

    _initialised = true;
    _status = SessionStatus.loading;
    _error = null;
    notifyListeners();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (firebaseUser) async {
        debugPrint(
          'SESSION: authStateChanges = ${firebaseUser?.uid ?? "NULL"}',
        );

        if (firebaseUser == null) {
          _user = null;
          _error = null;
          _status = SessionStatus.signedOut;
          notifyListeners();
          return;
        }

        await loadIdentity();
      },
      onError: (Object error) {
        debugPrint('SESSION: auth stream error = $error');

        _user = null;
        _error = 'Firebase authentication state error: $error';
        _status = SessionStatus.error;
        notifyListeners();
      },
    );

    // Handle an already-existing Firebase session immediately.
    final currentUser = FirebaseAuth.instance.currentUser;

    debugPrint(
      'SESSION: currentUser after initialize = '
      '${currentUser?.uid ?? "NULL"}',
    );

    if (currentUser != null) {
      await loadIdentity();
    } else {
      _status = SessionStatus.signedOut;
      notifyListeners();
    }
  }

  Future<void> loadIdentity() async {
    if (_identityLoading) {
      debugPrint('SESSION: identity load already running');
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;

    debugPrint(
      'SESSION: loadIdentity user = ${firebaseUser?.uid ?? "NULL"}',
    );

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
      debugPrint('SESSION: GET /identity/me');

      final user = await _identityService.getMe();

      debugPrint(
        'SESSION: /identity/me = ${user == null ? "NULL" : "FOUND"}',
      );

      if (user == null) {
        debugPrint('SESSION: bootstrapping identity');

        final created = await _identityService.bootstrap();

        debugPrint('SESSION: bootstrap success');

        _applyUser(created);
        return;
      }

      _applyUser(user);
    } on FirebaseAuthException catch (error) {
      debugPrint('SESSION: Firebase error = $error');

      _user = null;
      _error = error.message ?? 'Authentication session expired.';
      _status = SessionStatus.error;
      notifyListeners();
    } catch (error) {
      debugPrint('SESSION: identity error = $error');

      _error = error.toString();
      _status = SessionStatus.error;
      notifyListeners();
    } finally {
      _identityLoading = false;
    }
  }

  void _applyUser(CurrentUser user) {
    debugPrint(
      'SESSION: APPLY USER '
      'name=${user.name} '
      'company=${user.company?.id} '
      'warehouse=${user.warehouse?.id}',
    );

    _user = user;
    _error = null;

    final profileIncomplete =
        user.name.trim().isEmpty ||
        user.company == null ||
        user.warehouse == null;

    _status = profileIncomplete
        ? SessionStatus.onboarding
        : SessionStatus.authenticated;

    debugPrint('SESSION: status = $_status');

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
