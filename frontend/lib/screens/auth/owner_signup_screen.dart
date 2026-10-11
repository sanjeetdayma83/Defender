import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_auth_service.dart';
import 'verify_email_screen.dart';

const _navy = Color(0xFF021F4F);
const _blue = Color(0xFF0061FC);
const _slate = Color(0xFF64748B);
const _border = Color(0xFFD8E1ED);
const _surface = Color(0xFFF8FAFC);

class OwnerSignupScreen extends StatefulWidget {
  const OwnerSignupScreen({super.key});

  @override
  State<OwnerSignupScreen> createState() => _OwnerSignupScreenState();
}

class _OwnerSignupScreenState extends State<OwnerSignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _terms = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _password.text.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_password.text);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_password.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_password.text);

  Future<void> _create() async {
    FocusScope.of(context).unfocus();

    if (!_form.currentState!.validate()) return;

    if (!_terms) {
      setState(() {
        _error = 'Please accept the Terms of Service and Privacy Policy.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final credential = await FirebaseAuthService.instance
          .createAccountWithEmail(
            email: _email.text.trim(),
            password: _password.text,
            displayName: _name.text.trim(),
          );

      await credential.user?.sendEmailVerification();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const VerifyEmailScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyError(e));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to create account. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _friendlyError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return error.message ?? 'Unable to create account.';
    }
  }

  void _backToLogin() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 850) {
              return _mobileLayout();
            }

            return Row(
              children: [
                Expanded(flex: 4, child: _brandPanel()),
                Expanded(flex: 6, child: _desktopForm()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _brandPanel() {
    return Container(
      margin: const EdgeInsets.all(3),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/branding/loss_defender_login_background.png',
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(color: _navy),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xE8021535),
                  Color(0xA6021F4F),
                  Color(0xD9021535),
                ],
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, size) {
              final compact = size.maxHeight < 760;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(30, compact ? 24 : 34, 30, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/branding/loss_defender_logo.png',
                      height: compact ? 62 : 76,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Text(
                        'LOSS DEFENDER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: 0.38),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'WAREHOUSE INTELLIGENCE PLATFORM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 29 : 36,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
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
                    const SizedBox(height: 14),
                    const Text(
                      'AI-powered platform to scan, record and verify '
                      'packages — prevent losses, reduce disputes and '
                      'protect your business.',
                      style: TextStyle(
                        color: Color(0xFFE0EBFA),
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: compact ? 22 : 30),
                    _feature(
                      Icons.videocam_outlined,
                      'Video Evidence',
                      'Scan and record every package',
                    ),
                    _feature(
                      Icons.shield_outlined,
                      'Prevent Losses',
                      'Reduce disputes and fraud',
                    ),
                    _feature(
                      Icons.bar_chart_rounded,
                      'Real-time Insights',
                      'Track orders, returns and claims',
                    ),
                    _feature(
                      Icons.cloud_outlined,
                      'Works on Phone & Laptop',
                      'Access anywhere, anytime',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0x99021737),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0x5547B5FF)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xFF48C6FF),
                            size: 29,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Secure & reliable\nYour warehouse evidence, protected.',
                              style: TextStyle(
                                color: Colors.white,
                                height: 1.5,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _feature(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xCC0054D9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x554CB8FF)),
            ),
            child: Icon(icon, color: const Color(0xFF8AD9FF), size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFD0DFF2),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopForm() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 850;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(28, compact ? 12 : 20, 28, 0),
                child: _topBar(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    30,
                    compact ? 10 : 18,
                    30,
                    compact ? 14 : 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: _formContent(compact: compact),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _mobileLayout() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/branding/loss_defender_logo.png',
                  height: 54,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Text(
                    'LOSS DEFENDER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Turn Every Shipment into Iron-Clad Evidence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Protect your business with warehouse intelligence.',
                  style: TextStyle(
                    color: Color(0xFFD0DFF2),
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _topBar(),
          const SizedBox(height: 10),
          _formContent(compact: true),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Row(
      children: [
        const Spacer(),
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              const Text(
                'Already have an account?',
                style: TextStyle(color: _slate, fontSize: 12),
              ),
              TextButton(
                onPressed: _loading ? null : _backToLogin,
                child: const Text(
                  'Login',
                  style: TextStyle(color: _blue, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _formContent({required bool compact}) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              'assets/branding/loss_defender_logo.png',
              height: compact ? 48 : 62,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Text(
                'LOSS DEFENDER',
                style: TextStyle(
                  color: _navy,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 12 : 18),
          Text(
            'Create Your Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF0B1830),
              fontSize: compact ? 27 : 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Start with your personal details to set up your workspace.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _slate, height: 1.45, fontSize: 13),
          ),
          SizedBox(height: compact ? 17 : 24),
          _progress(),
          SizedBox(height: compact ? 18 : 25),
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
              ),
            ),
            const SizedBox(height: 14),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 590;

              final fields = <Widget>[
                _input(
                  controller: _name,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Full name is required.'
                      : null,
                ),
                _input(
                  controller: _email,
                  label: 'Email Address',
                  hint: 'Enter your email address',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                        ? null
                        : 'Enter a valid email address.';
                  },
                ),
                _input(
                  controller: _mobile,
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
                    return digits.length >= 10
                        ? null
                        : 'Enter a valid phone number.';
                  },
                ),
                _input(
                  controller: _password,
                  label: 'Password',
                  hint: 'Create a strong password',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  suffix: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _slate,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    if (!_hasMinLength ||
                        !_hasUpper ||
                        !_hasLower ||
                        !_hasNumber) {
                      return 'Password does not meet all requirements.';
                    }
                    return null;
                  },
                ),
              ];

              if (!twoColumns) {
                return Column(
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      fields[i],
                      if (i != fields.length - 1)
                        SizedBox(height: compact ? 13 : 17),
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 18),
                      Expanded(child: fields[1]),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: fields[2]),
                      const SizedBox(width: 18),
                      Expanded(child: fields[3]),
                    ],
                  ),
                ],
              );
            },
          ),
          SizedBox(height: compact ? 12 : 17),
          _passwordChecklist(),
          const SizedBox(height: 10),
          _input(
            controller: _confirm,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            icon: Icons.lock_outline,
            obscure: _obscureConfirm,
            suffix: IconButton(
              tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _slate,
              ),
            ),
            validator: (value) =>
                value != _password.text ? 'Passwords do not match.' : null,
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _terms,
            onChanged: _loading
                ? null
                : (value) => setState(() {
                    _terms = value ?? false;
                    _error = null;
                  }),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            activeColor: _blue,
            title: const Text(
              'I agree to the Terms of Service and Privacy Policy.',
              style: TextStyle(color: _slate, fontSize: 12),
            ),
          ),
          SizedBox(height: compact ? 12 : 18),
          SizedBox(
            height: compact ? 49 : 54,
            child: FilledButton(
              onPressed: _loading ? null : _create,
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '© 2026 Loss Defender. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _slate, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _progress() {
    const labels = [
      'Admin Details',
      'Company Details',
      'Email Verification',
      'Complete',
    ];

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: i == 0 ? _blue : const Color(0xFFE9EDF5),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: i == 0 ? Colors.white : _slate,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: i == 0 ? _blue : _slate,
                    fontSize: 10,
                    fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _passwordChecklist() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF6FF),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Password must contain:',
            style: TextStyle(
              color: _navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _requirement('At least 8 characters', _hasMinLength),
          _requirement('One uppercase letter (A–Z)', _hasUpper),
          _requirement('One lowercase letter (a–z)', _hasLower),
          _requirement('One number (0–9)', _hasNumber),
        ],
      ),
    );
  }

  Widget _requirement(String label, bool satisfied) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.check,
            size: 16,
            color: satisfied ? const Color(0xFF16A34A) : _slate,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: satisfied ? const Color(0xFF166534) : _slate,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          enabled: !_loading,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF8491A5), fontSize: 12),
            prefixIcon: Icon(icon, color: _slate, size: 21),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFFCFDFE),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _blue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFDC2626),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
