import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/storage/storage_usage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_widgets.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onScanPack;

  const DashboardScreen({super.key, required this.onScanPack});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageUsageService _storageService = const StorageUsageService();

  StorageUsage? _storageUsage;

  bool _loadingStorage = true;
  String? _storageError;

  @override
  void initState() {
    super.initState();
    _loadStorageUsage();
  }

  Future<void> _loadStorageUsage() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loadingStorage = true;
      _storageError = null;
    });

    try {
      final usage = await _storageService.getUsage();

      if (!mounted) {
        return;
      }

      setState(() {
        _storageUsage = usage;
        _loadingStorage = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingStorage = false;
        _storageError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _storageValue() {
    if (_loadingStorage) {
      return '...';
    }

    if (_storageUsage == null) {
      return '—';
    }

    return _storageUsage!.displayValue;
  }

  String _videoValue() {
    if (_loadingStorage || _storageUsage == null) {
      return '—';
    }

    return '${_storageUsage!.videoCount}';
  }

  @override
  Widget build(BuildContext context) {
    final orders = <Order>[];

    final readyCount = orders
        .where((order) => order.status.toLowerCase().contains('ready'))
        .length;

    final evidenceCount = orders.where((order) => order.evidenceExists).length;

    return RefreshIndicator(
      onRefresh: _loadStorageUsage,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _hero(),

            const SizedBox(height: 22),

            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 950;

                final cards = [
                  _metric(
                    icon: Icons.inventory_2_outlined,
                    title: 'Total Orders',
                    value: '${orders.length}',
                    caption: 'Orders in workspace',
                    color: LDColors.blue,
                  ),
                  _metric(
                    icon: Icons.pending_actions_rounded,
                    title: 'Ready to Pack',
                    value: '$readyCount',
                    caption: 'Awaiting verification',
                    color: LDColors.warning,
                  ),
                  _metric(
                    icon: Icons.verified_rounded,
                    title: 'Evidence',
                    value: '$evidenceCount',
                    caption: 'Orders with proof',
                    color: LDColors.success,
                  ),
                  _metric(
                    icon: Icons.cloud_outlined,
                    title: 'Storage Used',
                    value: _storageValue(),
                    caption: 'Backblaze B2',
                    color: LDColors.cyan,
                  ),
                ];

                if (compact) {
                  return Column(
                    children: cards
                        .map(
                          (card) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: card,
                          ),
                        )
                        .toList(),
                  );
                }

                return Row(
                  children: [
                    for (int i = 0; i < cards.length; i++) ...[
                      Expanded(child: cards[i]),
                      if (i != cards.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 22),

            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 900) {
                  return Column(
                    children: [
                      _quickScanCard(),
                      const SizedBox(height: 16),
                      _storageCard(),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _quickScanCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _storageCard()),
                  ],
                );
              },
            ),

            const SizedBox(height: 22),

            _recentOrders(orders),
          ],
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 25, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LDColors.navy, LDColors.navyLight],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -55,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LDColors.blue.withValues(alpha: .12),
              ),
            ),
          ),
          Positioned(
            right: 70,
            bottom: -75,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LDColors.cyan.withValues(alpha: .07),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: LDColors.success.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: LDColors.success.withValues(alpha: .22),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: LDColors.success),
                        SizedBox(width: 6),
                        Text(
                          'WAREHOUSE ONLINE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Packing intelligence,\nwithout the guesswork.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                'Scan shipments, capture packing proof and keep every dispatch traceable.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 19),
              FilledButton.icon(
                onPressed: widget.onScanPack,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 19),
                label: const Text('Start Scan & Pack'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric({
    required IconData icon,
    required String title,
    required String value,
    required String caption,
    required Color color,
  }) {
    return LDCard(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: LDColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LDColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  caption,
                  style: const TextStyle(color: LDColors.subtle, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickScanCard() {
    return LDCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LDSectionHeader(
            title: 'Quick Scan',
            subtitle: 'Start a verified packing session',
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: LDColors.surfaceSoft,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: LDColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [LDColors.blue, LDColors.cyan],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan a shipping barcode',
                        style: TextStyle(
                          color: LDColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'The system identifies the shipment before recording starts.',
                        style: TextStyle(
                          color: LDColors.muted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: widget.onScanPack,
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _storageCard() {
    return LDCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LDSectionHeader(
            title: 'Evidence Storage',
            subtitle: 'Backblaze B2 media storage',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: LDColors.cyan.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.cloud_done_outlined,
                  color: LDColors.cyan,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _storageValue(),
                      style: const TextStyle(
                        color: LDColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Used storage',
                      style: const TextStyle(
                        color: LDColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: LDColors.border),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.video_library_outlined,
                size: 17,
                color: LDColors.muted,
              ),
              const SizedBox(width: 8),
              const Text(
                'Videos stored',
                style: TextStyle(color: LDColors.muted, fontSize: 11),
              ),
              const Spacer(),
              Text(
                _videoValue(),
                style: const TextStyle(
                  color: LDColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (_storageError != null) ...[
            const SizedBox(height: 12),
            Text(
              _storageError!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: LDColors.danger, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _recentOrders(List<Order> orders) {
    return LDCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 19, 20, 14),
            child: LDSectionHeader(
              title: 'Recent Orders',
              subtitle: 'Latest shipment activity',
              action: TextButton(
                onPressed: () {},
                child: const Text('View all'),
              ),
            ),
          ),
          const Divider(height: 1),
          ...orders.take(5).map((order) => _orderRow(order)),
        ],
      ),
    );
  }

  Widget _orderRow(Order order) {
    final verified = order.evidenceExists;

    return InkWell(
      onTap: widget.onScanPack,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: verified
                    ? LDColors.success.withValues(alpha: .09)
                    : LDColors.blue.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                verified ? Icons.verified_rounded : Icons.inventory_2_outlined,
                color: verified ? LDColors.success : LDColors.blue,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.awb,
                    style: const TextStyle(
                      color: LDColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${order.product.sku} • ${order.marketplace}',
                    style: const TextStyle(color: LDColors.muted, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            LDStatusBadge(
              text: verified ? 'Evidence Ready' : order.status,
              color: verified ? LDColors.success : LDColors.warning,
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: LDColors.subtle,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

