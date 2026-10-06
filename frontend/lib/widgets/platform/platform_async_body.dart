import 'package:flutter/material.dart';

class PlatformAsyncBody extends StatelessWidget {
  final AsyncSnapshot snap;
  final VoidCallback onRetry;
  final Widget Function(BuildContext context) builder;
  final String emptyMessage;

  const PlatformAsyncBody({
    super.key,
    required this.snap,
    required this.onRetry,
    required this.builder,
    this.emptyMessage = 'No data found.',
  });

  @override
  Widget build(BuildContext context) {
    if (snap.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snap.hasError) {
      return PlatformErrorPage(message: '${snap.error}', onRetry: onRetry);
    }
    return builder(context);
  }
}

class PlatformErrorPage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String title;

  const PlatformErrorPage({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Something went wrong',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PlatformEmptyPage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const PlatformEmptyPage({
    super.key,
    this.message = 'No data found.',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 44, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Refresh')),
          ],
        ],
      ),
    );
  }
}
