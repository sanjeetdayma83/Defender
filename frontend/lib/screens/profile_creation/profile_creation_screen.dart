import 'package:flutter/material.dart';
import '../../widgets/ux/ld_ux.dart';

class ProfileCreationScreen extends StatefulWidget {
  final VoidCallback? onCompleted;

  const ProfileCreationScreen({super.key, this.onCompleted});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _warehouseController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _warehouseController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ldShowWarning(context, 'Please complete all required fields.');
      return;
    }

    setState(() => _saving = true);

    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    setState(() => _saving = false);

    ldShowSuccess(context, 'Profile information saved.');

    widget.onCompleted?.call();
  }

  InputDecoration _decoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LDUXColors.border),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LDUXColors.background,
      appBar: AppBar(
        title: const Text('Complete your profile'),
        backgroundColor: Colors.white,
        foregroundColor: LDUXColors.text,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: LDUXColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 36,
                        color: LDUXColors.blue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Let’s set up your workspace',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'These details will be used to personalize your Loss Defender workspace.',
                        style: TextStyle(color: LDUXColors.muted, height: 1.5),
                      ),
                      const SizedBox(height: 26),

                      TextFormField(
                        controller: _nameController,
                        decoration: _decoration(
                          'Full name',
                          'e.g. Sanjeet Dayma',
                          Icons.person_outline_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Full name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: _decoration(
                          'Phone number',
                          'e.g. +91 9876543210',
                          Icons.phone_outlined,
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _companyController,
                        decoration: _decoration(
                          'Company name',
                          'Your business or organization',
                          Icons.business_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Company name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _warehouseController,
                        decoration: _decoration(
                          'Primary warehouse',
                          'e.g. Main Warehouse',
                          Icons.warehouse_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Warehouse name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 26),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_rounded),
                          label: Text(_saving ? 'Saving...' : 'Continue'),
                        ),
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
