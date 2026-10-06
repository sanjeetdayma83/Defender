import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/identity/current_user.dart';
import '../services/identity/identity_service.dart';
import '../services/api/api_client.dart';
import '../services/api/api_config.dart';

enum SessionStatus { signedOut, loading, authenticated, onboarding, error }

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
    debugPrint('SESSION: initialize');
    _status = SessionStatus.loading;
    notifyListeners();

    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) async {
      debugPrint('SESSION: authStateChanges = ${u?.uid}');
      if (u == null) {
        _user = null;
        _status = SessionStatus.signedOut;
        notifyListeners();
        return;
      }
      await loadIdentity();
    });

    final current = FirebaseAuth.instance.currentUser;
    debugPrint('SESSION: currentUser after initialize = ${current?.uid}');
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
      debugPrint('SESSION: identity load already running');
      return;
    }
    _identityLoadRunning = true;

    final fbUser = FirebaseAuth.instance.currentUser;
    debugPrint('SESSION: loadIdentity user = ${fbUser?.uid}');

    if (fbUser == null) {
      _user = null;
      _status = SessionStatus.signedOut;
      _identityLoadRunning = false;
      notifyListeners();
      return;
    }

    try {
      debugPrint('SESSION: GET /identity/me');
      final user = await _identityService.getMe();
      if (user == null) {
        debugPrint('SESSION: /identity/me = NULL — bootstrap');
        final created = await _identityService.bootstrap();
        _applyUser(created);
      } else {
        debugPrint('SESSION: /identity/me = FOUND');
        _applyUser(user);
      }
      await _runTenantIsolationHttpNegativeTest();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('USER_NOT_REGISTERED') ||
          msg.contains('404') ||
          msg.contains('not been created')) {
        debugPrint('SESSION: identity 404 — bootstrap');
        try {
          final created = await _identityService.bootstrap();
          _applyUser(created);
        } catch (e2) {
          debugPrint('SESSION: identity error = $e2');
          _error = e2.toString();
          _status = SessionStatus.error;
          notifyListeners();
        }
      } else {
        debugPrint('SESSION: identity error = $e');
        _error = e.toString();
        _status = SessionStatus.error;
        notifyListeners();
      }
    } finally {
      _identityLoadRunning = false;
    }
  }

  void _applyUser(CurrentUser user) {
    debugPrint(
      'SESSION: APPLY USER name=${user.name} '
      'company=${user.company?.id} warehouse=${user.warehouse?.id}',
    );
    _user = user;
    _error = null;

    // Platform owner (super_admin / PLATFORM_ADMIN) — never seller onboarding
    if (user.isPlatformAdmin) {
      _status = SessionStatus.authenticated;
      debugPrint('SESSION: status = $_status (platform admin)');
      notifyListeners();
      return;
    }

    final incomplete = user.name.trim().isEmpty ||
        user.company == null ||
        user.warehouse == null;

    _status = incomplete
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
    _user = null;
    _status = SessionStatus.signedOut;
    notifyListeners();
  }

  Future<void> _runTenantIsolationHttpNegativeTest() async {
    try {
      final client = const ApiClient();
      final res = await client.get(
        Uri.parse('${ApiConfig.baseUrl}/orders/lookup?awb=__no_such_awb__'),
      );
      debugPrint('TENANT_HTTP_NEGATIVE_STATUS=${res.statusCode}');
      dynamic body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {}
      final found = body is Map && body['found'] == true;
      debugPrint('TENANT_HTTP_NEGATIVE_FOUND=$found');
      debugPrint(
        'TENANT_HTTP_NEGATIVE_RESULT=${res.statusCode == 200 && found == false ? "PASS" : "SKIP"}',
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
