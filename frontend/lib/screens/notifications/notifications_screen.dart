// ignore_for_file: unnecessary_underscores
// ignore_for_file: no_leading_underscores_for_local_identifiers
import 'package:flutter/material.dart';
import '../../widgets/ux/ld_ux.dart';

class LDNotificationItem {
  final String title;
  final String message;
  final DateTime time;
  final LDMessageType type;
  bool unread;

  LDNotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.unread = true,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<LDNotificationItem> _items = [
    LDNotificationItem(
      title: 'Welcome to Loss Defender',
      message: 'Complete your profile and warehouse setup to continue.',
      time: DateTime.now(),
      type: LDMessageType.info,
    ),
    LDNotificationItem(
      title: 'Packing workflow ready',
      message: 'Your Scan & Pack workflow is ready to use.',
      time: DateTime.now(),
      type: LDMessageType.success,
    ),
    LDNotificationItem(
      title: 'Marketplace APIs',
      message:
          'Amazon, Flipkart and Meesho integrations are currently coming soon.',
      time: DateTime.now(),
      type: LDMessageType.warning,
    ),
  ];

  IconData _icon(LDMessageType type) {
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

  Color _color(LDMessageType type) {
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
    final unread = _items.where((item) => item.unread).length;

    return Scaffold(
      backgroundColor: LDUXColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: LDUXColors.text,
        elevation: 0,
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (final item in _items) {
                    item.unread = false;
                  }
                });
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _items.isEmpty
          ? const LDEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              message: 'Important updates and alerts will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _items.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 10);
              },
              itemBuilder: (context, index) {
                final item = _items[index];
                final color = _color(item.type);

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      item.unread = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.unread
                            ? color.withValues(alpha: 0.25)
                            : LDUXColors.border,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_icon(item.type), color: color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontWeight: item.unread
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (item.unread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: LDUXColors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.message,
                                style: const TextStyle(
                                  color: LDUXColors.muted,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Just now',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
