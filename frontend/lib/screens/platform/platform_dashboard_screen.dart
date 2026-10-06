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
  final PlatformDashboardService _service = const PlatformDashboardService();

  PlatformDashboardData? _data;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.fetch();

      if (!mounted) return;

      setState(() {
        _data = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _DashboardLoading();
    }

    if (_error != null) {
      return _DashboardError(message: _error!, onRetry: _load);
    }

    final data = _data ?? PlatformDashboardData.empty();

    return Container(
      color: _DashboardColors.background,
      child: RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DashboardHeader(onExport: () {}),

                    const SizedBox(height: 14),

                    _DashboardTabs(),

                    const SizedBox(height: 18),

                    _KpiGrid(data: data),

                    const SizedBox(height: 14),

                    _ChartsRow(data: data),

                    const SizedBox(height: 14),

                    _UsageAndActivityRow(data: data),

                    const SizedBox(height: 14),

                    _CompaniesAndSubscriptionsRow(
                      data: data,
                      onOpenSection: widget.onOpenSection,
                    ),

                    const SizedBox(height: 14),

                    _HealthAndAlertsRow(
                      data: data,
                      onOpenSection: widget.onOpenSection,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* COLORS                                                                     */
/* -------------------------------------------------------------------------- */

abstract final class _DashboardColors {
  static const background = Color(0xFFF7F9FC);
  static const navy = Color(0xFF0A1B55);
  static const blue = Color(0xFF1769FF);
  static const blueSoft = Color(0xFFEAF2FF);

  static const green = Color(0xFF0DBB78);
  static const greenSoft = Color(0xFFE8FBF3);

  static const orange = Color(0xFFFF9819);
  static const orangeSoft = Color(0xFFFFF3E3);

  static const purple = Color(0xFF8A35F5);
  static const red = Color(0xFFF23D4F);

  static const text = Color(0xFF10235E);
  static const muted = Color(0xFF6F7D9E);

  static const border = Color(0xFFE1E7F0);
  static const grid = Color(0xFFE8EDF5);
}

/* -------------------------------------------------------------------------- */
/* HEADER                                                                     */
/* -------------------------------------------------------------------------- */

class _DashboardHeader extends StatelessWidget {
  final VoidCallback onExport;

  const _DashboardHeader({required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  color: _DashboardColors.navy,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Overview of your Loss Defender platform',
                style: TextStyle(
                  color: _DashboardColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _OutlinedButton(
          icon: Icons.calendar_month_outlined,
          label: 'Last 30 Days',
          onPressed: () {},
        ),
        const SizedBox(width: 10),
        _PrimaryButton(
          icon: Icons.download_outlined,
          label: 'Export Report',
          onPressed: onExport,
        ),
      ],
    );
  }
}

class _DashboardTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const tabs = [
      'Overview',
      'Revenue',
      'Companies',
      'Subscriptions',
      'Usage',
      'System Health',
    ];

    return Container(
      height: 42,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _DashboardColors.border)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 28),
              child: _TabItem(label: tabs[i], selected: i == 0),
            ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool selected;

  const _TabItem({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        border: selected
            ? const Border(
                bottom: BorderSide(color: _DashboardColors.blue, width: 3),
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? _DashboardColors.blue : _DashboardColors.text,
          fontSize: 12,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* KPI GRID                                                                   */
/* -------------------------------------------------------------------------- */

class _KpiGrid extends StatelessWidget {
  final PlatformDashboardData data;

  const _KpiGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final m = data.metrics;

    final cards = [
      _KpiItem(
        title: 'Total Companies',
        value: _formatInt(m.totalCompanies),
        subtitle:
            '${data.activeCompanies} active • ${data.inactiveCompanies} inactive',
        icon: Icons.business_rounded,
        color: _DashboardColors.blue,
        background: _DashboardColors.blueSoft,
      ),
      _KpiItem(
        title: 'Total Revenue',
        value: _formatMoney(m.totalRevenuePaise),
        subtitle: '${data.revenuePaidPaymentCount} paid payments',
        icon: Icons.currency_rupee_rounded,
        color: _DashboardColors.green,
        background: _DashboardColors.greenSoft,
      ),
      _KpiItem(
        title: 'Active Subscriptions',
        value: _formatInt(m.activeSubscriptions),
        subtitle: '${m.totalCompanies} companies',
        icon: Icons.workspace_premium_rounded,
        color: _DashboardColors.orange,
        background: _DashboardColors.orangeSoft,
      ),
      _KpiItem(
        title: 'Total Users',
        value: _formatInt(m.totalUsers),
        subtitle: '${data.activeUsers} active • ${data.inactiveUsers} inactive',
        icon: Icons.people_alt_rounded,
        color: _DashboardColors.blue,
        background: _DashboardColors.blueSoft,
      ),
      _KpiItem(
        title: 'Total Warehouses',
        value: _formatInt(m.totalWarehouses),
        subtitle: 'Across all companies',
        icon: Icons.warehouse_rounded,
        color: _DashboardColors.blue,
        background: _DashboardColors.blueSoft,
      ),
      _KpiItem(
        title: 'Total Storage Used',
        value: _formatBytes(m.totalStorageUsedBytes),
        subtitle: _storageSubtitle(m),
        icon: Icons.storage_rounded,
        color: _DashboardColors.blue,
        background: _DashboardColors.blueSoft,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1250
            ? 6
            : constraints.maxWidth >= 850
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 92,
          ),
          itemBuilder: (_, index) {
            return _KpiCard(item: cards[index]);
          },
        );
      },
    );
  }

  String _storageSubtitle(PlatformDashboardMetrics m) {
    if (m.totalStorageQuotaBytes <= 0) {
      return 'Quota not configured';
    }

    final percentage = m.totalStorageUsedBytes / m.totalStorageQuotaBytes * 100;

    return '${_formatBytes(m.totalStorageQuotaBytes)} quota '
        '(${percentage.toStringAsFixed(1)}%)';
  }
}

class _KpiItem {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;

  const _KpiItem({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiItem item;

  const _KpiCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _DashboardColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B2450),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: BoxDecoration(
              color: item.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DashboardColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DashboardColors.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DashboardColors.muted,
                    fontSize: 9,
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

/* -------------------------------------------------------------------------- */
/* CHARTS                                                                     */
/* -------------------------------------------------------------------------- */

class _ChartsRow extends StatelessWidget {
  final PlatformDashboardData data;

  const _ChartsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1050;

        if (!wide) {
          return Column(
            children: [
              _RevenueCard(data: data),
              const SizedBox(height: 10),
              _GrowthCard(data: data),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _RevenueCard(data: data)),
            const SizedBox(width: 10),
            Expanded(flex: 3, child: _GrowthCard(data: data)),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: _SubscriptionDistribution(data: data)),
          ],
        );
      },
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final PlatformDashboardData data;

  const _RevenueCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final points = data.revenueMonthly;

    return _Panel(
      title: 'Revenue Trend',
      icon: Icons.bar_chart_rounded,
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: _SmallSelector(label: 'Last 6 Months'),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 155,
            child: points.isEmpty
                ? const _EmptyChart(message: 'No revenue data available')
                : _RevenueChart(points: points),
          ),
          const SizedBox(height: 6),
          if (points.isNotEmpty)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: _DashboardColors.blue, label: 'Revenue'),
                SizedBox(width: 18),
                _LegendDot(color: _DashboardColors.orange, label: 'Payments'),
              ],
            ),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<PlatformRevenuePoint> points;

  const _RevenueChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxValue = points
        .map((e) => e.revenuePaise)
        .fold<int>(0, (a, b) => math.max(a, b));

    return CustomPaint(
      painter: _LineChartPainter(
        values: points.map((e) => e.revenuePaise.toDouble()).toList(),
        maxValue: maxValue.toDouble(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    point.month,
                    style: const TextStyle(
                      color: _DashboardColors.muted,
                      fontSize: 8,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GrowthCard extends StatelessWidget {
  final PlatformDashboardData data;

  const _GrowthCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final users = data.monthlyUsers;
    final subscriptions = data.monthlySubscriptions;

    final maxValue = [
      ...users.map((e) => e.value),
      ...subscriptions.map((e) => e.value),
    ].fold<int>(0, math.max);

    return _Panel(
      title: 'Companies Growth',
      icon: Icons.bar_chart_rounded,
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: _SmallSelector(label: 'Last 6 Months'),
          ),
          const SizedBox(height: 3),
          SizedBox(
            height: 155,
            child: users.isEmpty && subscriptions.isEmpty
                ? const _EmptyChart(message: 'No growth data available')
                : _GrowthChart(
                    users: users,
                    subscriptions: subscriptions,
                    maxValue: maxValue,
                  ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: _DashboardColors.blue, label: 'Users'),
              SizedBox(width: 18),
              _LegendDot(
                color: _DashboardColors.purple,
                label: 'Subscriptions',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrowthChart extends StatelessWidget {
  final List<PlatformGrowthPoint> users;
  final List<PlatformGrowthPoint> subscriptions;
  final int maxValue;

  const _GrowthChart({
    required this.users,
    required this.subscriptions,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final count = math.max(users.length, subscriptions.length);

    return CustomPaint(
      painter: _MultiLineChartPainter(
        first: users.map((e) => e.value.toDouble()).toList(),
        second: subscriptions.map((e) => e.value.toDouble()).toList(),
        maxValue: maxValue.toDouble(),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < count; i++)
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  i < users.length
                      ? users[i].month
                      : i < subscriptions.length
                      ? subscriptions[i].month
                      : '',
                  style: const TextStyle(
                    color: _DashboardColors.muted,
                    fontSize: 8,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubscriptionDistribution extends StatelessWidget {
  final PlatformDashboardData data;

  const _SubscriptionDistribution({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = data.subscriptionStatus;

    return _Panel(
      title: 'Subscription Status',
      icon: Icons.donut_large_rounded,
      child: SizedBox(
        height: 210,
        child: items.isEmpty
            ? const _EmptyChart(message: 'No subscription data available')
            : Row(
                children: [
                  SizedBox(
                    width: 125,
                    height: 125,
                    child: CustomPaint(
                      painter: _DonutPainter(
                        values: items.map((e) => e.count.toDouble()).toList(),
                      ),
                      child: Center(
                        child: Text(
                          '${data.metrics.totalCompanies}',
                          style: const TextStyle(
                            color: _DashboardColors.navy,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: math.min(items.length, 5),
                      separatorBuilder: (_, _) => const SizedBox(height: 7),
                      itemBuilder: (_, index) {
                        final item = items[index];

                        return Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _statusColor(index),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                _prettyStatus(item.status),
                                style: const TextStyle(
                                  color: _DashboardColors.text,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            Text(
                              '${item.count}',
                              style: const TextStyle(
                                color: _DashboardColors.navy,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* USAGE + ACTIVITY                                                           */
/* -------------------------------------------------------------------------- */

class _UsageAndActivityRow extends StatelessWidget {
  final PlatformDashboardData data;

  const _UsageAndActivityRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1050;

        final usage = _UsageCard(data: data);
        final activity = _ActivityCard(data: data);

        if (!wide) {
          return Column(
            children: [usage, const SizedBox(height: 10), activity],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: usage),
            const SizedBox(width: 10),
            Expanded(flex: 3, child: activity),
          ],
        );
      },
    );
  }
}

class _UsageCard extends StatelessWidget {
  final PlatformDashboardData data;

  const _UsageCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final storagePercentage = data.storageQuotaBytes <= 0
        ? 0.0
        : (data.storageUsedBytes / data.storageQuotaBytes).clamp(0.0, 1.0);

    return _Panel(
      title: 'Platform Usage Overview',
      icon: Icons.dashboard_customize_outlined,
      child: Row(
        children: [
          Expanded(
            child: _UsageMetric(
              icon: Icons.storage_rounded,
              title: 'Storage Usage',
              value:
                  '${_formatBytes(data.storageUsedBytes)}'
                  ' / '
                  '${_formatBytes(data.storageQuotaBytes)}',
              progress: storagePercentage,
            ),
          ),
          Expanded(
            child: _UsageMetric(
              icon: Icons.inventory_2_outlined,
              title: 'Total Orders',
              value: _formatInt(data.metrics.totalOrders),
              progress: null,
            ),
          ),
          Expanded(
            child: _UsageMetric(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Scan Credits',
              value: _formatInt(data.walletConsumed),
              progress: null,
            ),
          ),
          Expanded(
            child: _UsageMetric(
              icon: Icons.people_alt_outlined,
              title: 'Active Users',
              value: '${data.activeUsers} / ${data.totalUsers}',
              progress: data.totalUsers <= 0
                  ? 0
                  : data.activeUsers / data.totalUsers,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageMetric extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final double? progress;

  const _UsageMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _DashboardColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: _DashboardColors.blue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DashboardColors.muted,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _DashboardColors.navy,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFE8EEF8),
                valueColor: const AlwaysStoppedAnimation(_DashboardColors.blue),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final PlatformDashboardData data;

  const _ActivityCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final activities = <_Activity>[
      ...data.recentUsers
          .take(4)
          .map(
            (user) => _Activity(
              icon: Icons.person_add_alt_1_rounded,
              color: _DashboardColors.purple,
              title: 'User added',
              subtitle: user.name,
              time: _relativeTime(user.createdAt),
            ),
          ),
      ...data.recentPayments
          .take(4)
          .map(
            (payment) => _Activity(
              icon: Icons.payments_rounded,
              color: _DashboardColors.green,
              title: 'Payment',
              subtitle:
                  '${payment.companyName} • '
                  '${_formatMoney(payment.totalPaise)}',
              time: _relativeTime(payment.createdAt),
            ),
          ),
      ...data.recentTopups
          .take(4)
          .map(
            (topup) => _Activity(
              icon: Icons.shopping_cart_rounded,
              color: _DashboardColors.orange,
              title: 'Credit transaction',
              subtitle:
                  '${topup.companyName} • '
                  '${_formatInt(topup.credits)} credits',
              time: _relativeTime(topup.createdAt),
            ),
          ),
    ];

    return _Panel(
      title: 'Recent Activity',
      icon: Icons.event_note_outlined,
      trailing: TextButton(onPressed: () {}, child: const Text('View All')),
      child: activities.isEmpty
          ? const SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: _DashboardColors.muted, fontSize: 11),
                ),
              ),
            )
          : Column(
              children: [
                for (final activity in activities.take(7))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ActivityTile(item: activity),
                  ),
              ],
            ),
    );
  }
}

class _Activity {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _Activity({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

class _ActivityTile extends StatelessWidget {
  final _Activity item;

  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            color: item.color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(item.icon, size: 15, color: item.color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  color: _DashboardColors.text,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _DashboardColors.muted,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
        Text(
          item.time,
          style: const TextStyle(color: _DashboardColors.muted, fontSize: 7),
        ),
      ],
    );
  }
}

/* -------------------------------------------------------------------------- */
/* COMPANIES + STATUS                                                         */
/* -------------------------------------------------------------------------- */

class _CompaniesAndSubscriptionsRow extends StatelessWidget {
  final PlatformDashboardData data;
  final ValueChanged<String>? onOpenSection;

  const _CompaniesAndSubscriptionsRow({
    required this.data,
    required this.onOpenSection,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1050;

        final companies = _TopCompaniesPanel(
          data: data,
          onOpen: () => onOpenSection?.call('Companies'),
        );

        final status = _SubscriptionStatusPanel(data: data);

        if (!wide) {
          return Column(
            children: [companies, const SizedBox(height: 10), status],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: companies),
            const SizedBox(width: 10),
            Expanded(flex: 3, child: status),
          ],
        );
      },
    );
  }
}

class _TopCompaniesPanel extends StatelessWidget {
  final PlatformDashboardData data;
  final VoidCallback onOpen;

  const _TopCompaniesPanel({required this.data, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Top Companies by Revenue',
      icon: Icons.business_center_outlined,
      trailing: TextButton(onPressed: onOpen, child: const Text('View All')),
      child: Column(
        children: [
          _tableHeader(),
          const Divider(height: 1, color: _DashboardColors.border),
          if (data.recentPayments.isEmpty)
            const SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'No payment data available',
                  style: TextStyle(color: _DashboardColors.muted, fontSize: 10),
                ),
              ),
            )
          else
            for (int i = 0; i < data.recentPayments.length && i < 5; i++)
              _paymentRow(i + 1, data.recentPayments[i]),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return const Row(
      children: [
        SizedBox(width: 25, child: Text('#', style: _tableHeaderStyle)),
        Expanded(flex: 3, child: Text('COMPANY', style: _tableHeaderStyle)),
        Expanded(child: Text('PLAN', style: _tableHeaderStyle)),
        Expanded(child: Text('REVENUE', style: _tableHeaderStyle)),
        SizedBox(width: 55, child: Text('STATUS', style: _tableHeaderStyle)),
      ],
    );
  }

  Widget _paymentRow(int index, PlatformRecentPayment payment) {
    final success = payment.status.toLowerCase() == 'success';

    return Container(
      height: 32,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F3F8))),
      ),
      child: Row(
        children: [
          SizedBox(width: 25, child: Text('$index', style: _tableCellStyle)),
          Expanded(
            flex: 3,
            child: Text(
              payment.companyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _DashboardColors.blue,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              payment.plan.isEmpty ? '—' : payment.plan,
              style: _tableCellStyle,
            ),
          ),
          Expanded(
            child: Text(
              _formatMoney(payment.totalPaise),
              style: _tableCellStyle,
            ),
          ),
          SizedBox(
            width: 55,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: success
                    ? _DashboardColors.greenSoft
                    : const Color(0xFFFFECEF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                success ? 'Active' : payment.status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: success
                      ? _DashboardColors.green
                      : _DashboardColors.red,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionStatusPanel extends StatelessWidget {
  final PlatformDashboardData data;

  const _SubscriptionStatusPanel({required this.data});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Subscription Status',
      icon: Icons.card_membership_outlined,
      child: SizedBox(
        height: 220,
        child: data.subscriptionStatus.isEmpty
            ? const Center(
                child: Text(
                  'No subscription data available',
                  style: TextStyle(color: _DashboardColors.muted, fontSize: 10),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 125,
                          height: 125,
                          child: CustomPaint(
                            painter: _DonutPainter(
                              values: data.subscriptionStatus
                                  .map((e) => e.count.toDouble())
                                  .toList(),
                            ),
                            child: Center(
                              child: Text(
                                '${data.activeSubscriptions}',
                                style: const TextStyle(
                                  color: _DashboardColors.navy,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (
                                int i = 0;
                                i < data.subscriptionStatus.length && i < 5;
                                i++
                              )
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: _statusColor(i),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(
                                          _prettyStatus(
                                            data.subscriptionStatus[i].status,
                                          ),
                                          style: const TextStyle(
                                            color: _DashboardColors.text,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${data.subscriptionStatus[i].count}',
                                        style: const TextStyle(
                                          color: _DashboardColors.navy,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* HEALTH + ALERTS                                                            */
/* -------------------------------------------------------------------------- */

class _HealthAndAlertsRow extends StatelessWidget {
  final PlatformDashboardData data;
  final ValueChanged<String>? onOpenSection;

  const _HealthAndAlertsRow({required this.data, required this.onOpenSection});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1050;

        final health = _SystemHealthPanel(
          data: data,
          onOpen: () => onOpenSection?.call('System Health'),
        );

        final alerts = const _AlertsPanel();

        if (!wide) {
          return Column(children: [health, const SizedBox(height: 10), alerts]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 7, child: health),
            const SizedBox(width: 10),
            const Expanded(flex: 3, child: _AlertsPanel()),
          ],
        );
      },
    );
  }
}

class _SystemHealthPanel extends StatelessWidget {
  final PlatformDashboardData data;
  final VoidCallback onOpen;

  const _SystemHealthPanel({required this.data, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    /*
     * IMPORTANT:
     *
     * Current dashboard API does not yet expose actual
     * service health checks.
     *
     * Therefore we intentionally do NOT show fake
     * "Operational" values.
     */

    return _Panel(
      title: 'System Health',
      icon: Icons.settings_suggest_outlined,
      trailing: TextButton(
        onPressed: onOpen,
        child: const Text('View Details'),
      ),
      child: Container(
        height: 105,
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: _DashboardColors.muted,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Live service health data is not available '
                'from the current dashboard API.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _DashboardColors.muted, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertsPanel extends StatelessWidget {
  const _AlertsPanel();

  @override
  Widget build(BuildContext context) {
    /*
     * No hard-coded alerts.
     *
     * Alerts will be rendered after the backend exposes
     * real platform alert records/rules.
     */

    return _Panel(
      title: 'Important Alerts',
      icon: Icons.notifications_active_outlined,
      child: const SizedBox(
        height: 105,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: _DashboardColors.green,
              ),
              SizedBox(width: 8),
              Text(
                'No alert data available',
                style: TextStyle(color: _DashboardColors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* COMMON PANEL                                                               */
/* -------------------------------------------------------------------------- */

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: _DashboardColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x070B2450),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _DashboardColors.blueSoft,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 15, color: _DashboardColors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _DashboardColors.navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* BUTTONS                                                                    */
/* -------------------------------------------------------------------------- */

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: _DashboardColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _OutlinedButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15, color: _DashboardColors.navy),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _DashboardColors.navy,
        side: const BorderSide(color: _DashboardColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SmallSelector extends StatelessWidget {
  final String label;

  const _SmallSelector({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 29,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        border: Border.all(color: _DashboardColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _DashboardColors.navy,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 14,
            color: _DashboardColors.muted,
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* CHART PAINTERS                                                             */
/* -------------------------------------------------------------------------- */

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;

  _LineChartPainter({required this.values, required this.maxValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final gridPaint = Paint()
      ..color = _DashboardColors.grid
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = _DashboardColors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = _DashboardColors.blue.withAlpha(18)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 4; i++) {
      final y = 12 + (size.height - 35) * i / 3;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fill = Path();

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);

      final normalized = maxValue <= 0 ? 0.0 : values[i] / maxValue;

      final y = 12 + (size.height - 42) * (1 - normalized);

      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height - 25);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }

    fill.lineTo(
      values.length == 1 ? size.width / 2 : size.width,
      size.height - 25,
    );
    fill.close();

    canvas.drawPath(fill, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = _DashboardColors.blue;

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);

      final normalized = maxValue <= 0 ? 0.0 : values[i] / maxValue;

      final y = 12 + (size.height - 42) * (1 - normalized);

      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.maxValue != maxValue;
  }
}

class _MultiLineChartPainter extends CustomPainter {
  final List<double> first;
  final List<double> second;
  final double maxValue;

  _MultiLineChartPainter({
    required this.first,
    required this.second,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _DashboardColors.grid
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = 12 + (size.height - 35) * i / 3;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawLine(canvas, first, _DashboardColors.blue, size);

    _drawLine(canvas, second, _DashboardColors.purple, size);
  }

  void _drawLine(Canvas canvas, List<double> values, Color color, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * i / (values.length - 1);

      final normalized = maxValue <= 0 ? 0.0 : values[i] / maxValue;

      final y = 12 + (size.height - 42) * (1 - normalized);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = color);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MultiLineChartPainter oldDelegate) {
    return true;
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;

  _DonutPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final total = values.fold<double>(0, (a, b) => a + b);

    if (total <= 0) return;

    final colors = [
      _DashboardColors.green,
      _DashboardColors.orange,
      _DashboardColors.red,
      const Color(0xFFB7C3D9),
      _DashboardColors.blue,
    ];

    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);

    double start = -math.pi / 2;

    for (int i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;

      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, start, sweep, false, paint);

      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

/* -------------------------------------------------------------------------- */
/* EMPTY / LOADING / ERROR                                                    */
/* -------------------------------------------------------------------------- */

class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: _DashboardColors.muted, fontSize: 10),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(30),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _DashboardColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: _DashboardColors.red,
              size: 38,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load platform dashboard',
              style: TextStyle(
                color: _DashboardColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _DashboardColors.muted,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/* SMALL WIDGETS                                                              */
/* -------------------------------------------------------------------------- */

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: _DashboardColors.muted, fontSize: 8),
        ),
      ],
    );
  }
}

const _tableHeaderStyle = TextStyle(
  color: _DashboardColors.muted,
  fontSize: 7,
  fontWeight: FontWeight.w700,
);

const _tableCellStyle = TextStyle(color: _DashboardColors.text, fontSize: 8);

/* -------------------------------------------------------------------------- */
/* HELPERS                                                                    */
/* -------------------------------------------------------------------------- */

String _formatInt(int value) {
  final text = value.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) {
      buffer.write(',');
    }

    buffer.write(text[i]);
  }

  return buffer.toString();
}

String _formatMoney(int paise) {
  final rupees = paise / 100;

  if (rupees >= 10000000) {
    return '₹${(rupees / 10000000).toStringAsFixed(2)} Cr';
  }

  if (rupees >= 100000) {
    return '₹${(rupees / 100000).toStringAsFixed(2)} L';
  }

  return '₹${_formatInt(rupees.round())}';
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';

  const units = ['B', 'KB', 'MB', 'GB', 'TB'];

  double value = bytes.toDouble();
  int index = 0;

  while (value >= 1024 && index < units.length - 1) {
    value /= 1024;
    index++;
  }

  if (index == 0) {
    return '${value.round()} ${units[index]}';
  }

  return '${value.toStringAsFixed(2)} ${units[index]}';
}

String _prettyStatus(String value) {
  final normalized = value.replaceAll('_', ' ').replaceAll('-', ' ').trim();

  if (normalized.isEmpty) return 'Unknown';

  return normalized
      .split(' ')
      .where((e) => e.isNotEmpty)
      .map((e) => '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}')
      .join(' ');
}

Color _statusColor(int index) {
  const colors = [
    _DashboardColors.green,
    _DashboardColors.orange,
    _DashboardColors.red,
    Color(0xFFB7C3D9),
    _DashboardColors.blue,
  ];

  return colors[index % colors.length];
}

String _relativeTime(String raw) {
  final parsed = DateTime.tryParse(raw);

  if (parsed == null) return '';

  final difference = DateTime.now().difference(parsed.toLocal());

  if (difference.inSeconds < 60) {
    return 'now';
  }

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours}h';
  }

  if (difference.inDays < 30) {
    return '${difference.inDays}d';
  }

  return '${difference.inDays ~/ 30}mo';
}
