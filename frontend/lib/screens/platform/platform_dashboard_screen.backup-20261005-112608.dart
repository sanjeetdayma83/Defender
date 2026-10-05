import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/dashboard/platform_dashboard_service.dart';

class PlatformDashboardScreen extends StatefulWidget {
  final ValueChanged<String>? onOpenSection;

  const PlatformDashboardScreen({super.key, this.onOpenSection});

  @override
  State<PlatformDashboardScreen> createState() =>
      _PlatformDashboardScreenState();
}

class _PlatformDashboardScreenState extends State<PlatformDashboardScreen> {
  final _service = const PlatformDashboardService();

  Future<PlatformDashboardData>? _future;

  static const _background = Color(0xFFF7F9FC);
  static const _navy = Color(0xFF101828);
  static const _muted = Color(0xFF667085);
  static const _border = Color(0xFFE4E7EC);
  static const _blue = Color(0xFF3155D8);
  static const _green = Color(0xFF12B76A);
  static const _orange = Color(0xFFF79009);
  static const _purple = Color(0xFF7F56D9);
  static const _red = Color(0xFFF04438);
  static const _cyan = Color(0xFF06AED4);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _service.fetch();
    });
  }

  void _open(String section) {
    widget.onOpenSection?.call(section);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: FutureBuilder<PlatformDashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString().replaceFirst(
                'Exception: ',
                '',
              ),
              onRetry: _reload,
            );
          }

          final data = snapshot.data ?? PlatformDashboardData.empty();

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            color: _blue,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1200;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    wide ? 30 : 20,
                    24,
                    wide ? 30 : 20,
                    40,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(data: data, onRefresh: _reload),
                          const SizedBox(height: 24),
                          _KpiGrid(data: data),
                          const SizedBox(height: 22),
                          _AnalyticsRow(data: data, wide: wide),
                          const SizedBox(height: 22),
                          _OverviewRow(data: data, wide: wide, onOpen: _open),
                          const SizedBox(height: 22),
                          _ActivityRow(data: data, wide: wide),
                          const SizedBox(height: 22),
                          _SystemHealth(data: data),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final PlatformDashboardData data;
  final VoidCallback onRefresh;

  const _Header({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, ${data.adminName.isEmpty ? 'Platform Admin' : data.adminName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _PlatformDashboardScreenState._navy,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Here is your platform performance overview.',
                style: TextStyle(
                  color: _PlatformDashboardScreenState._muted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        if (data.adminEmail.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxWidth: 260),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _PlatformDashboardScreenState._border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 15,
                  backgroundColor: _PlatformDashboardScreenState._blue,
                  child: Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    data.adminEmail,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _PlatformDashboardScreenState._navy,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 10),
        IconButton(
          tooltip: 'Refresh dashboard',
          onPressed: onRefresh,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(
              color: _PlatformDashboardScreenState._border,
            ),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 20),
        ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final PlatformDashboardData data;

  const _KpiGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final count = width >= 1250
        ? 5
        : width >= 850
        ? 3
        : 1;

    return GridView.count(
      crossAxisCount: count,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: width >= 850 ? 1.9 : 2.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _KpiCard(
          title: 'Total Revenue',
          value: _money(data.revenueTotalPaise),
          subtitle: '${data.revenuePaidPaymentCount} paid payments',
          icon: Icons.payments_outlined,
          iconColor: _PlatformDashboardScreenState._green,
          trend: 'Live',
        ),
        _KpiCard(
          title: 'Subscriptions',
          value: '${data.activeSubscriptions}',
          subtitle: 'Active subscriptions',
          icon: Icons.card_membership_outlined,
          iconColor: _PlatformDashboardScreenState._purple,
          trend: 'Live',
        ),
        _KpiCard(
          title: 'Total Users',
          value: '${data.totalUsers}',
          subtitle: '${data.activeUsers} active',
          icon: Icons.people_outline_rounded,
          iconColor: _PlatformDashboardScreenState._blue,
          trend: 'Live',
        ),
        _KpiCard(
          title: 'Companies',
          value: '${data.totalCompanies}',
          subtitle: '${data.activeCompanies} active',
          icon: Icons.business_outlined,
          iconColor: _PlatformDashboardScreenState._orange,
          trend: 'Live',
        ),
        _KpiCard(
          title: 'Storage Used',
          value: _bytes(data.storageUsedBytes),
          subtitle:
              '${_percent(data.storageUsedBytes, data.storageQuotaBytes)}% of quota',
          icon: Icons.cloud_outlined,
          iconColor: _PlatformDashboardScreenState._cyan,
          trend: 'Live',
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final String trend;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _PlatformDashboardScreenState._muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        trend,
                        style: const TextStyle(
                          color: Color(0xFF027A48),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: _PlatformDashboardScreenState._navy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _PlatformDashboardScreenState._muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsRow extends StatefulWidget {
  final PlatformDashboardData data;
  final bool wide;

  const _AnalyticsRow({required this.data, required this.wide});

  @override
  State<_AnalyticsRow> createState() => _AnalyticsRowState();
}

class _AnalyticsRowState extends State<_AnalyticsRow> {
  int _rangeMonths = 6;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    final revenue = _DashboardCard(
      title: 'Revenue & Growth',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _PlatformDashboardScreenState._border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _rangeMonths,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
                style: const TextStyle(
                  color: _PlatformDashboardScreenState._navy,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
                items: const [
                  DropdownMenuItem(value: 3, child: Text('Last 3 months')),
                  DropdownMenuItem(value: 6, child: Text('Last 6 months')),
                  DropdownMenuItem(value: 12, child: Text('Last 12 months')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _rangeMonths = value);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _LivePill(),
        ],
      ),
      child: SizedBox(
        height: 285,
        child: _RevenueChart(
          revenue: _takeLast(data.revenueMonthly, _rangeMonths),
          users: _takeLast(data.monthlyUsers, _rangeMonths),
          subscriptions: _takeLast(data.monthlySubscriptions, _rangeMonths),
        ),
      ),
    );

    final storage = _DashboardCard(
      title: 'Storage Usage',
      trailing: Text(
        _percentText(data.storageUsedBytes, data.storageQuotaBytes),
        style: const TextStyle(
          color: _PlatformDashboardScreenState._blue,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      child: SizedBox(height: 285, child: _StorageChart(data: data)),
    );

    if (widget.wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: revenue),
          const SizedBox(width: 18),
          Expanded(child: storage),
        ],
      );
    }

    return Column(children: [revenue, const SizedBox(height: 18), storage]);
  }
}

List<T> _takeLast<T>(List<T> items, int count) {
  if (items.length <= count) return items;
  return items.sublist(items.length - count);
}

class _RevenueChart extends StatelessWidget {
  final List<PlatformRevenuePoint> revenue;
  final List<PlatformGrowthPoint> users;
  final List<PlatformGrowthPoint> subscriptions;

  const _RevenueChart({
    required this.revenue,
    required this.users,
    required this.subscriptions,
  });

  @override
  Widget build(BuildContext context) {
    if (revenue.isEmpty) {
      return const _EmptyChart();
    }

    final userByMonth = <String, PlatformGrowthPoint>{
      for (final item in users) item.month: item,
    };

    final subscriptionByMonth = <String, PlatformGrowthPoint>{
      for (final item in subscriptions) item.month: item,
    };

    final alignedUsers = revenue
        .map((item) => userByMonth[item.month]?.value ?? 0)
        .toList();

    final alignedSubscriptions = revenue
        .map((item) => subscriptionByMonth[item.month]?.value ?? 0)
        .toList();

    final revenueValues = revenue
        .map((item) => item.revenuePaise.toDouble())
        .toList();

    final maxRevenue = revenueValues.fold<double>(
      0,
      (previous, value) => math.max(previous, value),
    );

    final maxUsers = alignedUsers.fold<int>(
      0,
      (previous, value) => math.max(previous, value),
    );

    final maxSubscriptions = alignedSubscriptions.fold<int>(
      0,
      (previous, value) => math.max(previous, value),
    );

    final maxCount = math.max(maxUsers, maxSubscriptions);

    return Column(
      children: [
        Row(
          children: [
            _ChartLegendItem(
              label: 'Revenue',
              color: _PlatformDashboardScreenState._blue,
              bar: true,
            ),
            const SizedBox(width: 16),
            _ChartLegendItem(
              label: 'Users',
              color: _PlatformDashboardScreenState._purple,
            ),
            const SizedBox(width: 16),
            _ChartLegendItem(
              label: 'Subscriptions',
              color: _PlatformDashboardScreenState._green,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 44, child: _RevenueYAxis(maxRevenue: maxRevenue)),
              Expanded(
                child: CustomPaint(
                  painter: _RevenueGrowthPainter(
                    revenue: revenueValues,
                    users: alignedUsers,
                    subscriptions: alignedSubscriptions,
                    maxRevenue: maxRevenue,
                    maxCount: maxCount,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              SizedBox(width: 36, child: _CountYAxis(maxCount: maxCount)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 44),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: revenue.map((point) {
              return Expanded(
                child: Text(
                  point.month,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _PlatformDashboardScreenState._muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool bar;

  const _ChartLegendItem({
    required this.label,
    required this.color,
    this.bar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: bar ? 12 : 18,
          height: bar ? 8 : 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _PlatformDashboardScreenState._muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RevenueYAxis extends StatelessWidget {
  final double maxRevenue;

  const _RevenueYAxis({required this.maxRevenue});

  @override
  Widget build(BuildContext context) {
    final top = _compactMoney(maxRevenue);
    final middle = _compactMoney(maxRevenue / 2);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          top,
          style: const TextStyle(
            color: _PlatformDashboardScreenState._muted,
            fontSize: 9,
          ),
        ),
        Text(
          middle,
          style: const TextStyle(
            color: _PlatformDashboardScreenState._muted,
            fontSize: 9,
          ),
        ),
        const Text(
          '₹0',
          style: TextStyle(
            color: _PlatformDashboardScreenState._muted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _CountYAxis extends StatelessWidget {
  final int maxCount;

  const _CountYAxis({required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final middle = maxCount / 2;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _compactCount(maxCount),
          style: const TextStyle(
            color: _PlatformDashboardScreenState._muted,
            fontSize: 9,
          ),
        ),
        Text(
          _compactCount(middle.round()),
          style: const TextStyle(
            color: _PlatformDashboardScreenState._muted,
            fontSize: 9,
          ),
        ),
        const Text(
          '0',
          style: TextStyle(
            color: _PlatformDashboardScreenState._muted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

class _RevenueGrowthPainter extends CustomPainter {
  final List<double> revenue;
  final List<int> users;
  final List<int> subscriptions;
  final double maxRevenue;
  final int maxCount;

  _RevenueGrowthPainter({
    required this.revenue,
    required this.users,
    required this.subscriptions,
    required this.maxRevenue,
    required this.maxCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (revenue.isEmpty) return;

    const horizontalPadding = 8.0;
    const verticalPadding = 8.0;

    final chartWidth = math.max(1.0, size.width - horizontalPadding * 2);

    final chartHeight = math.max(1.0, size.height - verticalPadding * 2);

    final count = revenue.length;
    final stepX = count <= 1 ? 0.0 : chartWidth / (count - 1);

    final gridPaint = Paint()
      ..color = _PlatformDashboardScreenState._border.withValues(alpha: .65)
      ..strokeWidth = 1;

    for (var i = 0; i < 5; i++) {
      final y = verticalPadding + (chartHeight * i / 4);
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(size.width - horizontalPadding, y),
        gridPaint,
      );
    }

    final barPaint = Paint()
      ..color = _PlatformDashboardScreenState._blue.withValues(alpha: .14);

    final barWidth = count <= 3
        ? 28.0
        : math.min(34.0, chartWidth / count * .48);

    for (var i = 0; i < revenue.length; i++) {
      final normalized = maxRevenue <= 0
          ? 0.0
          : (revenue[i] / maxRevenue).clamp(0.0, 1.0);

      final barHeight = chartHeight * normalized;
      final x = count == 1 ? size.width / 2 : horizontalPadding + (stepX * i);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x - barWidth / 2,
          verticalPadding + chartHeight - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(5),
      );

      canvas.drawRRect(rect, barPaint);
    }

    _drawLine(
      canvas: canvas,
      values: users,
      maxValue: maxCount,
      color: _PlatformDashboardScreenState._purple,
      size: size,
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      stepX: stepX,
    );

    _drawLine(
      canvas: canvas,
      values: subscriptions,
      maxValue: maxCount,
      color: _PlatformDashboardScreenState._green,
      size: size,
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
      chartWidth: chartWidth,
      chartHeight: chartHeight,
      stepX: stepX,
    );
  }

  void _drawLine({
    required Canvas canvas,
    required List<int> values,
    required int maxValue,
    required Color color,
    required Size size,
    required double horizontalPadding,
    required double verticalPadding,
    required double chartWidth,
    required double chartHeight,
    required double stepX,
  }) {
    if (values.isEmpty) return;

    final path = Path();

    for (var i = 0; i < values.length; i++) {
      final normalized = maxValue <= 0
          ? 0.0
          : (values[i] / maxValue).clamp(0.0, 1.0);

      final x = values.length == 1
          ? size.width / 2
          : horizontalPadding + (stepX * i);

      final y = verticalPadding + chartHeight - (chartHeight * normalized);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()..color = color;

    for (var i = 0; i < values.length; i++) {
      final normalized = maxValue <= 0
          ? 0.0
          : (values[i] / maxValue).clamp(0.0, 1.0);

      final x = values.length == 1
          ? size.width / 2
          : horizontalPadding + (stepX * i);

      final y = verticalPadding + chartHeight - (chartHeight * normalized);

      canvas.drawCircle(Offset(x, y), 3.2, pointPaint);

      final innerPaint = Paint()..color = Colors.white;

      canvas.drawCircle(Offset(x, y), 1.25, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueGrowthPainter oldDelegate) {
    return oldDelegate.revenue != revenue ||
        oldDelegate.users != users ||
        oldDelegate.subscriptions != subscriptions ||
        oldDelegate.maxRevenue != maxRevenue ||
        oldDelegate.maxCount != maxCount;
  }
}

class _StorageChart extends StatelessWidget {
  final PlatformDashboardData data;

  const _StorageChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final percent = _percent(data.storageUsedBytes, data.storageQuotaBytes);

    return Row(
      children: [
        Expanded(
          child: Center(
            child: SizedBox(
              width: 155,
              height: 155,
              child: CustomPaint(
                painter: _DonutPainter(
                  percent: percent / 100,
                  color: _PlatformDashboardScreenState._blue,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: _PlatformDashboardScreenState._navy,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'used',
                        style: TextStyle(
                          color: _PlatformDashboardScreenState._muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StorageLegend(
                label: 'Used',
                value: _bytes(data.storageUsedBytes),
                color: _PlatformDashboardScreenState._blue,
              ),
              const SizedBox(height: 16),
              _StorageLegend(
                label: 'Available',
                value: _bytes(data.storageAvailableBytes),
                color: const Color(0xFFD0D5DD),
              ),
              const SizedBox(height: 16),
              _StorageLegend(
                label: 'Quota',
                value: _bytes(data.storageQuotaBytes),
                color: _PlatformDashboardScreenState._muted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double percent;
  final Color color;

  _DonutPainter({required this.percent, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 10;

    final background = Paint()
      ..color = const Color(0xFFEFF2F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    final foreground = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, background);

    final safePercent = percent.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * safePercent,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.color != color;
  }
}

class _OverviewRow extends StatelessWidget {
  final PlatformDashboardData data;
  final bool wide;
  final ValueChanged<String> onOpen;

  const _OverviewRow({
    required this.data,
    required this.wide,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final subscriptions = _DashboardCard(
      title: 'Subscription Status',
      trailing: Text(
        '${data.activeSubscriptions} active',
        style: const TextStyle(
          color: _PlatformDashboardScreenState._green,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: _StatusBars(
        items: data.subscriptionStatus,
        activeColor: _PlatformDashboardScreenState._green,
      ),
    );

    final users = _DashboardCard(
      title: 'Users & Access',
      trailing: Text(
        '${data.totalUsers} total',
        style: const TextStyle(
          color: _PlatformDashboardScreenState._muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: _UserAccess(data: data),
    );

    final companies = _DashboardCard(
      title: 'Companies Overview',
      trailing: TextButton(
        onPressed: () => onOpen('companies'),
        child: const Text('View all'),
      ),
      child: _CompanyOverview(data: data),
    );

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: subscriptions),
          const SizedBox(width: 18),
          Expanded(child: users),
          const SizedBox(width: 18),
          Expanded(child: companies),
        ],
      );
    }

    return Column(
      children: [
        subscriptions,
        const SizedBox(height: 18),
        users,
        const SizedBox(height: 18),
        companies,
      ],
    );
  }
}

class _StatusBars extends StatelessWidget {
  final List<PlatformStatusItem> items;
  final Color activeColor;

  const _StatusBars({required this.items, required this.activeColor});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyContent();
    }

    final total = items.fold<int>(0, (sum, item) => sum + item.count);

    return Column(
      children: items.map((item) {
        final fraction = total == 0 ? 0.0 : item.count / total;

        final normalized = item.status.toLowerCase();

        final color = normalized == 'active'
            ? activeColor
            : normalized == 'cancelled'
            ? _PlatformDashboardScreenState._red
            : _PlatformDashboardScreenState._orange;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _titleCase(item.status),
                      style: const TextStyle(
                        color: _PlatformDashboardScreenState._navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${item.count}',
                    style: const TextStyle(
                      color: _PlatformDashboardScreenState._navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: fraction,
                  backgroundColor: const Color(0xFFF2F4F7),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _UserAccess extends StatelessWidget {
  final PlatformDashboardData data;

  const _UserAccess({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AccessRow(
          icon: Icons.admin_panel_settings_outlined,
          label: 'Platform Admins',
          value: data.platformAdmins,
          color: _PlatformDashboardScreenState._purple,
        ),
        _AccessRow(
          icon: Icons.business_center_outlined,
          label: 'Company Admins',
          value: data.companyAdmins,
          color: _PlatformDashboardScreenState._blue,
        ),
        _AccessRow(
          icon: Icons.badge_outlined,
          label: 'Operators',
          value: data.operators,
          color: _PlatformDashboardScreenState._orange,
        ),
        _AccessRow(
          icon: Icons.check_circle_outline,
          label: 'Active Users',
          value: data.activeUsers,
          color: _PlatformDashboardScreenState._green,
        ),
      ],
    );
  }
}

class _AccessRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _AccessRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _PlatformDashboardScreenState._navy,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              color: _PlatformDashboardScreenState._navy,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyOverview extends StatelessWidget {
  final PlatformDashboardData data;

  const _CompanyOverview({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniMetric(
                value: data.totalCompanies,
                label: 'Total',
                color: _PlatformDashboardScreenState._blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniMetric(
                value: data.activeCompanies,
                label: 'Active',
                color: _PlatformDashboardScreenState._green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniMetric(
                value: data.newCompaniesThisMonth,
                label: 'New',
                color: _PlatformDashboardScreenState._orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _ProgressStat(
                label: 'Active companies',
                value: data.totalCompanies == 0
                    ? 0
                    : data.activeCompanies / data.totalCompanies,
                color: _PlatformDashboardScreenState._green,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _MiniMetric({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: _PlatformDashboardScreenState._muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _PlatformDashboardScreenState._muted,
                  fontSize: 10.5,
                ),
              ),
            ),
            Text(
              '${(value.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: value.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFF2F4F7),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final PlatformDashboardData data;
  final bool wide;

  const _ActivityRow({required this.data, required this.wide});

  @override
  Widget build(BuildContext context) {
    final topups = _DashboardCard(
      title: 'Recent Top-ups',
      trailing: _LivePill(text: '${data.walletBalance} balance'),
      child: _TopupsList(data: data),
    );

    final users = _DashboardCard(
      title: 'Recent Users',
      child: _UsersList(data: data),
    );

    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: topups),
          const SizedBox(width: 18),
          Expanded(child: users),
        ],
      );
    }

    return Column(children: [topups, const SizedBox(height: 18), users]);
  }
}

class _TopupsList extends StatelessWidget {
  final PlatformDashboardData data;

  const _TopupsList({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.recentTopups.isEmpty) {
      return const _EmptyContent();
    }

    return Column(
      children: data.recentTopups.take(5).map((topup) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_card_outlined,
                  size: 17,
                  color: Color(0xFF039855),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topup.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _PlatformDashboardScreenState._navy,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _titleCase(topup.type),
                      style: const TextStyle(
                        color: _PlatformDashboardScreenState._muted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '+${topup.credits}',
                style: const TextStyle(
                  color: Color(0xFF027A48),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _UsersList extends StatelessWidget {
  final PlatformDashboardData data;

  const _UsersList({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.recentUsers.isEmpty) {
      return const _EmptyContent();
    }

    return Column(
      children: data.recentUsers.take(5).map((user) {
        final initials = user.name.trim().isEmpty
            ? 'U'
            : user.name
                  .trim()
                  .split(RegExp(r'\s+'))
                  .take(2)
                  .map((e) => e.substring(0, 1))
                  .join()
                  .toUpperCase();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: _avatarColor(user.name),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _PlatformDashboardScreenState._navy,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      user.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _PlatformDashboardScreenState._muted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: user.status),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SystemHealth extends StatelessWidget {
  final PlatformDashboardData data;

  const _SystemHealth({required this.data});

  @override
  Widget build(BuildContext context) {
    final recordingTotal = data.recordingStatus.fold<int>(
      0,
      (sum, item) => sum + item.count,
    );

    final evidenceTotal = data.evidenceStatus.fold<int>(
      0,
      (sum, item) => sum + item.count,
    );

    return _DashboardCard(
      title: 'System Health',
      trailing: const _LivePill(text: 'Operational'),
      child: Row(
        children: [
          Expanded(
            child: _HealthItem(
              icon: Icons.inventory_2_outlined,
              label: 'Orders',
              value: '${data.metrics.totalOrders}',
              color: _PlatformDashboardScreenState._blue,
            ),
          ),
          Expanded(
            child: _HealthItem(
              icon: Icons.videocam_outlined,
              label: 'Packing Sessions',
              value: '$recordingTotal',
              color: _PlatformDashboardScreenState._purple,
            ),
          ),
          Expanded(
            child: _HealthItem(
              icon: Icons.perm_media_outlined,
              label: 'Evidence',
              value: '$evidenceTotal',
              color: _PlatformDashboardScreenState._cyan,
            ),
          ),
          Expanded(
            child: _HealthItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Wallet Balance',
              value: '${data.walletBalance}',
              color: _PlatformDashboardScreenState._green,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HealthItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _PlatformDashboardScreenState._navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _PlatformDashboardScreenState._muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _PlatformDashboardScreenState._navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (trailing case final Widget widget) widget,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  final String text;

  const _LivePill({this.text = 'Live'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: Color(0xFF12B76A),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF027A48),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status.toLowerCase() == 'active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECFDF3) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _titleCase(status),
        style: TextStyle(
          color: active ? const Color(0xFF027A48) : const Color(0xFFB54708),
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StorageLegend extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StorageLegend({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _PlatformDashboardScreenState._muted,
              fontSize: 10.5,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _PlatformDashboardScreenState._navy,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyContent extends StatelessWidget {
  const _EmptyContent();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 90,
      child: Center(
        child: Text(
          'No live data available',
          style: TextStyle(
            color: _PlatformDashboardScreenState._muted,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No revenue data available',
        style: TextStyle(
          color: _PlatformDashboardScreenState._muted,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: _PlatformDashboardScreenState._red,
              size: 38,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load dashboard',
              style: TextStyle(
                color: _PlatformDashboardScreenState._navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _PlatformDashboardScreenState._muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFE4E7EC)),
    boxShadow: const [
      BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
    ],
  );
}

String _money(int paise) {
  final rupees = paise / 100;

  if (rupees >= 10000000) {
    return '₹${(rupees / 10000000).toStringAsFixed(1)}Cr';
  }

  if (rupees >= 100000) {
    return '₹${(rupees / 100000).toStringAsFixed(1)}L';
  }

  if (rupees >= 1000) {
    return '₹${(rupees / 1000).toStringAsFixed(1)}K';
  }

  return '₹${rupees.toStringAsFixed(0)}';
}

String _bytes(int bytes) {
  if (bytes <= 0) return '0 B';

  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var index = 0;

  while (value >= 1024 && index < units.length - 1) {
    value /= 1024;
    index++;
  }

  if (index == 0) {
    return '${value.toStringAsFixed(0)} ${units[index]}';
  }

  return '${value.toStringAsFixed(value >= 10 ? 1 : 2)} ${units[index]}';
}

double _percent(int used, int quota) {
  if (quota <= 0) return 0;
  return ((used / quota) * 100).clamp(0, 100).toDouble();
}

String _percentText(int used, int quota) {
  return '${_percent(used, quota).toStringAsFixed(2)}%';
}

String _compactMoney(double paise) {
  final rupees = paise / 100;

  if (rupees >= 10000000) {
    return '₹${(rupees / 10000000).toStringAsFixed(1)}Cr';
  }

  if (rupees >= 100000) {
    return '₹${(rupees / 100000).toStringAsFixed(1)}L';
  }

  if (rupees >= 1000) {
    return '₹${(rupees / 1000).toStringAsFixed(1)}K';
  }

  return '₹${rupees.toStringAsFixed(0)}';
}

String _compactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }

  return value.toString();
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .where((e) => e.isNotEmpty)
      .map(
        (word) =>
            '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

Color _avatarColor(String value) {
  const colors = [
    Color(0xFF3155D8),
    Color(0xFF7F56D9),
    Color(0xFF06AED4),
    Color(0xFF12B76A),
    Color(0xFFF79009),
  ];

  var hash = 0;

  for (final unit in value.codeUnits) {
    hash = (hash + unit) & 0x7fffffff;
  }

  return colors[hash % colors.length];
}
