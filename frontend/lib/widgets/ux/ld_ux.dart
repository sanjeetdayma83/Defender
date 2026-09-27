import 'package:flutter/material.dart';

class LDUXColors {
  static const navy = Color(0xFF0F172A);
  static const blue = Color(0xFF2563EB);
  static const cyan = Color(0xFF06B6D4);
  static const green = Color(0xFF16A34A);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFDC2626);
  static const background = Color(0xFFF8FAFC);
  static const border = Color(0xFFE2E8F0);
  static const text = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
}

enum LDMessageType { success, info, warning, danger }

class LDMessageBanner extends StatelessWidget {
  final LDMessageType type;
  final String title;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;
  final VoidCallback? onClose;

  const LDMessageBanner({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.action,
    this.actionLabel,
    this.onClose,
  });

  IconData get icon {
    switch (type) {
      case LDMessageType.success:
        return Icons.check_circle_rounded;
      case LDMessageType.info:
        return Icons.info_rounded;
      case LDMessageType.warning:
        return Icons.warning_amber_rounded;
      case LDMessageType.danger:
        return Icons.error_rounded;
    }
  }

  Color get accent {
    switch (type) {
      case LDMessageType.success:
        return LDUXColors.green;
      case LDMessageType.info:
        return LDUXColors.blue;
      case LDMessageType.warning:
        return LDUXColors.amber;
      case LDMessageType.danger:
        return LDUXColors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: LDUXColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: LDUXColors.muted, height: 1.45),
                ),
                if (action != null && actionLabel != null) ...[
                  const SizedBox(height: 10),
                  TextButton(onPressed: action, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

class LDConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final bool destructive;

  const LDConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.icon = Icons.help_outline_rounded,
    this.destructive = false,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    IconData icon = Icons.help_outline_rounded,
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LDConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        destructive: destructive,
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final color = destructive ? LDUXColors.red : LDUXColors.blue;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(color: LDUXColors.muted, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: color),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class LDLoadingState extends StatelessWidget {
  final String title;
  final String message;

  const LDLoadingState({
    super.key,
    this.title = 'Loading',
    this.message = 'Please wait while we prepare this page.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: LDUXColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class LDEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? action;

  const LDEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.actionLabel,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: LDUXColors.muted),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: LDUXColors.muted, height: 1.45),
              ),
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: action,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LDOfflineBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const LDOfflineBanner({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return LDMessageBanner(
      type: LDMessageType.warning,
      title: 'You are offline',
      message:
          'Some live data may be unavailable. Your packing workflow can continue where supported.',
      action: onRetry,
      actionLabel: 'Retry',
    );
  }
}

class LDSessionExpiredBanner extends StatelessWidget {
  final VoidCallback onLogin;

  const LDSessionExpiredBanner({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return LDMessageBanner(
      type: LDMessageType.danger,
      title: 'Session expired',
      message: 'Your secure session has expired. Sign in again to continue.',
      action: onLogin,
      actionLabel: 'Sign in',
    );
  }
}

void ldShowSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: LDUXColors.green,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

void ldShowWarning(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: LDUXColors.amber,
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

void ldShowError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: LDUXColors.red,
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
