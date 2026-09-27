import 'package:flutter/material.dart';
import '../../widgets/ux/ld_ux.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;

  final List<_OnboardingStep> _steps = const [
    _OnboardingStep(
      icon: Icons.business_rounded,
      title: 'Set up your company',
      description:
          'Create your company workspace and define the basic operating information.',
    ),
    _OnboardingStep(
      icon: Icons.warehouse_rounded,
      title: 'Configure your warehouse',
      description: 'Add your primary warehouse and prepare your packing team.',
    ),
    _OnboardingStep(
      icon: Icons.upload_file_rounded,
      title: 'Import your orders',
      description:
          'Upload CSV or XLSX orders, map columns, validate and import them.',
    ),
    _OnboardingStep(
      icon: Icons.qr_code_scanner_rounded,
      title: 'Start Scan & Pack',
      description:
          'Scan the shipping barcode, verify the order and create packing evidence.',
    ),
  ];

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      return;
    }

    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final item = _steps[_step];

    return Scaffold(
      backgroundColor: LDUXColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: LDUXColors.blue.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, size: 44, color: LDUXColors.blue),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: LDUXColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _step ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _step
                              ? LDUXColors.blue
                              : LDUXColors.border,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(
                        _step == _steps.length - 1 ? 'Get Started' : 'Continue',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_step < _steps.length - 1)
                    TextButton(
                      onPressed: widget.onComplete,
                      child: const Text('Skip for now'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
  });
}
