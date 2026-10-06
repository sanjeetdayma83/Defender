import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../../models/identity/current_user.dart';
import '../auth/login_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../saas/saas_portal_screen.dart';

class LDSessionGate extends StatefulWidget {
  const LDSessionGate({super.key});

  @override
  State<LDSessionGate> createState() => _LDSessionGateState();
}

class _LDSessionGateState extends State<LDSessionGate> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SessionProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        switch (session.status) {
          case SessionStatus.loading:
            return const _SessionLoading();

          case SessionStatus.signedOut:
            return const LoginScreen();

          case SessionStatus.error:
            return _SessionError(
              message: session.error ?? 'Unable to load your workspace.',
              onRetry: session.refresh,
            );

          case SessionStatus.onboarding:
            return const OnboardingScreen();

          case SessionStatus.authenticated:
            return SaaSPortalScreen(initialRole: _roleForUser(session.user));
        }
      },
    );
  }

  SaaSRole _roleForUser(CurrentUser? user) {
    final rawRole = user?.role.trim().toLowerCase() ?? '';

    switch (rawRole) {
      case 'super_admin':
      case 'platform':
      case 'platform_admin':
        return SaaSRole.platformAdmin;

      case 'company_admin':
      case 'owner':
      case 'admin':
        return SaaSRole.companyAdmin;

      case 'warehouse_manager':
      case 'manager':
        return SaaSRole.companyAdmin; // manager → company shell

      case 'packing_operator':
      case 'operator':
        return SaaSRole.operator;

      case 'viewer':
        return SaaSRole.companyAdmin; // viewer → limited later

      default:
        return SaaSRole.companyAdmin;
    }
  }
}

class _SessionLoading extends StatelessWidget {
  const _SessionLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SessionError extends StatelessWidget {
  const _SessionError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 52,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Workspace unavailable',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
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

