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

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthMode _mode = AuthMode.signIn;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _errorMessage;

  bool get _isSignIn => _mode == AuthMode.signIn;

  @override
  void dispose() {
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

  Future<void> _submitEmailPassword() async {
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
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await auth.createAccountWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
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
        _errorMessage = error.toString();
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
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuthService.instance.signInWithGoogle();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _firebaseErrorMessage(error);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
        return 'Google sign-in was cancelled.';

      case 'popup-blocked':
        return 'The Google sign-in popup was blocked by the browser.';

      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';

      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Authentication.';

      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';

      case 'network-request-failed':
        return 'Network error. Check your internet connection.';

      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.security,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Loss Defender',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _isSignIn
                        ? 'Sign in to your warehouse workspace'
                        : 'Create your Loss Defender account',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeButton(
                            label: 'Sign in',
                            selected: _isSignIn,
                            onPressed: () {
                              _setMode(AuthMode.signIn);
                            },
                          ),
                        ),
                        Expanded(
                          child: _ModeButton(
                            label: 'Create account',
                            selected: !_isSignIn,
                            onPressed: () {
                              _setMode(AuthMode.signUp);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          enabled: !_loading,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@example.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
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

                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          enabled: !_loading,
                          obscureText: _obscurePassword,
                          textInputAction: _isSignIn
                              ? TextInputAction.done
                              : TextInputAction.next,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) {
                            if (_isSignIn && !_loading) {
                              _submitEmailPassword();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Show password'
                                  : 'Hide password',
                              onPressed: _loading
                                  ? null
                                  : () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').isEmpty) {
                              return 'Password is required.';
                            }

                            if (!_isSignIn && (value ?? '').length < 6) {
                              return 'Password must be at least 6 characters.';
                            }

                            return null;
                          },
                        ),

                        if (!_isSignIn) ...[
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _confirmPasswordController,
                            enabled: !_loading,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Confirm password',
                              hintText: 'Enter password again',
                              prefixIcon: const Icon(Icons.lock_reset_outlined),
                              suffixIcon: IconButton(
                                tooltip: _obscureConfirmPassword
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: _loading
                                    ? null
                                    : () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return 'Please confirm your password.';
                              }

                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: _loading ? null : _submitEmailPassword,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isSignIn ? 'Sign In' : 'Create Account',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                    ],
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _loading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Secure authentication powered by Firebase',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
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
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

