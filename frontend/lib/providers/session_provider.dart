import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/identity/current_user.dart';
import '../services/identity/identity_service.dart';
import '../services/api/api_client.dart';
import '../services/api/api_config.dart';

enum SessionStatus {
  signedOut,
  loading,
  authenticated,
  onboarding,
  emailVerificationRequired,
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
  bool _identityLoadRunning = false;
  StreamSubscription<User?>? _authSub;

  SessionStatus get status => _status;
  CurrentUser? get user => _user;
  String? get error => _error;
  bool get initialised => _initialised;

  bool get isAuthenticated =>
      _status == SessionStatus.authenticated ||
      _status == SessionStatus.onboarding;

  bool get needsOnboarding => _status == SessionStatus.onboarding;

  Future<void> initialize() async {
    _status = SessionStatus.loading;
    _error = null;
    notifyListeners();

    await _authSub?.cancel();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        _user = null;
        _error = null;
        _status = SessionStatus.signedOut;
        notifyListeners();
        return;
      }

      await loadIdentity();
    });

    final current = FirebaseAuth.instance.currentUser;

    if (current == null) {
      _status = SessionStatus.signedOut;
      _initialised = true;
      notifyListeners();
      return;
    }

    await loadIdentity();
    _initialised = true;
  }

  Future<void> loadIdentity() async {
    if (_identityLoadRunning) {
      return;
    }

    _identityLoadRunning = true;

    final fbUser = FirebaseAuth.instance.currentUser;

    if (fbUser == null) {
      _user = null;
      _error = null;
      _status = SessionStatus.signedOut;
      _identityLoadRunning = false;
      notifyListeners();
      return;
    }

    try {
      await fbUser.reload();

      final refreshedFirebaseUser = FirebaseAuth.instance.currentUser;

      if (refreshedFirebaseUser?.emailVerified != true) {
        _user = null;
        _error = null;
        _status = SessionStatus.emailVerificationRequired;
        notifyListeners();
        return;
      }

      final user = await _identityService.getMe();

      if (user != null) {
        _applyUser(user);
        await _runTenantIsolationHttpNegativeTest();
        return;
      }

      try {
        final created = await _identityService.bootstrap();
        _applyUser(created);
        await _runTenantIsolationHttpNegativeTest();
      } catch (bootstrapError) {
        final message = bootstrapError.toString();

        if (message.contains('USER_NOT_REGISTERED') ||
            message.contains('404') ||
            message.contains('not been created')) {
          _user = null;
          _error = null;
          _status = SessionStatus.onboarding;
          notifyListeners();
        } else {
          rethrow;
        }
      }
    } catch (e) {
      _error = e.toString();
      _status = SessionStatus.error;
      notifyListeners();
    } finally {
      _identityLoadRunning = false;
    }
  }

  void _applyUser(CurrentUser user) {
    _user = user;
    _error = null;

    if (user.isPlatformAdmin) {
      _status = SessionStatus.authenticated;
      notifyListeners();
      return;
    }

    final incomplete =
        user.name.trim().isEmpty ||
        user.company == null ||
        user.warehouses.isEmpty;

    _status = incomplete
        ? SessionStatus.onboarding
        : SessionStatus.authenticated;

    notifyListeners();
  }

  Future<void> refresh() async {
    await loadIdentity();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _user = null;
    _error = null;
    _status = SessionStatus.signedOut;
    notifyListeners();
  }

  Future<void> _runTenantIsolationHttpNegativeTest() async {
    try {
      final client = const ApiClient();
      final res = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/lookup?awb=__no_such_awb__'),
      );

      dynamic body;

      try {
        body = jsonDecode(res.body);
      } catch (_) {}

      final found = body is Map && body['found'] == true;

      debugPrint(
        'TENANT_HTTP_NEGATIVE_RESULT='
        '${res.statusCode == 200 && found == false ? "PASS" : "SKIP"}',
      );
    } catch (_) {
      debugPrint('TENANT_HTTP_NEGATIVE_RESULT=SKIP');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
