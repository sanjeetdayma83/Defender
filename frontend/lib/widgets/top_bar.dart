import 'package:flutter/material.dart';

class LossDefenderTopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onScanPack;

  const LossDefenderTopBar({super.key, required this.title, this.onScanPack});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E7EC))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF172033),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF3),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 4, backgroundColor: Color(0xFF12B76A)),
                SizedBox(width: 8),
                Text(
                  'System Ready',
                  style: TextStyle(
                    color: Color(0xFF027A48),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (onScanPack != null)
            FilledButton.icon(
              onPressed: onScanPack,
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('Scan & Pack'),
            ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_outlined),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }
}
