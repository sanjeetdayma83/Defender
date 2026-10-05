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

  static const _navy = Color(0xFF0F172A);
  static const _blue = Color(0xFF2563EB);
  static const _blueLight = Color(0xFFEFF6FF);
  static const _green = Color(0xFF059669);
  static const _greenLight = Color(0xFFECFDF5);
  static const _orange = Color(0xFFF59E0B);
  static const _orangeLight = Color(0xFFFFF7ED);
  static const _violet = Color(0xFF7C3AED);
  static const _violetLight = Color(0xFFF5F3FF);
  static const _cyan = Color(0xFF0891B2);
  static const _cyanLight = Color(0xFFECFEFF);
  static const _text = Color(0xFF172554);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);
  static const _surface = Colors.white;
  static const _background = Color(0xFFF8FAFC);

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
    return FutureBuilder<PlatformDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _DashboardLoading();
        }

        if (snapshot.hasError) {
          return _DashboardError(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
            onRetry: _reload,
          );
        }

        final data = snapshot.data ?? PlatformDashboardData.empty();

        return Container(
          color: _background,
          child: RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _future;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    width < 700 ? 16 : 24,
                    width < 700 ? 16 : 22,
                    width < 700 ? 16 : 24,
                    32,
                  ),
                  children: [
                    _PageHeader(
                      data: data,
                      onExport: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Export action will be connected to the reporting API.',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _DashboardTabs(selected: 'Overview', onSelected: _open),
                    const SizedBox(height: 18),
                    _KpiSection(data: data),
                    const SizedBox(height: 18),
                    _PrimaryAnalytics(data: data, wide: width >= 1100),
                    const SizedBox(height: 18),
                    _UsageSection(data: data, wide: width >= 900),
                    const SizedBox(height: 18),
                    _LowerDashboard(data: data, wide: width >= 1050),
                    const SizedBox(height: 18),
                    _AlertsSection(data: data),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _PageHeader extends StatelessWidget {
  final PlatformDashboardData data;
  final VoidCallback onExport;

  const _PageHeader({required this.data, required this.onExport});

  @override
  Widget build(BuildContext context) {
    final adminName = data.adminName.trim().isEmpty
        ? 'Platform Admin'
        : data.adminName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  color: _PlatformDashboardScreenState._navy,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Overview of your Loss Defender platform',
                style: TextStyle(
                  color: _PlatformDashboardScreenState._muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    size: 14,
                    color: _PlatformDashboardScreenState._green,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    adminName,
                    style: const TextStyle(
                      color: _PlatformDashboardScreenState._muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (data.adminEmail.trim().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    const Text(
                      '•',
                      style: TextStyle(
                        color: _PlatformDashboardScreenState._border,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        data.adminEmail,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _PlatformDashboardScreenState._muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        if (MediaQuery.sizeOf(context).width >= 650)
          Row(
            children: [
              _OutlineAction(
                label: 'Last 30 Days',
                icon: Icons.calendar_today_outlined,
                onTap: () {},
              ),
              const SizedBox(width: 10),
              _PrimaryAction(
                label: 'Export Report',
                icon: Icons.download_outlined,
                onTap: onExport,
              ),
            ],
          ),
      ],
    );
  }
}

class _DashboardTabs extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _DashboardTabs({required this.selected, required this.onSelected});

  static const items = [
    ('Overview', Icons.dashboard_outlined),
    ('Revenue', Icons.payments_outlined),
    ('Companies', Icons.business_outlined),
    ('Subscriptions', Icons.workspace_premium_outlined),
    ('Usage', Icons.bar_chart_rounded),
    ('System Health', Icons.monitor_heart_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _PlatformDashboardScreenState._border),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in items)
              _DashboardTab(
                label: item.$1,
                icon: item.$2,
                selected: selected == item.$1,
                onTap: () => onSelected(item.$1),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DashboardTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(right: 28),
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? _PlatformDashboardScreenState._blue
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? _PlatformDashboardScreenState._blue
                  : _PlatformDashboardScreenState._muted,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? _PlatformDashboardScreenState._blue
                    : _PlatformDashboardScreenState._muted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiSection extends StatelessWidget {
  final PlatformDashboardData data;

  const _KpiSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1250
            ? 6
            : constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;

        final gap = 12.0;
        final cardWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;

        final cards = [
          _KpiCard(
            title: 'Total Companies',
            value: _number(data.totalCompanies),
            subtitle:
                '${_number(data.activeCompanies)} active  •  ${_number(data.inactiveCompanies)} inactive',
            icon: Icons.business_outlined,
            iconColor: _PlatformDashboardScreenState._blue,
            iconBackground: _PlatformDashboardScreenState._blueLight,
            positive: data.newCompaniesThisMonth > 0,
            trend: data.newCompaniesThisMonth > 0
                ? '+${_number(data.newCompaniesThisMonth)}'
                : 'Live',
          ),
          _KpiCard(
            title: 'Total Revenue',
            value: _money(data.revenueTotalPaise),
            subtitle: '${_number(data.revenuePaidPaymentCount)} paid payments',
            icon: Icons.currency_rupee_rounded,
            iconColor: _PlatformDashboardScreenState._green,
            iconBackground: _PlatformDashboardScreenState._greenLight,
            positive: data.revenueTotalPaise > 0,
            trend: 'Live',
          ),
          _KpiCard(
            title: 'Active Subscriptions',
            value: _number(data.activeSubscriptions),
            subtitle: '${_number(data.totalCompanies)} companies',
            icon: Icons.workspace_premium_outlined,
            iconColor: _PlatformDashboardScreenState._orange,
            iconBackground: _PlatformDashboardScreenState._orangeLight,
            positive: data.activeSubscriptions > 0,
            trend: 'Live',
          ),
          _KpiCard(
            title: 'Total Users',
            value: _number(data.totalUsers),
            subtitle:
                '${_number(data.activeUsers)} active  •  ${_number(data.inactiveUsers)} inactive',
            icon: Icons.people_outline_rounded,
            iconColor: _PlatformDashboardScreenState._blue,
            iconBackground: _PlatformDashboardScreenState._blueLight,
            positive: data.activeUsers > 0,
            trend: 'Live',
          ),
          _KpiCard(
            title: 'Storage Used',
            value: _bytes(data.storageUsedBytes),
            subtitle:
                '${_percent(data.storageUsedBytes, data.storageQuotaBytes)}% of quota',
            icon: Icons.storage_outlined,
            iconColor: _PlatformDashboardScreenState._violet,
            iconBackground: _PlatformDashboardScreenState._violetLight,
            positive: data.storageQuotaBytes == 0 || _storagePercent(data) < 80,
            trend:
                '${_percent(data.storageUsedBytes, data.storageQuotaBytes)}%',
          ),
          _KpiCard(
            title: 'Evidence Media',
            value: _number(
              data.evidenceStatus.fold<int>(0, (sum, item) => sum + item.count),
            ),
            subtitle:
                '${_number(data.recordingStatus.fold<int>(0, (sum, item) => sum + item.count))} recordings',
            icon: Icons.video_library_outlined,
            iconColor: _PlatformDashboardScreenState._cyan,
            iconBackground: _PlatformDashboardScreenState._cyanLight,
            positive: true,
            trend: 'Live',
          ),
        ];

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(
                width: columns == 1 ? constraints.maxWidth : cardWidth,
                child: card,
              ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final bool positive;
  final String trend;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.positive,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: positive
                      ? _PlatformDashboardScreenState._greenLight
                      : _PlatformDashboardScreenState._orangeLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    color: positive
                        ? _PlatformDashboardScreenState._green
                        : _PlatformDashboardScreenState._orange,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: const TextStyle(
              color: _PlatformDashboardScreenState._muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: _PlatformDashboardScreenState._navy,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PlatformDashboardScreenState._muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAnalytics extends StatelessWidget {
  final PlatformDashboardData data;
  final bool wide;

  const _PrimaryAnalytics({required this.data, required this.wide});

  @override
  Widget build(BuildContext context) {
    final revenue = _DashboardCard(
      title: 'Revenue Trend',
      icon: Icons.bar_chart_rounded,
      trailing: _CompactDropdown(label: 'Last 6 Months', onTap: () {}),
      child: SizedBox(
        height: 280,
        child: _RevenueChart(revenue: data.revenueMonthly),
      ),
    );

    final growth = _DashboardCard(
      title: 'Users & Subscriptions Growth',
      icon: Icons.trending_up_rounded,
      trailing: _CompactDropdown(label: 'Last 6 Months', onTap: () {}),
      child: SizedBox(
        height: 280,
        child: _GrowthChart(
          users: data.monthlyUsers,
          subscriptions: data.monthlySubscriptions,
        ),
      ),
    );

    if (!wide) {
      return Column(children: [revenue, const SizedBox(height: 14), growth]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: revenue),
        const SizedBox(width: 14),
        Expanded(flex: 2, child: growth),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  final Widget child;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 13),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _PlatformDashboardScreenState._blueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: _PlatformDashboardScreenState._blue,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: _PlatformDashboardScreenState._text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<PlatformRevenuePoint> revenue;

  const _RevenueChart({required this.revenue});

  @override
  Widget build(BuildContext context) {
    if (revenue.isEmpty) {
      return const _EmptyChart(message: 'No revenue history available');
    }

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _RevenuePainter(
              values: revenue
                  .map((item) => item.revenuePaise.toDouble())
                  .toList(),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _LegendDot(
              color: _PlatformDashboardScreenState._blue,
              label: 'Revenue',
            ),
            const SizedBox(width: 18),
            _LegendDot(
              color: _PlatformDashboardScreenState._orange,
              label: 'Live API data',
            ),
            const Spacer(),
            Text(
              revenue.isNotEmpty ? _money(revenue.last.revenuePaise) : '₹0',
              style: const TextStyle(
                color: _PlatformDashboardScreenState._navy,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GrowthChart extends StatelessWidget {
  final List<PlatformGrowthPoint> users;
  final List<PlatformGrowthPoint> subscriptions;

  const _GrowthChart({required this.users, required this.subscriptions});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty && subscriptions.isEmpty) {
      return const _EmptyChart(message: 'No growth history available');
    }

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _GrowthPainter(
              first: users.map((e) => e.value.toDouble()).toList(),
              second: subscriptions.map((e) => e.value.toDouble()).toList(),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _LegendDot(
              color: _PlatformDashboardScreenState._blue,
              label: 'Users',
            ),
            const SizedBox(width: 18),
            _LegendDot(
              color: _PlatformDashboardScreenState._violet,
              label: 'Subscriptions',
            ),
          ],
        ),
      ],
    );
  }
}

class _RevenuePainter extends CustomPainter {
  final List<double> values;

  _RevenuePainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const left = 54.0;
    const right = 12.0;
    const top = 12.0;
    const bottom = 28.0;

    final chart = Rect.fromLTWH(
      left,
      top,
      math.max(0, size.width - left - right),
      math.max(0, size.height - top - bottom),
    );

    final maxValue = values.fold<double>(
      0,
      (max, value) => math.max(max, value),
    );

    final grid = Paint()
      ..color = _PlatformDashboardScreenState._border
      ..strokeWidth = 1;

    for (var i = 0; i < 5; i++) {
      final y = chart.top + chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);

      final value = maxValue * (4 - i) / 4;

      _drawText(
        canvas,
        _compactMoney(value.round()),
        Offset(0, y - 6),
        const TextStyle(
          color: _PlatformDashboardScreenState._muted,
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    if (maxValue <= 0) return;

    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? chart.center.dx
          : chart.left + chart.width * i / (values.length - 1);

      final normalized = values[i] / maxValue;
      final y = chart.bottom - normalized * chart.height;

      points.add(Offset(x, y));
    }

    final fill = Path()
      ..moveTo(points.first.dx, chart.bottom)
      ..lineTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      fill.lineTo(points[i].dx, points[i].dy);
    }

    fill
      ..lineTo(points.last.dx, chart.bottom)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..color = _PlatformDashboardScreenState._blue.withValues(alpha: .07),
    );

    final line = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      line.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = _PlatformDashboardScreenState._blue
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(
        points[i],
        3.5,
        Paint()..color = _PlatformDashboardScreenState._blue,
      );

      canvas.drawCircle(points[i], 1.5, Paint()..color = Colors.white);
    }

    final months = values.length <= 6 ? values.length : 6;

    for (var i = 0; i < months; i++) {
      final index = values.length <= 6
          ? i
          : ((values.length - 1) * i / (months - 1)).round();

      final x = values.length == 1
          ? chart.center.dx
          : chart.left + chart.width * index / (values.length - 1);

      _drawText(
        canvas,
        '${index + 1}',
        Offset(x - 3, chart.bottom + 8),
        const TextStyle(
          color: _PlatformDashboardScreenState._muted,
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RevenuePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _GrowthPainter extends CustomPainter {
  final List<double> first;
  final List<double> second;

  _GrowthPainter({required this.first, required this.second});

  @override
  void paint(Canvas canvas, Size size) {
    const left = 36.0;
    const right = 10.0;
    const top = 12.0;
    const bottom = 28.0;

    final chart = Rect.fromLTWH(
      left,
      top,
      math.max(0, size.width - left - right),
      math.max(0, size.height - top - bottom),
    );

    final all = [...first, ...second];

    if (all.isEmpty) return;

    final maxValue = all.fold<double>(0, (max, value) => math.max(max, value));

    final grid = Paint()
      ..color = _PlatformDashboardScreenState._border
      ..strokeWidth = 1;

    for (var i = 0; i < 5; i++) {
      final y = chart.top + chart.height * i / 4;

      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);

      final value = maxValue * (4 - i) / 4;

      _drawText(
        canvas,
        _compactCount(value.round()),
        Offset(0, y - 6),
        const TextStyle(
          color: _PlatformDashboardScreenState._muted,
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    _drawSeries(
      canvas,
      chart,
      first,
      _PlatformDashboardScreenState._blue,
      maxValue,
    );

    _drawSeries(
      canvas,
      chart,
      second,
      _PlatformDashboardScreenState._violet,
      maxValue,
    );
  }

  void _drawSeries(
    Canvas canvas,
    Rect chart,
    List<double> values,
    Color color,
    double maxValue,
  ) {
    if (values.isEmpty || maxValue <= 0) return;

    final points = <Offset>[];

    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? chart.center.dx
          : chart.left + chart.width * i / (values.length - 1);

      final normalized = values[i] / maxValue;
      final y = chart.bottom - normalized * chart.height;

      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (final point in points) {
      canvas.drawCircle(point, 3, Paint()..color = color);

      canvas.drawCircle(point, 1.25, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _GrowthPainter oldDelegate) {
    return oldDelegate.first != first || oldDelegate.second != second;
  }
}

class _UsageSection extends StatelessWidget {
  final PlatformDashboardData data;
  final bool wide;

  const _UsageSection({required this.data, required this.wide});

  @override
  Widget build(BuildContext context) {
    final storagePercent = _ratio(
      data.storageUsedBytes,
      data.storageQuotaBytes,
    );

    final walletPercent = _ratio(data.walletConsumed, data.walletAllocated);

    final userPercent = _ratio(data.activeUsers, data.totalUsers);

    final cards = [
      _UsageCard(
        title: 'Storage Usage',
        value: _bytes(data.storageUsedBytes),
        total: _bytes(data.storageQuotaBytes),
        percent: storagePercent,
        icon: Icons.storage_outlined,
        color: _PlatformDashboardScreenState._blue,
      ),
      _UsageCard(
        title: 'Scan Credits',
        value: _number(data.walletConsumed),
        total: _number(data.walletAllocated),
        percent: walletPercent,
        icon: Icons.qr_code_scanner_rounded,
        color: _PlatformDashboardScreenState._violet,
      ),
      _UsageCard(
        title: 'Active Users',
        value: _number(data.activeUsers),
        total: _number(data.totalUsers),
        percent: userPercent,
        icon: Icons.people_outline_rounded,
        color: _PlatformDashboardScreenState._green,
      ),
      _UsageCard(
        title: 'Evidence',
        value: _number(
          data.evidenceStatus.fold<int>(0, (sum, item) => sum + item.count),
        ),
        total: _number(
          data.recordingStatus.fold<int>(0, (sum, item) => sum + item.count),
        ),
        percent: _ratio(
          data.evidenceStatus.fold<int>(0, (sum, item) => sum + item.count),
          data.recordingStatus.fold<int>(0, (sum, item) => sum + item.count),
        ),
        icon: Icons.video_library_outlined,
        color: _PlatformDashboardScreenState._orange,
      ),
    ];

    if (!wide) {
      return _DashboardCard(
        title: 'Platform Usage Overview',
        icon: Icons.analytics_outlined,
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, index) => cards[index],
        ),
      );
    }

    return _DashboardCard(
      title: 'Platform Usage Overview',
      icon: Icons.analytics_outlined,
      child: Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i != cards.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final String title;
  final String value;
  final String total;
  final double percent;
  final IconData icon;
  final Color color;

  const _UsageCard({
    required this.title,
    required this.value,
    required this.total,
    required this.percent,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFCFF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _PlatformDashboardScreenState._border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _PlatformDashboardScreenState._text,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _percentFromRatio(percent),
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: _PlatformDashboardScreenState._navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '/ $total',
                style: const TextStyle(
                  color: _PlatformDashboardScreenState._muted,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: percent.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: .10),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowerDashboard extends StatelessWidget {
  final PlatformDashboardData data;
  final bool wide;

  const _LowerDashboard({required this.data, required this.wide});

  @override
  Widget build(BuildContext context) {
    final revenue = _RevenueCollectionCard(data: data);
    final activity = _RecentActivityCard(data: data);
    final subscriptions = _SubscriptionCard(data: data);

    if (!wide) {
      return Column(
        children: [
          revenue,
          const SizedBox(height: 14),
          subscriptions,
          const SizedBox(height: 14),
          activity,
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: revenue),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: subscriptions),
          ],
        ),
        const SizedBox(height: 14),
        activity,
      ],
    );
  }
}

class _RevenueCollectionCard extends StatelessWidget {
  final PlatformDashboardData data;

  const _RevenueCollectionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      title: 'Revenue Collection',
      icon: Icons.payments_outlined,
      trailing: TextButton(
        onPressed: () {},
        child: const Text(
          'View Details',
          style: TextStyle(
            color: _PlatformDashboardScreenState._blue,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RevenueMetric(
              label: 'Total Revenue',
              value: _money(data.revenueTotalPaise),
              icon: Icons.currency_rupee_rounded,
              color: _PlatformDashboardScreenState._green,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _RevenueMetric(
              label: 'Subtotal',
              value: _money(data.revenueSubtotalPaise),
              icon: Icons.receipt_long_outlined,
              color: _PlatformDashboardScreenState._blue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _RevenueMetric(
              label: 'GST',
              value: _money(data.revenueGstPaise),
              icon: Icons.account_balance_outlined,
              color: _PlatformDashboardScreenState._orange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _RevenueMetric(
              label: 'Paid Payments',
              value: _number(data.revenuePaidPaymentCount),
              icon: Icons.check_circle_outline_rounded,
              color: _PlatformDashboardScreenState._violet,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _RevenueMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .045),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 9),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _PlatformDashboardScreenState._muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: _PlatformDashboardScreenState._navy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final PlatformDashboardData data;

  const _SubscriptionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final activeRatio = _ratio(data.activeSubscriptions, data.totalCompanies);

    final inactive = math.max(
      0,
      data.totalCompanies - data.activeSubscriptions,
    );

    return _DashboardCard(
      title: 'Subscription Status',
      icon: Icons.workspace_premium_outlined,
      trailing: TextButton(
        onPressed: () {},
        child: const Text(
          'View All',
          style: TextStyle(
            color: _PlatformDashboardScreenState._blue,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 125,
                  child: Center(
                    child: _Donut(
                      progress: activeRatio,
                      color: _PlatformDashboardScreenState._green,
                      center: _number(data.activeSubscriptions),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatusRow(
                        color: _PlatformDashboardScreenState._green,
                        label: 'Active',
                        value: _number(data.activeSubscriptions),
                      ),
                      const SizedBox(height: 10),
                      _StatusRow(
                        color: _PlatformDashboardScreenState._orange,
                        label: 'Inactive / Other',
                        value: _number(inactive),
                      ),
                      const SizedBox(height: 10),
                      _StatusRow(
                        color: _PlatformDashboardScreenState._blue,
                        label: 'New Companies',
                        value: _number(data.newCompaniesThisMonth),
                      ),
                    ],
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

class _RecentActivityCard extends StatelessWidget {
  final PlatformDashboardData data;

  const _RecentActivityCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    for (final item in data.recentPayments.take(3)) {
      rows.add(
        _ActivityRow(
          icon: Icons.payments_outlined,
          iconColor: _PlatformDashboardScreenState._green,
          title: 'Payment received',
          subtitle: item.companyName,
          meta: item.status,
        ),
      );
    }

    for (final item in data.recentTopups.take(3)) {
      rows.add(
        _ActivityRow(
          icon: Icons.add_card_outlined,
          iconColor: _PlatformDashboardScreenState._orange,
          title: '${item.type} • ${_number(item.credits)} credits',
          subtitle: item.companyName,
          meta: _shortDate(item.createdAt),
        ),
      );
    }

    for (final item in data.recentUsers.take(3)) {
      rows.add(
        _ActivityRow(
          icon: Icons.person_add_alt_1_outlined,
          iconColor: _PlatformDashboardScreenState._blue,
          title: 'New user added',
          subtitle: '${item.name} • ${item.companyName}',
          meta: _shortDate(item.createdAt),
        ),
      );
    }

    if (rows.isEmpty) {
      rows.add(
        const Expanded(
          child: _EmptyChart(message: 'No recent activity available'),
        ),
      );
    }

    return _DashboardCard(
      title: 'Recent Activity',
      icon: Icons.history_rounded,
      trailing: TextButton(
        onPressed: () {},
        child: const Text(
          'View All',
          style: TextStyle(
            color: _PlatformDashboardScreenState._blue,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows.length > 7 ? 7 : rows.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          color: _PlatformDashboardScreenState._border,
        ),
        itemBuilder: (_, index) => rows[index],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String meta;

  const _ActivityRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _PlatformDashboardScreenState._text,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
          const SizedBox(width: 8),
          Text(
            meta,
            style: const TextStyle(
              color: _PlatformDashboardScreenState._muted,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsSection extends StatelessWidget {
  final PlatformDashboardData data;

  const _AlertsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final alerts = <_AlertItem>[];

    final storagePercent = _storagePercent(data);

    if (storagePercent >= 80) {
      alerts.add(
        _AlertItem(
          icon: Icons.storage_outlined,
          title: 'Storage usage is high',
          subtitle:
              '${_percent(data.storageUsedBytes, data.storageQuotaBytes)}% of total quota is used.',
          color: _PlatformDashboardScreenState._orange,
          background: _PlatformDashboardScreenState._orangeLight,
        ),
      );
    }

    if (data.inactiveCompanies > 0) {
      alerts.add(
        _AlertItem(
          icon: Icons.business_outlined,
          title: 'Inactive companies',
          subtitle:
              '${_number(data.inactiveCompanies)} companies are currently inactive.',
          color: _PlatformDashboardScreenState._orange,
          background: _PlatformDashboardScreenState._orangeLight,
        ),
      );
    }

    if (data.inactiveUsers > 0) {
      alerts.add(
        _AlertItem(
          icon: Icons.person_off_outlined,
          title: 'Inactive users',
          subtitle:
              '${_number(data.inactiveUsers)} users are currently inactive.',
          color: _PlatformDashboardScreenState._blue,
          background: _PlatformDashboardScreenState._blueLight,
        ),
      );
    }

    if (data.revenuePaidPaymentCount == 0) {
      alerts.add(
        const _AlertItem(
          icon: Icons.info_outline_rounded,
          title: 'No paid payments returned',
          subtitle:
              'The current dashboard response contains no paid payment records.',
          color: _PlatformDashboardScreenState._cyan,
          background: _PlatformDashboardScreenState._cyanLight,
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        const _AlertItem(
          icon: Icons.check_circle_outline_rounded,
          title: 'No critical alerts',
          subtitle:
              'Current platform metrics are within the configured dashboard thresholds.',
          color: _PlatformDashboardScreenState._green,
          background: _PlatformDashboardScreenState._greenLight,
        ),
      );
    }

    return _SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _PlatformDashboardScreenState._orangeLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: _PlatformDashboardScreenState._orange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'Important Alerts',
                style: TextStyle(
                  color: _PlatformDashboardScreenState._text,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: _PlatformDashboardScreenState._blue,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          for (final alert in alerts) _AlertRow(item: alert),
        ],
      ),
    );
  }
}

class _AlertItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;

  const _AlertItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
  });
}

class _AlertRow extends StatelessWidget {
  final _AlertItem item;

  const _AlertRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: item.background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: item.color, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: item.color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(
                    color: _PlatformDashboardScreenState._muted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: _PlatformDashboardScreenState._muted,
            size: 17,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _StatusRow({
    required this.color,
    required this.label,
    required this.value,
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
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _PlatformDashboardScreenState._navy,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Donut extends StatelessWidget {
  final double progress;
  final Color color;
  final String center;

  const _Donut({
    required this.progress,
    required this.color,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: CustomPaint(
        painter: _DonutPainter(progress: progress, color: color),
        child: Center(
          child: Text(
            center,
            style: const TextStyle(
              color: _PlatformDashboardScreenState._navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final Color color;

  _DonutPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2 - 8;

    final background = Paint()
      ..color = const Color(0xFFE8EEF7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final foreground = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, background);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0.0, 1.0),
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _PlatformDashboardScreenState._muted,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CompactDropdown extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _CompactDropdown({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFCFF),
          border: Border.all(color: _PlatformDashboardScreenState._border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _PlatformDashboardScreenState._text,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: _PlatformDashboardScreenState._muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _OutlineAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _PlatformDashboardScreenState._text,
        side: const BorderSide(color: _PlatformDashboardScreenState._border),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: _PlatformDashboardScreenState._blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        textStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _PlatformDashboardScreenState._surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _PlatformDashboardScreenState._border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({this.message = 'No data available'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.analytics_outlined,
            color: Color(0xFFCBD5E1),
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _PlatformDashboardScreenState._muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _PlatformDashboardScreenState._background,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: _PlatformDashboardScreenState._blue,
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _SurfaceCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: Color(0xFF94A3B8),
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load Platform Dashboard',
              style: TextStyle(
                color: _PlatformDashboardScreenState._navy,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            SizedBox(
              width: 420,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _PlatformDashboardScreenState._muted,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  painter.paint(canvas, offset);
}

String _number(int value) {
  return _formatIndian(value);
}

String _money(int paise) {
  final rupees = paise / 100;
  return '₹${_formatIndianDouble(rupees)}';
}

String _bytes(int bytes) {
  if (bytes <= 0) return '0 B';

  const kb = 1024.0;
  const mb = kb * 1024;
  const gb = mb * 1024;
  const tb = gb * 1024;

  if (bytes >= tb) {
    return '${(bytes / tb).toStringAsFixed(2)} TB';
  }

  if (bytes >= gb) {
    return '${(bytes / gb).toStringAsFixed(2)} GB';
  }

  if (bytes >= mb) {
    return '${(bytes / mb).toStringAsFixed(2)} MB';
  }

  if (bytes >= kb) {
    return '${(bytes / kb).toStringAsFixed(2)} KB';
  }

  return '$bytes B';
}

double _ratio(int used, int total) {
  if (total <= 0) return 0;
  return (used / total).clamp(0.0, 1.0);
}

double _storagePercent(PlatformDashboardData data) {
  if (data.storageQuotaBytes <= 0) return 0;
  return data.storageUsedBytes / data.storageQuotaBytes * 100;
}

String _percent(int used, int total) {
  if (total <= 0) return '0.00';
  return (used / total * 100).toStringAsFixed(2);
}

String _percentFromRatio(double value) {
  return '${(value * 100).clamp(0, 100).toStringAsFixed(2)}%';
}

String _compactMoney(int paise) {
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

  return '$value';
}

String _formatIndian(int value) {
  final negative = value < 0;
  final raw = value.abs().toString();

  if (raw.length <= 3) {
    return negative ? '-$raw' : raw;
  }

  final lastThree = raw.substring(raw.length - 3);
  var prefix = raw.substring(0, raw.length - 3);

  final parts = <String>[];

  while (prefix.length > 2) {
    parts.insert(0, prefix.substring(prefix.length - 2));
    prefix = prefix.substring(0, prefix.length - 2);
  }

  if (prefix.isNotEmpty) {
    parts.insert(0, prefix);
  }

  final result = '${parts.join(',')},$lastThree';

  return negative ? '-$result' : result;
}

String _formatIndianDouble(double value) {
  if (value == value.roundToDouble()) {
    return _formatIndian(value.toInt());
  }

  final fixed = value.toStringAsFixed(2);
  final split = fixed.split('.');
  final integer = int.tryParse(split.first) ?? 0;

  return '${_formatIndian(integer)}.${split.last}';
}

String _shortDate(dynamic value) {
  final raw = value?.toString() ?? '';

  if (raw.isEmpty) {
    return '—';
  }

  if (raw.contains('T')) {
    final date = raw.split('T').first;
    if (date.length >= 10) {
      return date.substring(5);
    }
  }

  return raw.length > 16 ? raw.substring(0, 16) : raw;
}
