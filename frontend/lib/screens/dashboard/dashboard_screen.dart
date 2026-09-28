import 'package:flutter/material.dart';

import '../../services/dashboard/dashboard_api_service.dart';
import '../../services/storage/storage_usage_service.dart';
import '../screen_ui.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onScanPack;

  const DashboardScreen({super.key, required this.onScanPack});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardApiService _dashboard = DashboardApiService();
  final StorageUsageService _storage = const StorageUsageService();

  DashboardData? _data;
  StorageUsage? _storageUsage;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _dashboard.getCompanyDashboard(),
        _storage.getUsage(),
      ]);

      if (!mounted) return;

      setState(() {
        _data = results[0] as DashboardData;
        _storageUsage = results[1] as StorageUsage;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final metrics = data?.metrics;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LDPageHeader(
              title: data?.companyName ?? 'Company Dashboard',
              subtitle: data?.companyCode.isNotEmpty == true
                  ? 'Company code: ${data!.companyCode}'
                  : 'Live operational overview',
              action: OutlinedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              LDCard(
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!)),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            if (_loading && data == null)
              const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (metrics != null) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final cards = <Widget>[
                    _metric(
                      'Total Orders',
                      '${metrics.orders}',
                      Icons.inventory_2_outlined,
                      ldBlue,
                    ),
                    _metric(
                      'Ready to Pack',
                      '${metrics.pendingOrders}',
                      Icons.pending_actions_rounded,
                      ldAmber,
                    ),
                    _metric(
                      'Packing',
                      '${metrics.packingOrders}',
                      Icons.inventory_outlined,
                      ldAmber,
                    ),
                    _metric(
                      'Packed',
                      '${metrics.packedOrders}',
                      Icons.verified_outlined,
                      ldGreen,
                    ),
                  ];

                  if (constraints.maxWidth < 900) {
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
                      for (var i = 0; i < cards.length; i++) ...[
                        Expanded(child: cards[i]),
                        if (i != cards.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final storage = _storageUsage;

                  final storageCard = LDCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LDSectionTitle(
                          title: 'Evidence Storage',
                          subtitle: 'Backblaze B2',
                        ),
                        const SizedBox(height: 18),
                        Text(
                          storage?.displayValue ?? '—',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${storage?.videoCount ?? 0} video files',
                          style: const TextStyle(color: ldMute),
                        ),
                      ],
                    ),
                  );

                  final activity = LDCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LDSectionTitle(
                          title: 'Operational Status',
                          subtitle: 'Current company metrics',
                        ),
                        const SizedBox(height: 14),
                        _line('Products', '${metrics.products}'),
                        _line('Warehouses', '${metrics.warehouses}'),
                        _line('Active Users', '${metrics.users}'),
                        _line('Packing Sessions', '${metrics.sessions}'),
                        _line('Active Sessions', '${metrics.activeSessions}'),
                        _line('Evidence Items', '${metrics.evidence}'),
                      ],
                    ),
                  );

                  if (constraints.maxWidth < 900) {
                    return Column(
                      children: [
                        _quickScan(),
                        const SizedBox(height: 16),
                        storageCard,
                        const SizedBox(height: 16),
                        activity,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _quickScan()),
                      const SizedBox(width: 16),
                      Expanded(child: storageCard),
                      const SizedBox(width: 16),
                      Expanded(child: activity),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _metric(String title, String value, IconData icon, Color color) {
    return LDCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: ldMute, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickScan() {
    return LDCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LDSectionTitle(
            title: 'Quick Scan',
            subtitle: 'Start a verified packing session',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: widget.onScanPack,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('Start Scan & Pack'),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class LDPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const LDPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(subtitle, style: const TextStyle(color: ldMute)),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}
