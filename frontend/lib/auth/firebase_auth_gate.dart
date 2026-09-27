import 'package:flutter/material.dart';

import '../providers/session_provider.dart';
import '../screens/auth/login_screen.dart';

class FirebaseAuthGate extends StatefulWidget {
  final Widget authenticatedChild;

  const FirebaseAuthGate({super.key, required this.authenticatedChild});

  @override
  State<FirebaseAuthGate> createState() => _FirebaseAuthGateState();
}

class _FirebaseAuthGateState extends State<FirebaseAuthGate> {
  late final SessionProvider _sessionProvider;

  @override
  void initState() {
    super.initState();

    _sessionProvider = SessionProvider();
    _sessionProvider.addListener(_onSessionChanged);

    _initializeSession();
  }

  Future<void> _initializeSession() async {
    await _sessionProvider.initialize();
  }

  void _onSessionChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _sessionProvider.removeListener(_onSessionChanged);
    _sessionProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _sessionProvider.status;

    if (status == SessionStatus.loading) {
      return const _AuthLoadingScreen();
    }

    if (status == SessionStatus.error) {
      return _AuthErrorScreen(
        message:
            _sessionProvider.error ??
            'Authentication session could not be initialized.',
        onRetry: () async {
          await _sessionProvider.refresh();
        },
      );
    }

    if (status == SessionStatus.signedOut) {
      return const LoginScreen();
    }

    if (status == SessionStatus.onboarding) {
      return widget.authenticatedChild;
    }

    if (status == SessionStatus.authenticated) {
      return widget.authenticatedChild;
    }

    return const _AuthLoadingScreen();
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _AuthErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AuthErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 44,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Authentication initialization failed',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      message,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
