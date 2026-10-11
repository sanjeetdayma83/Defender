import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_auth_service.dart';
import 'forgot_password_screen.dart';
import 'owner_signup_screen.dart';

const _navy = Color(0xFF021F4F);
const _blue = Color(0xFF0061FC);
const _slate = Color(0xFF64748B);
const _border = Color(0xFFD8E1ED);
const _surface = Color(0xFFF8FAFC);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }

    if (password.isEmpty) {
      setState(() => _error = 'Enter your password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyError(e));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to sign in. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _google() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuthService.instance.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyError(e));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Google sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _friendlyError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  void _openSignup() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const OwnerSignupScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 900;

            if (isMobile) {
              return _mobileLayout();
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 11, child: _brandPanel()),
                Expanded(flex: 9, child: _desktopFormPanel()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _mobileLayout() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
      child: Column(
        children: [
          Image.asset(
            'assets/branding/loss_defender_logo.png',
            height: 58,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Text(
              'LOSS DEFENDER',
              style: TextStyle(
                color: _navy,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _loginForm(),
        ],
      ),
    );
  }

  Widget _brandPanel() {
    return Container(
      margin: const EdgeInsets.all(3),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFF315B83)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/branding/loss_defender_login_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, _, _) => const ColoredBox(color: _navy),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xE8021535),
                  Color(0xC8021F4F),
                  Color(0x67203F65),
                ],
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 820;
              final horizontalPadding = constraints.maxWidth < 1050
                  ? 34.0
                  : 56.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: compact ? 30 : 44,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - (compact ? 60 : 88),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/branding/loss_defender_logo.png',
                        height: compact ? 66 : 84,
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                        errorBuilder: (_, _, _) => const Text(
                          'LOSS DEFENDER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 20 : 30),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 29 : 37,
                            height: 1.16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                          children: const [
                            TextSpan(text: 'Turn Every Shipment\ninto '),
                            TextSpan(
                              text: 'Iron-Clad Evidence',
                              style: TextStyle(color: Color(0xFF20A5FF)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'AI-powered warehouse intelligence platform '
                        'to prevent losses, reduce disputes and protect '
                        'your business.',
                        style: TextStyle(
                          color: Color(0xFFD4E3F7),
                          fontSize: 16,
                          height: 1.55,
                        ),
                      ),
                      SizedBox(height: compact ? 16 : 24),
                      _featureGrid(compact),
                      SizedBox(height: compact ? 14 : 22),
                      _devicePreview(compact),
                      const SizedBox(height: 16),
                      const Text(
                        'Warehouse intelligence. Shipment confidence.',
                        style: TextStyle(
                          color: Color(0xFFB8D0ED),
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _featureGrid(bool compact) {
    final features = [
      (Icons.camera_alt_outlined, 'Scan & Record', 'Packing'),
      (Icons.description_outlined, 'AI Evidence', 'Management'),
      (Icons.shield_outlined, 'Dispute', 'Protection'),
      (Icons.bar_chart_rounded, 'Real-time', 'Insights'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth < 460 ? 8.0 : 14.0;
        final itemWidth = (constraints.maxWidth - spacing * 3) / 4;

        return Wrap(
          spacing: spacing,
          runSpacing: 16,
          children: features.map((feature) {
            return SizedBox(
              width: itemWidth,
              child: Column(
                children: [
                  Container(
                    width: compact ? 48 : 58,
                    height: compact ? 48 : 58,
                    decoration: BoxDecoration(
                      color: const Color(0xB00061FC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x663BB8FF)),
                    ),
                    child: Icon(
                      feature.$1,
                      color: const Color(0xFF79D0FF),
                      size: compact ? 25 : 29,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    '${feature.$2}\n${feature.$3}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 10 : 12,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _devicePreview(bool compact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 20),
      decoration: BoxDecoration(
        color: const Color(0xB3021737),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x663C9CDE)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: compact ? 72 : 94,
            decoration: BoxDecoration(
              color: const Color(0xFF20A5FF),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF38D99B),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Packing verification',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _metric('ORDERS', '1,248'),
                    const SizedBox(width: 18),
                    _metric('VERIFIED', '99.1%'),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: 0.82,
                    minHeight: 5,
                    backgroundColor: Color(0xFF25405D),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF20A5FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            const Icon(
              Icons.devices_rounded,
              color: Color(0xFF79D0FF),
              size: 38,
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFADC4DF),
            fontSize: 9,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _desktopFormPanel() {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 514),
            child: _loginForm(),
          ),
        ),
      ),
    );
  }

  Widget _loginForm() {
    final compact = MediaQuery.sizeOf(context).height < 820;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              const Text(
                'New to Loss Defender?',
                style: TextStyle(color: _slate, fontSize: 13),
              ),
              TextButton(
                onPressed: _loading ? null : _openSignup,
                style: TextButton.styleFrom(
                  foregroundColor: _blue,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: Image.asset(
            'assets/branding/loss_defender_logo.png',
            height: compact ? 52 : 68,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Text(
              'LOSS DEFENDER',
              style: TextStyle(
                color: _navy,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome Back',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0B1830),
            fontSize: compact ? 29 : 33,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Login to your account to continue',
          textAlign: TextAlign.center,
          style: TextStyle(color: _slate, fontSize: 17, height: 1.4),
        ),
        SizedBox(height: compact ? 16 : 24),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(13),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFB91C1C),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        _fieldLabel('Email Address'),
        const SizedBox(height: 9),
        TextField(
          controller: _email,
          enabled: !_loading,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration: _inputDecoration(
            hint: 'Enter your email address',
            icon: Icons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 26),
        _fieldLabel('Password'),
        const SizedBox(height: 9),
        TextField(
          controller: _password,
          enabled: !_loading,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _signIn(),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration:
              _inputDecoration(
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _slate,
                  ),
                ),
              ),
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _loading ? null : _openForgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: _blue,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text(
              'Forgot Password?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 58,
          child: FilledButton(
            onPressed: _loading ? null : _signIn,
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF8BB7FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    height: 23,
                    width: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 13),
                      Icon(Icons.arrow_forward_rounded, size: 23),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 28),
        const Row(
          children: [
            Expanded(child: Divider(color: _border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: _slate,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: _border)),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 56,
          child: OutlinedButton(
            onPressed: _loading ? null : _google,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF111827),
              side: const BorderSide(color: _border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoogleMark(),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Continue with Google',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 36),
        const Text(
          '© 2026 Loss Defender. All rights reserved.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _slate, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF111827),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF8491A5),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, color: _slate, size: 23),
      filled: true,
      fillColor: const Color(0xFFFCFDFE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _blue, width: 1.6),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: _border),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 23,
      height: 23,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w900,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}
