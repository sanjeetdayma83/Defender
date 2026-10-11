import 'package:flutter/material.dart';

const _navy = Color(0xFF021F4F);
const _blue = Color(0xFF0061FC);
const _slate = Color(0xFF64748B);
const _border = Color(0xFFD8E1ED);

class CompanyDetailsScreen extends StatefulWidget {
  const CompanyDetailsScreen({
    super.key,
    this.initialValues = const {},
    this.onContinue,
  });

  final Map<String, String> initialValues;
  final ValueChanged<Map<String, String>>? onContinue;

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _company;
  late final TextEditingController _gst;
  late final TextEditingController _address;
  late final TextEditingController _website;
  late final TextEditingController _warehouses;

  String? _businessType;
  String? _industry;
  bool _submitting = false;

  static const _businessTypes = [
    'Proprietorship',
    'Partnership',
    'Private Limited',
    'Public Limited',
    'LLP',
    'Other',
  ];

  static const _industries = [
    'E-commerce',
    'Retail & Wholesale',
    'Manufacturing',
    'Logistics & Warehousing',
    'FMCG',
    'Electronics',
    'Pharmaceuticals',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _company = TextEditingController(text: widget.initialValues['companyName']);
    _gst = TextEditingController(text: widget.initialValues['gstNumber']);
    _address = TextEditingController(text: widget.initialValues['address']);
    _website = TextEditingController(text: widget.initialValues['website']);
    _warehouses = TextEditingController(
      text: widget.initialValues['warehouseCount'],
    );
    _businessType = widget.initialValues['businessType'];
    _industry = widget.initialValues['industry'];
  }

  @override
  void dispose() {
    _company.dispose();
    _gst.dispose();
    _address.dispose();
    _website.dispose();
    _warehouses.dispose();
    super.dispose();
  }

  void _continue() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_businessType == null || _industry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your business type and industry.'),
        ),
      );
      return;
    }

    final values = <String, String>{
      'companyName': _company.text.trim(),
      'gstNumber': _gst.text.trim(),
      'businessType': _businessType!,
      'industry': _industry!,
      'address': _address.text.trim(),
      'website': _website.text.trim(),
      'warehouseCount': _warehouses.text.trim(),
    };

    if (widget.onContinue != null) {
      setState(() => _submitting = true);
      widget.onContinue!(values);
      if (mounted) setState(() => _submitting = false);
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Company details validated'),
        content: const Text(
          'The form is valid. Connect this screen to the registration '
          'workflow before submitting these details to the backend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 850) {
              return _mobileLayout();
            }

            return Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(flex: 38, child: _brandPanel()),
                  const SizedBox(width: 12),
                  Expanded(flex: 62, child: _desktopForm()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _brandPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
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
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xE8021535),
                  Color(0xA6021F4F),
                  Color(0xE8021535),
                ],
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, size) {
              final compact = size.maxHeight < 760;

              return SingleChildScrollView(
                padding: EdgeInsets.all(compact ? 22 : 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/branding/loss_defender_logo.png',
                      height: compact ? 58 : 72,
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
                    SizedBox(height: compact ? 20 : 28),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'WAREHOUSE INTELLIGENCE PLATFORM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 27 : 35,
                          height: 1.13,
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
                    const SizedBox(height: 12),
                    const Text(
                      'AI-powered platform to scan, record and verify '
                      'packages — prevent losses, reduce disputes and '
                      'protect your business.',
                      style: TextStyle(
                        color: Color(0xFFE0EBFA),
                        height: 1.5,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: compact ? 20 : 28),
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
                    const SizedBox(height: 12),
                    const Text(
                      'Secure & reliable  •  Quick setup  •  Built for business',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xCC0054D9),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0x554CB8FF)),
            ),
            child: Icon(icon, color: const Color(0xFF8AD9FF), size: 23),
          ),
          const SizedBox(width: 12),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, size) {
          final compact = size.maxHeight < 800;

          return Column(
            children: [
              _topBar(),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    compact ? 24 : 32,
                    compact ? 8 : 14,
                    compact ? 24 : 32,
                    compact ? 18 : 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/branding/loss_defender_logo.png',
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Text(
                    'LOSS DEFENDER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Protect Every Shipment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Set up your company workspace.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _topBar(),
          const SizedBox(height: 8),
          _formContent(compact: true),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          const Spacer(),
          const Flexible(
            child: Text(
              'Already have an account?',
              textAlign: TextAlign.end,
              style: TextStyle(color: _slate, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text(
              'Login',
              style: TextStyle(color: _blue, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formContent({required bool compact}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _progress(),
          SizedBox(height: compact ? 20 : 28),
          Text(
            'Company Details',
            style: TextStyle(
              color: const Color(0xFF0B1830),
              fontSize: compact ? 27 : 33,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tell us about your business to set up your workspace.',
            style: TextStyle(color: _slate, height: 1.45, fontSize: 13),
          ),
          SizedBox(height: compact ? 20 : 28),
          LayoutBuilder(
            builder: (context, size) {
              final twoColumns = size.maxWidth >= 580;

              final fields = <Widget>[
                _input(
                  controller: _company,
                  label: 'Company Name',
                  hint: 'Enter your company name',
                  icon: Icons.business_outlined,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Company name is required.'
                      : null,
                ),
                _input(
                  controller: _gst,
                  label: 'GST Number (Optional)',
                  hint: 'Enter GST number',
                  icon: Icons.badge_outlined,
                  validator: (v) {
                    final gst = v?.trim() ?? '';
                    if (gst.isEmpty) return null;
                    if (!RegExp(
                      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
                    ).hasMatch(gst.toUpperCase())) {
                      return 'Enter a valid GSTIN.';
                    }
                    return null;
                  },
                ),
                _dropdown(
                  label: 'Business Type',
                  hint: 'Select business type',
                  value: _businessType,
                  options: _businessTypes,
                  icon: Icons.business_center_outlined,
                  onChanged: (v) => setState(() => _businessType = v),
                ),
                _dropdown(
                  label: 'Industry',
                  hint: 'Select industry',
                  value: _industry,
                  options: _industries,
                  icon: Icons.factory_outlined,
                  onChanged: (v) => setState(() => _industry = v),
                ),
              ];

              if (!twoColumns) {
                return Column(
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      fields[i],
                      const SizedBox(height: 15),
                    ],
                    _addressField(),
                    const SizedBox(height: 15),
                    _input(
                      controller: _website,
                      label: 'Website (Optional)',
                      hint: 'https://yourcompany.com',
                      icon: Icons.language_outlined,
                      keyboardType: TextInputType.url,
                      validator: _validateWebsite,
                    ),
                    const SizedBox(height: 15),
                    _warehouseCountField(),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 20),
                      Expanded(child: fields[1]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: fields[2]),
                      const SizedBox(width: 20),
                      Expanded(child: fields[3]),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _addressField(),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _input(
                          controller: _website,
                          label: 'Website (Optional)',
                          hint: 'https://yourcompany.com',
                          icon: Icons.language_outlined,
                          keyboardType: TextInputType.url,
                          validator: _validateWebsite,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(child: _warehouseCountField()),
                    ],
                  ),
                ],
              );
            },
          ),
          SizedBox(height: compact ? 20 : 28),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _navy,
                  side: const BorderSide(color: _border),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _continue,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(
                    _submitting
                        ? 'Please wait'
                        : 'Continue to Email Verification',
                    textAlign: TextAlign.center,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
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
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i <= 1 ? _blue : const Color(0xFFE2E8F0),
                      ),
                    ),
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: i <= 1 ? _blue : const Color(0xFFE9EDF5),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: i == 0
                          ? const Icon(
                              Icons.check,
                              size: 19,
                              color: Colors.white,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: i <= 1 ? Colors.white : _slate,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i < 1 ? _blue : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: i <= 1 ? _blue : _slate,
                    fontSize: 10,
                    fontWeight: i == 1 ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _addressField() {
    return _input(
      controller: _address,
      label: 'Company Address',
      hint: 'Enter complete business address',
      icon: Icons.location_on_outlined,
      maxLines: 3,
      validator: (v) => v == null || v.trim().isEmpty
          ? 'Company address is required.'
          : v.trim().length > 300
          ? 'Address must be 300 characters or fewer.'
          : null,
    );
  }

  Widget _warehouseCountField() {
    return _input(
      controller: _warehouses,
      label: 'Number of Warehouses (Optional)',
      hint: 'e.g. 1, 2, 5',
      icon: Icons.warehouse_outlined,
      keyboardType: TextInputType.number,
      validator: (v) {
        final value = v?.trim() ?? '';
        if (value.isEmpty) return null;
        final count = int.tryParse(value);
        if (count == null || count < 1 || count > 10000) {
          return 'Enter a number from 1 to 10000.';
        }
        return null;
      },
    );
  }

  String? _validateWebsite(String? value) {
    final website = value?.trim() ?? '';
    if (website.isEmpty) return null;

    final uri = Uri.tryParse(
      website.startsWith('http') ? website : 'https://$website',
    );

    if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) {
      return 'Enter a valid website address.';
    }
    return null;
  }

  Widget _dropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> options,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, required: true),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          validator: (v) => v == null ? 'Please select $label.' : null,
          decoration: _decoration(hint, icon),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(
          label,
          required: label == 'Company Name' || label == 'Company Address',
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          maxLength: label == 'Company Address' ? 300 : null,
          textCapitalization: label == 'GST Number (Optional)'
              ? TextCapitalization.characters
              : TextCapitalization.sentences,
          onChanged: label == 'GST Number (Optional)'
              ? (v) {
                  final upper = v.toUpperCase();
                  if (upper != v) {
                    controller.value = controller.value.copyWith(
                      text: upper,
                      selection: TextSelection.collapsed(offset: upper.length),
                    );
                  }
                }
              : null,
          decoration: _decoration(hint, icon).copyWith(
            counterStyle: const TextStyle(color: _slate, fontSize: 11),
            alignLabelWithHint: maxLines > 1,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label, {required bool required}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8793A7), fontSize: 12),
      prefixIcon: Icon(icon, color: _slate, size: 21),
      filled: true,
      fillColor: const Color(0xFFFCFDFE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.4),
      ),
    );
  }
}
