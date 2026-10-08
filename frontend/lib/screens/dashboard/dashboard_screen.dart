import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/session_provider.dart';
import '../../services/dashboard/dashboard_api_service.dart';
import '../../services/orders/order_service.dart';
import '../screen_ui.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onScanPack;

  const DashboardScreen({super.key, required this.onScanPack});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dashboard = DashboardApiService();
  final _ordersApi = OrderService();

  DashboardData? _data;
  List<Order> _orders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await Future.wait<dynamic>([
        _dashboard.getCompanyDashboard(),
        _ordersApi.getOrders(),
      ]);

      if (!mounted) return;

      setState(() {
        _data = result[0] as DashboardData;
        _orders = result[1] as List<Order>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _data?.metrics;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 22),
            if (_error != null) _errorBanner(),
            _metricsGrid(metrics),
            const SizedBox(height: 18),
            _statusAndMarketplaces(),
            const SizedBox(height: 18),
            _recentAndQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning, ${_greetingName()}!',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF071A46),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Here\'s what\'s happening with your warehouse today.',
                style: TextStyle(fontSize: 16, color: Color(0xFF53698F)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        FilledButton.icon(
          onPressed: widget.onScanPack,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Start Scanning'),
        ),
      ],
    );
  }

  Widget _metricsGrid(DashboardMetrics? metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200
            ? 5
            : constraints.maxWidth >= 800
            ? 3
            : 1;

        return _grid(columns, [
          _metric(
            'Total Orders',
            _loading ? '—' : '${metrics?.orders ?? 0}',
            Icons.inventory_2_outlined,
            const Color(0xFF0061FC),
          ),
          _metric(
            'Packed Orders',
            _loading ? '—' : '${metrics?.packedOrders ?? 0}',
            Icons.check_circle_outline,
            const Color(0xFF16A34A),
          ),
          _metric(
            'Pending Orders',
            _loading ? '—' : '${metrics?.pendingOrders ?? 0}',
            Icons.schedule_outlined,
            const Color(0xFFF59E0B),
          ),
          _metric(
            'Packing Now',
            _loading ? '—' : '${metrics?.packingOrders ?? 0}',
            Icons.local_shipping_outlined,
            const Color(0xFFEF4444),
          ),
          _metric(
            'Evidence',
            _loading ? '—' : '${metrics?.evidence ?? 0}',
            Icons.verified_outlined,
            const Color(0xFF7C3AED),
          ),
        ]);
      },
    );
  }

  Widget _statusAndMarketplaces() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _statusCard()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _marketplaces()),
            ],
          );
        }

        return Column(
          children: [
            _statusCard(),
            const SizedBox(height: 16),
            _marketplaces(),
          ],
        );
      },
    );
  }

  Widget _recentAndQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        final recent = _recentOrders();

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _recent(recent)),
              const SizedBox(width: 16),
              SizedBox(width: 330, child: _quickActions()),
            ],
          );
        }

        return Column(
          children: [
            _recent(recent),
            const SizedBox(height: 16),
            _quickActions(),
          ],
        );
      },
    );
  }

  String _greetingName() {
    final name = context.read<SessionProvider>().user?.name.trim();

    return name?.isNotEmpty == true ? name! : 'there';
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFC2410C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFF9A3412)),
            ),
          ),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDCE6F3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .025),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
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
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF071A46),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(int columns, List<Widget> children) {
    final rows = <Widget>[];

    for (var i = 0; i < children.length; i += columns) {
      final end = (i + columns).clamp(0, children.length).toInt();
      final chunk = children.sublist(i, end);

      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: chunk
              .map(
                (widget) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: chunk.length > 1 ? 12 : 0,
                      bottom: 12,
                    ),
                    child: widget,
                  ),
                ),
              )
              .toList(),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _panel({
    required String title,
    required Widget child,
    String? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFDCE6F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF071A46),
                  ),
                ),
              ),
              if (action != null)
                TextButton(onPressed: () {}, child: Text(action)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _statusCard() {
    final metrics = _data?.metrics;

    return _panel(
      title: 'Order Status',
      child: Row(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _RingPainter(metrics),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${metrics?.orders ?? 0}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF071A46),
                        ),
                      ),
                      const Text(
                        'Total Orders',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: [
                _legend(
                  'Packed',
                  metrics?.packedOrders ?? 0,
                  const Color(0xFF0061FC),
                ),
                _legend(
                  'Pending',
                  metrics?.pendingOrders ?? 0,
                  const Color(0xFFF59E0B),
                ),
                _legend(
                  'Packing',
                  metrics?.packingOrders ?? 0,
                  const Color(0xFF16A34A),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF53698F), fontSize: 12),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF071A46),
            ),
          ),
        ],
      ),
    );
  }

  Widget _marketplaces() {
    final counts = <String, int>{};

    for (final order in _orders) {
      final key = order.marketplace.trim().isEmpty
          ? 'Other'
          : order.marketplace;

      counts[key] = (counts[key] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return _panel(
        title: 'Top Marketplaces',
        child: const LDEmpty(
          icon: Icons.storefront_outlined,
          title: 'No marketplace data',
          subtitle:
              'Marketplace distribution will appear when orders are available.',
        ),
      );
    }

    return _panel(
      title: 'Top Marketplaces',
      child: Column(
        children: sorted.take(5).map((entry) {
          final progress = _orders.isEmpty ? 0.0 : entry.value / _orders.length;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF253858),
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${entry.value}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Order> _recentOrders() {
    return _orders.take(6).toList();
  }

  Widget _recent(List<Order> rows) {
    return _panel(
      title: 'Recent Orders',
      action: 'View All',
      child: rows.isEmpty
          ? const LDEmpty(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'Orders received for this workspace will appear here.',
            )
          : Column(
              children: rows.map((order) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEEF2F7)),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          order.orderId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF071A46),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          order.marketplace,
                          style: const TextStyle(color: Color(0xFF53698F)),
                        ),
                      ),
                      SizedBox(width: 45, child: Text('${order.quantity}')),
                      LDStatus(
                        text: order.status.toUpperCase(),
                        color: _statusColor(order.status),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _quickActions() {
    return _panel(
      title: 'Quick Actions',
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onScanPack,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Start Scanning'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('View Orders'),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Actions that require an API are kept disabled until the endpoint is available.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    final value = status.toLowerCase();

    if (value.contains('pack')) {
      return const Color(0xFF16A34A);
    }

    if (value.contains('pending')) {
      return const Color(0xFFF59E0B);
    }

    if (value.contains('issue') || value.contains('fail')) {
      return const Color(0xFFDC2626);
    }

    return const Color(0xFF0061FC);
  }
}

class _RingPainter extends CustomPainter {
  final DashboardMetrics? metrics;

  _RingPainter(this.metrics);

  @override
  void paint(Canvas canvas, Size size) {
    final total = metrics?.orders ?? 0;
    final packed = metrics?.packedOrders ?? 0;
    final pending = metrics?.pendingOrders ?? 0;
    final packing = metrics?.packingOrders ?? 0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.butt;

    final radius = (size.shortestSide - 20) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, paint..color = const Color(0xFFE8EEF7));

    if (total <= 0) return;

    var start = -1.5708;

    final values = [packed, pending, packing];

    final colors = [
      const Color(0xFF0061FC),
      const Color(0xFFF59E0B),
      const Color(0xFF16A34A),
    ];

    for (var i = 0; i < values.length; i++) {
      final sweep = 6.28318 * values[i] / total;

      if (sweep > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          start,
          sweep,
          false,
          paint..color = colors[i],
        );
      }

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.metrics != metrics;
  }
}
