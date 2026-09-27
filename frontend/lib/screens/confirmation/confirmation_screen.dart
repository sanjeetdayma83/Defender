import 'package:flutter/material.dart';
import '../../widgets/ux/ld_ux.dart';

class ConfirmationScreen extends StatelessWidget {
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback? onContinue;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const ConfirmationScreen({
    super.key,
    this.title = 'All set!',
    this.message = 'Your request has been completed successfully.',
    this.primaryLabel = 'Continue',
    this.onContinue,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LDUXColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: LDUXColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: LDUXColors.green.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 46,
                        color: LDUXColors.green,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: LDUXColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed:
                            onContinue ?? () => Navigator.maybePop(context),
                        child: Text(primaryLabel),
                      ),
                    ),
                    if (secondaryLabel != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed:
                              onSecondary ?? () => Navigator.maybePop(context),
                          child: Text(secondaryLabel!),
                        ),
                      ),
                    ],
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
