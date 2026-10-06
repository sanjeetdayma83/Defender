import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firebase_auth_service.dart';

class InviteDetails {
  final String companyName;
  final String businessType;
  final String location;
  final String role;
  final String warehouseName;
  final String warehouseLocation;
  final String invitedEmail;
  final String inviterName;
  final String message;

  const InviteDetails({
    this.companyName = '',
    this.businessType = '',
    this.location = '',
    this.role = '',
    this.warehouseName = '',
    this.warehouseLocation = '',
    this.invitedEmail = '',
    this.inviterName = '',
    this.message = '',
  });

  bool get hasCompanyInfo =>
      companyName.isNotEmpty || businessType.isNotEmpty || location.isNotEmpty;

  bool get hasAssignment => role.isNotEmpty || warehouseName.isNotEmpty;
}

class InviteAcceptScreen extends StatefulWidget {
  final InviteDetails invite;
  final Future<void> Function({
    required String fullName,
    required String mobile,
    required String password,
  })?
  onAccept;

  const InviteAcceptScreen({super.key, required this.invite, this.onAccept});

  @override
  State<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends State<InviteAcceptScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _termsAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? _error;

  bool get _passwordLength => _passwordController.text.length >= 8;

  bool get _passwordLetter =>
      RegExp(r'[A-Za-z]').hasMatch(_passwordController.text);

  bool get _passwordNumber =>
      RegExp(r'[0-9]').hasMatch(_passwordController.text);

  bool get _passwordSpecial =>
      RegExp(r'[^A-Za-z0-9]').hasMatch(_passwordController.text);

  @override
  void initState() {
    super.initState();

    _passwordController.addListener(_passwordChanged);

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (widget.invite.invitedEmail.isEmpty && firebaseUser != null) {
      // Email remains sourced from Firebase when invitation data does not
      // contain an email address.
    }
  }

  void _passwordChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _email {
    if (widget.invite.invitedEmail.isNotEmpty) {
      return widget.invite.invitedEmail;
    }

    return FirebaseAuth.instance.currentUser?.email ?? '';
  }

  Future<void> _acceptInvitation() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_termsAccepted) {
      setState(() {
        _error = 'Please agree to the Terms of Service and Privacy Policy.';
      });
      return;
    }

    if (widget.onAccept == null) {
      setState(() {
        _error = 'Invitation acceptance is not connected to the backend yet.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.onAccept!(
        fullName: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _firebaseError(e);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _continueWithGoogle() async {
    if (widget.onAccept == null) {
      setState(() {
        _error = 'Invitation acceptance is not connected to the backend yet.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuthService.instance.signInWithGoogle();

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception('Google authentication did not return a user.');
      }

      await widget.onAccept!(
        fullName: user.displayName ?? '',
        mobile: '',
        password: '',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _firebaseError(e);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _firebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled.';
      case 'popup-blocked':
        return 'The Google sign-in popup was blocked by the browser.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Unable to continue.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 320, child: _brandPanel()),
                    _formPanel(),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: constraints.maxHeight - 40,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 35, child: _brandPanel()),
                      Expanded(flex: 65, child: _formPanel()),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _brandPanel() {
    return ClipRRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/branding/loss_defender_login_background.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x99021F4F), Color(0xF2021F4F)],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(46, 38, 42, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/branding/loss_defender_logo.png',
                  width: 205,
                  height: 52,
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                ),

                const SizedBox(height: 62),

                const Text(
                  "You've Been",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),

                const Text(
                  'Invited to Join',
                  style: TextStyle(
                    color: Color(0xFF118BFF),
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Join your company on Loss Defender Pro '
                  'and be part of a secure, transparent '
                  'packing process.',
                  style: TextStyle(
                    color: Color(0xFFE5EEF9),
                    fontSize: 16,
                    height: 1.55,
                  ),
                ),

                const SizedBox(height: 38),

                _feature(
                  Icons.inventory_2_outlined,
                  'Real Packing Verification',
                  'Video proof for every shipment',
                ),

                _feature(
                  Icons.shield_outlined,
                  'Reduce Fake Returns',
                  'Build trust with customers',
                ),

                _feature(
                  Icons.groups_outlined,
                  'Work with Your Team',
                  'Assigned warehouse access',
                ),

                _feature(
                  Icons.bar_chart_rounded,
                  'Secure & Compliant',
                  'Complete audit trail',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feature(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0x332F80ED),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0x667AAFFF)),
            ),
            child: Icon(icon, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xCFE0EAF7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _formPanel() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(46, 24, 46, 30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.topRight, child: _languageSelector()),

              const SizedBox(height: 12),

              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: Color(0xFF0061FC),
                    size: 42,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Accept Invitation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF071333),
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                widget.invite.inviterName.isNotEmpty
                    ? '${widget.invite.inviterName} has invited you to join '
                          'a company on Loss Defender Pro.'
                    : 'You have been invited to join a company on '
                          'Loss Defender Pro.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF52627A),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 24),

              if (widget.invite.hasCompanyInfo) _companyCard(),

              if (widget.invite.hasCompanyInfo) const SizedBox(height: 16),

              if (widget.invite.hasAssignment) _assignmentCard(),

              if (widget.invite.hasAssignment) const SizedBox(height: 22),

              if (_error != null) ...[
                _errorBanner(),
                const SizedBox(height: 16),
              ],

              _field(
                controller: _nameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                requiredField: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name is required.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 15),

              _field(
                controller: _mobileController,
                label: 'Mobile Number',
                hint: 'Enter 10 digit mobile number',
                icon: Icons.phone_outlined,
                requiredField: true,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                prefix: '+91',
                validator: (value) {
                  final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';

                  if (digits.length != 10) {
                    return 'Enter a valid 10 digit mobile number.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 15),

              _field(
                controller: TextEditingController(text: _email),
                label: 'Email Address',
                hint: 'Invitation email',
                icon: Icons.mail_outline_rounded,
                readOnly: true,
              ),

              const SizedBox(height: 15),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _passwordField()),
                  const SizedBox(width: 16),
                  Expanded(child: _passwordRequirements()),
                ],
              ),

              const SizedBox(height: 15),

              _confirmPasswordField(),

              const SizedBox(height: 16),

              _termsRow(),

              const SizedBox(height: 18),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _acceptInvitation,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0061FC),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Accept Invitation',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, size: 19),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE3E8F0))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE3E8F0))),
                ],
              ),

              const SizedBox(height: 18),

              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: _loading ? null : _continueWithGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF172033),
                    side: const BorderSide(color: Color(0xFFD7E0EC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _googleMark(),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                widget.invite.message.isNotEmpty
                    ? '"${widget.invite.message}"'
                    : 'Invitation valid for 7 days. '
                          'If expired, please request a new invite from your owner.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _companyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCEBFC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoIcon(Icons.business_rounded),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Company',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.invite.companyName,
                  style: const TextStyle(
                    color: Color(0xFF071333),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 18,
                  runSpacing: 6,
                  children: [
                    if (widget.invite.businessType.isNotEmpty)
                      _meta(
                        Icons.person_outline_rounded,
                        widget.invite.businessType,
                      ),
                    if (widget.invite.location.isNotEmpty)
                      _meta(Icons.location_on_outlined, widget.invite.location),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignmentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCEBFC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _assignmentItem(
              Icons.groups_outlined,
              'Your Role',
              widget.invite.role,
            ),
          ),
          Container(width: 1, height: 58, color: const Color(0xFFD9E5F2)),
          const SizedBox(width: 20),
          Expanded(
            child: _assignmentItem(
              Icons.warehouse_outlined,
              'Warehouse Access',
              widget.invite.warehouseName.isEmpty
                  ? widget.invite.warehouseLocation
                  : widget.invite.warehouseName,
            ),
          ),
        ],
      ),
    );
  }

  Widget _assignmentItem(IconData icon, String label, String value) {
    return Row(
      children: [
        _infoIcon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'Not specified' : value,
                style: const TextStyle(
                  color: Color(0xFF0B4FD8),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordController,
      enabled: !_loading,
      obscureText: _obscurePassword,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password is required.';
        }

        if (!_passwordLength ||
            !_passwordLetter ||
            !_passwordNumber ||
            !_passwordSpecial) {
          return 'Password does not meet requirements.';
        }

        return null;
      },
      style: const TextStyle(fontSize: 14, color: Color(0xFF172033)),
      decoration:
          _inputDecoration(
            'Set Password',
            'Create a strong password',
            Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
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
                size: 19,
              ),
            ),
          ),
    );
  }

  Widget _confirmPasswordField() {
    return TextFormField(
      controller: _confirmController,
      enabled: !_loading,
      obscureText: _obscureConfirm,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Confirm your password.';
        }

        if (value != _passwordController.text) {
          return 'Passwords do not match.';
        }

        return null;
      },
      style: const TextStyle(fontSize: 14, color: Color(0xFF172033)),
      decoration:
          _inputDecoration(
            'Confirm Password',
            'Confirm your password',
            Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon: IconButton(
              onPressed: _loading
                  ? null
                  : () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 19,
              ),
            ),
          ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool requiredField = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    int? maxLength,
    String? prefix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_loading,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF172033),
        fontWeight: FontWeight.w500,
      ),
      decoration:
          _inputDecoration(
            label,
            hint,
            icon,
            requiredField: requiredField,
          ).copyWith(
            counterText: '',
            prefixIcon: prefix == null
                ? null
                : SizedBox(
                    width: 62,
                    child: Center(
                      child: Text(
                        prefix,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
          ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    String hint,
    IconData icon, {
    bool requiredField = false,
  }) {
    return InputDecoration(
      labelText: requiredField ? '$label *' : label,
      hintText: hint,
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
      labelStyle: const TextStyle(
        color: Color(0xFF172033),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(color: Color(0xFF8794A8), fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD9E2EE)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD9E2EE)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0061FC), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE53935)),
      ),
    );
  }

  Widget _passwordRequirements() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFDCEBFC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF0061FC),
              ),
              const SizedBox(width: 8),
              const Text(
                'Password Requirements',
                style: TextStyle(
                  color: Color(0xFF172033),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _requirement(_passwordLength, 'Minimum 8 characters'),
          _requirement(_passwordLetter, 'At least one letter (A-Z)'),
          _requirement(_passwordNumber, 'At least one number (0-9)'),
          _requirement(_passwordSpecial, 'At least one special character'),
        ],
      ),
    );
  }

  Widget _requirement(bool valid, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Icon(
            valid ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 17,
            color: valid ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: valid
                    ? const Color(0xFF15803D)
                    : const Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _termsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _termsAccepted,
          onChanged: _loading
              ? null
              : (value) {
                  setState(() {
                    _termsAccepted = value ?? false;
                    if (_termsAccepted) {
                      _error = null;
                    }
                  });
                },
          activeColor: const Color(0xFF0061FC),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 7),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text.rich(
              TextSpan(
                text: 'I agree to the ',
                style: TextStyle(color: Color(0xFF475569), fontSize: 12),
                children: [
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: Color(0xFF0061FC),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFF0061FC),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Color(0xFFE53935)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoIcon(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFE2F0FF),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Color(0xFF0061FC), size: 25),
    );
  }

  Widget _meta(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF475569)),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(color: Color(0xFF334155), fontSize: 12),
        ),
      ],
    );
  }

  Widget _languageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFDCE3EC)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.language_rounded, size: 17, color: Color(0xFF334155)),
          SizedBox(width: 7),
          Text(
            'English',
            style: TextStyle(
              color: Color(0xFF172033),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 5),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 17,
            color: Color(0xFF475569),
          ),
        ],
      ),
    );
  }

  Widget _googleMark() {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 21,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
