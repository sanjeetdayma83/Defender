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
  bool _identityLoading = false;
  bool _tenantE2eNegativeRan = false;

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

    debugPrint('SESSION: loadIdentity user = ${firebaseUser?.uid ?? "NULL"}');

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

      debugPrint('SESSION: /identity/me = ${user == null ? "NULL" : "FOUND"}');

      if (user == null) {
        debugPrint('SESSION: bootstrapping identity');

        final created = await _identityService.bootstrap();

        debugPrint('SESSION: bootstrap success');

        _applyUser(created);
        return;
      }

      _applyUser(user);
      await _runTenantIsolationHttpNegativeTest();
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

  Future<void> _runTenantIsolationHttpNegativeTest() async {
    if (_tenantE2eNegativeRan) {
      return;
    }

    _tenantE2eNegativeRan = true;

    try {
      final api = const ApiClient();

      final response = await api.post(
        Uri.parse('${ApiConfig.baseUrl}/scan/lookup'),
        body: <String, String>{
          'barcode': 'TESTAWB-LD-OTHER-001',
        },
      );

      debugPrint(
        'TENANT_HTTP_NEGATIVE_STATUS=${response.statusCode}',
      );

      try {
        final safeStatusBody = jsonDecode(response.body);

        if (safeStatusBody is Map<String, dynamic>) {
          final safeMessage = safeStatusBody['message'];
          final safeCode = safeStatusBody['code'];

          if (safeCode != null) {
            debugPrint(
              'TENANT_HTTP_NEGATIVE_CODE=$safeCode',
            );
          }

          if (safeMessage != null) {
            debugPrint(
              'TENANT_HTTP_NEGATIVE_MESSAGE=$safeMessage',
            );
          }
        }
      } catch (_) {
        debugPrint(
          'TENANT_HTTP_NEGATIVE_MESSAGE=UNPARSEABLE_RESPONSE',
        );
      }

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];

          final found = data is Map<String, dynamic>
              ? data['found'] == true
              : null;

          debugPrint(
            'TENANT_HTTP_NEGATIVE_FOUND=$found',
          );

          final passed =
              response.statusCode == 200 && found == false;

          debugPrint(
            'TENANT_HTTP_NEGATIVE_RESULT=${passed ? "PASS" : "FAIL"}',
          );
        } else {
          debugPrint('TENANT_HTTP_NEGATIVE_RESULT=FAIL');
        }
      } catch (_) {
        debugPrint('TENANT_HTTP_NEGATIVE_RESULT=FAIL');
      }
    } catch (_) {
      debugPrint('TENANT_HTTP_NEGATIVE_REQUEST=FAILED');
      debugPrint('TENANT_HTTP_NEGATIVE_RESULT=FAIL');
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


