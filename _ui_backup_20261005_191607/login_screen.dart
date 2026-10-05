import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_auth_service.dart';

enum AuthMode { signIn, signUp }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthMode _mode = AuthMode.signIn;

  bool _loading = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _errorMessage;

  bool get _isSignIn => _mode == AuthMode.signIn;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setMode(AuthMode mode) {
    if (_mode == mode || _loading) return;

    setState(() {
      _mode = mode;
      _errorMessage = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isSignIn &&
        _passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final auth = FirebaseAuthService.instance;

      if (_isSignIn) {
        await auth.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await auth.createAccountWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _firebaseErrorMessage(error);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanException(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    await _socialSignIn(
      action: () => FirebaseAuthService.instance.signInWithGoogle(),
    );
  }

  Future<void> _signInWithMicrosoft() async {
    await _socialSignIn(
      action: () => FirebaseAuthService.instance.signInWithMicrosoft(),
    );
  }

  Future<void> _socialSignIn({required Future<void> Function() action}) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await action();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _firebaseErrorMessage(error);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanException(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Enter your email address first.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuthService.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Check your email'),
            content: Text(
              'If an account exists for $email, Firebase has sent a '
              'password reset link.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _firebaseErrorMessage(error);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanException(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _cleanException(Object error) {
    final value = error.toString();

    if (value.startsWith('Exception: ')) {
      return value.substring('Exception: '.length);
    }

    return value;
  }

  String _firebaseErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-not-found':
        return 'No account exists with this email address.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';

      case 'email-already-in-use':
        return 'An account already exists with this email address.';

      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';

      case 'popup-closed-by-user':
        return 'Sign-in was cancelled.';

      case 'popup-blocked':
        return 'The sign-in popup was blocked by the browser.';

      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';

      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Authentication.';

      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';

      case 'network-request-failed':
        return 'Network error. Check your internet connection.';

      case 'user-disabled':
        return 'This account has been disabled.';

      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1000;

            if (!isDesktop) {
              return _buildMobileLayout();
            }

            return _buildDesktopLayout();
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 47, child: _buildBrandPanel()),
          const SizedBox(width: 0),
          Expanded(flex: 53, child: _buildAuthArea()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMobileBrandHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: _buildAuthCard(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildBrandPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(76, 76, 64, 42),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071B4D), Color(0xFF0A2C72), Color(0xFF0B4DCC)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260B2A68),
            blurRadius: 35,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(width: 310, height: 86, darkBackground: true),
          const SizedBox(height: 42),
          const Text(
            'AI-powered Warehouse Security &\nOrder Verification Platform',
            style: TextStyle(
              color: Color(0xFFE8F0FF),
              fontSize: 21,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 38),
          _FeatureCard(
            icon: Icons.fact_check_rounded,
            title: 'Verify Every Order',
            description:
                'AI-driven verification to ensure packing accuracy and reduce errors.',
          ),
          const SizedBox(height: 14),
          _FeatureCard(
            icon: Icons.videocam_rounded,
            title: 'AI Video Evidence',
            description:
                'Auto recording with searchable evidence timeline for disputes.',
          ),
          const SizedBox(height: 14),
          _FeatureCard(
            icon: Icons.shield_rounded,
            title: 'Reduce Warehouse Loss',
            description:
                'Prevent shrinkage, fraud and unauthorized activities with smart monitoring.',
          ),
          const SizedBox(height: 14),
          _FeatureCard(
            icon: Icons.bar_chart_rounded,
            title: 'Live Analytics',
            description:
                'Real-time insights and performance tracking for better decision making.',
          ),
          const Spacer(),
          Container(height: 1, color: const Color(0x55FFFFFF)),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xAAFFFFFF)),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Trusted by businesses to secure warehouse operations worldwide.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBrandHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF071B4D), Color(0xFF0B4DCC)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogo(width: 250, height: 70, darkBackground: true),
          const SizedBox(height: 16),
          const Text(
            'AI-powered Warehouse Security & Order Verification Platform',
            style: TextStyle(
              color: Color(0xFFE8F0FF),
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthArea() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(56, 28, 56, 10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: _buildAuthCard(),
              ),
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildAuthCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(56, 44, 56, 42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3EAF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140B2A68),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF2F6FF),
                  border: Border.all(color: const Color(0xFFD9E5FF)),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 42,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                _isSignIn ? 'Welcome Back' : 'Create Your Account',
                style: const TextStyle(
                  color: Color(0xFF071333),
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _isSignIn
                    ? 'Sign in to continue to your account'
                    : 'Create your Loss Defender workspace account',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF71809B), fontSize: 16),
              ),
            ),
            const SizedBox(height: 28),
            _buildModeSwitcher(),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              _buildErrorBanner(),
              const SizedBox(height: 18),
            ],
            if (!_isSignIn) ...[
              _buildField(
                controller: _nameController,
                label: 'Full name',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name is required.';
                  }

                  if (value.trim().length < 2) {
                    return 'Enter your full name.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 17),
            ],
            _buildField(
              controller: _emailController,
              label: 'Email',
              hint: 'Enter your email address',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final email = value?.trim() ?? '';

                if (email.isEmpty) {
                  return 'Email is required.';
                }

                if (!email.contains('@') || !email.contains('.')) {
                  return 'Enter a valid email address.';
                }

                return null;
              },
            ),
            const SizedBox(height: 17),
            _buildPasswordField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              obscure: _obscurePassword,
              onToggle: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required.';
                }

                if (value.length < 6) {
                  return 'Password must contain at least 6 characters.';
                }

                return null;
              },
            ),
            if (!_isSignIn) ...[
              const SizedBox(height: 17),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                hint: 'Re-enter your password',
                obscure: _obscureConfirmPassword,
                onToggle: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password.';
                  }

                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }

                  return null;
                },
              ),
            ],
            if (_isSignIn) ...[
              const SizedBox(height: 15),
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: _loading
                        ? null
                        : (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                    activeColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const Text(
                    'Remember me',
                    style: TextStyle(color: Color(0xFF334155), fontSize: 14),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _loading ? null : _forgotPassword,
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF93B4F5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isSignIn ? 'Sign in' : 'Create account',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward_rounded, size: 21),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDivider(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    icon: const _GoogleIcon(),
                    label: 'Sign in with Google',
                    onPressed: _loading ? null : _signInWithGoogle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _SocialButton(
                    icon: const _MicrosoftIcon(),
                    label: 'Sign in with Microsoft',
                    onPressed: _loading ? null : _signInWithMicrosoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    _isSignIn
                        ? "Don't have an account? "
                        : 'Already have an account? ',
                    style: const TextStyle(
                      color: Color(0xFF71809B),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: _loading
                        ? null
                        : () {
                            _setMode(
                              _isSignIn ? AuthMode.signUp : AuthMode.signIn,
                            );
                          },
                    child: Text(
                      _isSignIn ? 'Create Account' : 'Sign in',
                      style: const TextStyle(
                        color: Color(0xFF145CE6),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Sign in',
              selected: _isSignIn,
              onPressed: () => _setMode(AuthMode.signIn),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Create account',
              selected: !_isSignIn,
              onPressed: () => _setMode(AuthMode.signUp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_loading,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: keyboardType == TextInputType.emailAddress
          ? const [AutofillHints.email]
          : null,
      validator: validator,
      decoration: _inputDecoration(label: label, hint: hint, icon: icon),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_loading,
      obscureText: obscure,
      textInputAction: TextInputAction.done,
      validator: validator,
      onFieldSubmitted: (_) {
        if (!_loading) {
          _submit();
        }
      },
      decoration:
          _inputDecoration(
            label: label,
            hint: hint,
            icon: Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              onPressed: _loading ? null : onToggle,
              tooltip: obscure ? 'Show password' : 'Hide password',
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      labelStyle: const TextStyle(
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.w500,
      ),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD7DFEC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD7DFEC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFDDE4EF))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or continue with',
            style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFDDE4EF))),
      ],
    );
  }

  Widget _buildLogo({
    required double width,
    required double height,
    required bool darkBackground,
  }) {
    if (darkBackground) {
      return Image.asset(
        'assets/branding/loss_defender_logo.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) {
          return const Text(
            'LOSS DEFENDER',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          );
        },
      );
    }

    return Image.asset(
      'assets/branding/loss_defender_logo.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14,
        runSpacing: 8,
        children: const [
          Text(
            '© 2026 Loss Defender Pro',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
          Text(
            'Version 1.0.0',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
          Text(
            'Privacy Policy',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
          Text(
            'Support',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x10000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF145CE6) : const Color(0xFF64748B),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0x140F62D8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x3B9CC4FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x402563EB),
                  blurRadius: 15,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        foregroundColor: const Color(0xFF1E293B),
        side: const BorderSide(color: Color(0xFFD7DFEC)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 22, height: 22, child: icon),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MicrosoftIcon extends StatelessWidget {
  const _MicrosoftIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: const [
            ColoredBox(color: Color(0xFFF35325)),
            ColoredBox(color: Color(0xFF81BC06)),
            ColoredBox(color: Color(0xFF05A6F0)),
            ColoredBox(color: Color(0xFFFFBA08)),
          ],
        ),
      ),
    );
  }
}
