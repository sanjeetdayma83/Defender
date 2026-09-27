import 'dart:async';

import 'package:flutter/material.dart';

import '../config/clerk_config.dart';
import '../screens/auth/login_screen.dart';
import '../services/clerk_web_bridge.dart';

class ClerkAuthGate extends StatefulWidget {
  final Widget authenticatedChild;

  const ClerkAuthGate({super.key, required this.authenticatedChild});

  @override
  State<ClerkAuthGate> createState() => _ClerkAuthGateState();
}

class _ClerkAuthGateState extends State<ClerkAuthGate> {
  Timer? _authTimer;

  bool _loading = true;
  bool _signedIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!ClerkConfig.isConfigured) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'CLERK_PUBLISHABLE_KEY is not configured.';
      });

      return;
    }

    try {
      await ClerkWebBridge.initialize(ClerkConfig.publishableKey);

      final signedIn = ClerkWebBridge.isSignedIn;

      if (!mounted) return;

      setState(() {
        _loading = false;
        _signedIn = signedIn;
      });

      _authTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
        _checkAuth();
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _checkAuth() {
    if (!mounted) return;

    final signedIn = ClerkWebBridge.isSignedIn;

    if (signedIn != _signedIn) {
      setState(() {
        _signedIn = signedIn;
      });
    }
  }

  @override
  void dispose() {
    _authTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _AuthLoadingScreen();
    }

    if (_error != null) {
      return _AuthErrorScreen(
        message: _error!,
        onRetry: () {
          setState(() {
            _loading = true;
            _error = null;
          });

          _initialize();
        },
      );
    }

    if (!_signedIn) {
      return const LoginScreen();
    }

    return widget.authenticatedChild;
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(),
          ),
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 42,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Authentication initialization failed',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(message),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
