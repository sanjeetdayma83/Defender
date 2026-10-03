import 'package:flutter/material.dart';

import '../../services/dashboard/platform_dashboard_service.dart';

/// Live PLATFORM_ADMIN home — metrics from GET /dashboard/platform.
/// Quick links cover P2–P10 navigation targets (parent shell switches tabs).
class PlatformDashboardScreen extends StatefulWidget {
  final ValueChanged<String>? onOpenSection;

  const PlatformDashboardScreen({super.key, this.onOpenSection});

  @override
  State<PlatformDashboardScreen> createState() => _PlatformDashboardScreenState();
}

class _PlatformDashboardScreenState extends State<PlatformDashboardScreen> {
  final _service = const PlatformDashboardService();
  Future<PlatformDashboardData>? _future;

  static const _navy = Color(0xFF0F172A);
  static const _blue = Color(0xFF2563EB);
  static const _cyan = Color(0xFF0891B2);
  static const _green = Color(0xFF059669);
  static const _amber = Color(0xFFD97706);
  static const _violet = Color(0xFF7C3AED);
  static const _rose = Color(0xFFE11D48);

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

  void _open(String label) {
    widget.onOpenSection?.call(label);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlatformDashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ErrorBody(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
            onRetry: _reload,
          );
        }

        final data = snapshot.data!;
        final m = data.metrics;

        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform Overview',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _navy,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Signed in as ${data.adminName} · ${data.adminEmail}',
                          style: TextStyle(color: const Color(0xFF475569), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _open('Analytics'),
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('Analytics'),
                    style: FilledButton.styleFrom(backgroundColor: _navy),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // P1 live metrics
              _SectionTitle('Live metrics'),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, c) {
                  final w = c.maxWidth;
                  final cols = w > 1100 ? 3 : (w > 700 ? 2 : 1);
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: cols == 1 ? 2.6 : 1.85,
                    children: [
                      _MetricCard(
                        title: 'Companies',
                        value: _fmt(m.companies),
                        subtitle: 'Registered tenants',
                        icon: Icons.business_outlined,
                        color: _blue,
                        onTap: () => _open('Companies'),
                      ),
                      _MetricCard(
                        title: 'Users',
                        value: _fmt(m.users),
                        subtitle: 'All roles across tenants',
                        icon: Icons.people_outline,
                        color: _cyan,
                        onTap: () => _open('Users'),
                      ),
                      _MetricCard(
                        title: 'Warehouses',
                        value: _fmt(m.warehouses),
                        subtitle: 'Active warehouse locations',
                        icon: Icons.warehouse_outlined,
                        color: _violet,
                        onTap: () => _open('Companies'),
                      ),
                      _MetricCard(
                        title: 'Orders',
                        value: _fmt(m.orders),
                        subtitle: 'All tenant orders',
                        icon: Icons.inventory_2_outlined,
                        color: _amber,
                      ),
                      _MetricCard(
                        title: 'Packing sessions',
                        value: _fmt(m.sessions),
                        subtitle: 'Scan & pack sessions',
                        icon: Icons.qr_code_scanner_rounded,
                        color: _green,
                      ),
                      _MetricCard(
                        title: 'Evidence media',
                        value: _fmt(m.evidence),
                        subtitle: 'Stored packing evidence',
                        icon: Icons.verified_outlined,
                        color: _rose,
                        onTap: () => _open('Evidence'),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),
              _SectionTitle('Platform modules'),
              const SizedBox(height: 4),
              Text(
                'P2–P10 — open each module. Screens show live data when API is ready; otherwise empty state (no fake rows).',
                style: TextStyle(color: const Color(0xFF475569), fontSize: 12),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth > 1000 ? 4 : (c.maxWidth > 640 ? 2 : 1);
                  final modules = <_Module>[
                    _Module('Companies', 'P2', 'Tenants list, activate / suspend', Icons.business_outlined, 'Companies'),
                    _Module('Users', 'P3', 'Search users across companies', Icons.people_outline, 'Users'),
                    _Module('Subscriptions', 'P6', 'Tenant × plan status', Icons.credit_card_outlined, 'Subscriptions'),
                    _Module('Plans', 'P4', 'Packages, limits, pricing', Icons.layers_outlined, 'Plans'),
                    _Module('Scan Top-Ups', 'P5', 'Extra credit catalog', Icons.add_card_outlined, 'Scan Top-Ups'),
                    _Module('Storage', 'P7', 'Usage by company', Icons.cloud_outlined, 'Storage'),
                    _Module('Analytics', 'P8', 'Platform trends', Icons.analytics_outlined, 'Analytics'),
                    _Module('Audit Logs', 'P9', 'Sensitive admin actions', Icons.history_outlined, 'Audit Logs'),
                    _Module('Settings', 'P10', 'Config & feature flags', Icons.settings_outlined, 'Settings'),
                    _Module('Evidence', 'Support', 'Cross-tenant evidence support', Icons.verified_outlined, 'Evidence'),
                    _Module('Profile', 'Account', 'Your platform admin profile', Icons.person_outline, 'Profile'),
                    _Module('Help', 'Support', 'Docs & contact', Icons.help_outline, 'Help'),
                  ];
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.4,
                    children: [
                      for (final mod in modules)
                        _ModuleTile(
                          module: mod,
                          onTap: () => _open(mod.navLabel),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),
              _SectionTitle('Operational notes'),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                color: const Color(0xFFF8FAFC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: const Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('• Metrics are live counts from the database (no placeholder numbers).'),
                      SizedBox(height: 6),
                      Text('• Companies / Users / Plans modules will be wired next with real tables.'),
                      SizedBox(height: 6),
                      Text('• Only PLATFORM_ADMIN can call this dashboard API.'),
                      SizedBox(height: 6),
                      Text('• Pull down to refresh metrics.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: TextStyle(fontSize: 12, color: const Color(0xFF475569))),
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              if (onTap != null) Icon(Icons.chevron_right, color: const Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Module {
  final String title;
  final String badge;
  final String subtitle;
  final IconData icon;
  final String navLabel;
  const _Module(this.title, this.badge, this.subtitle, this.icon, this.navLabel);
}

class _ModuleTile extends StatelessWidget {
  final _Module module;
  final VoidCallback onTap;
  const _ModuleTile({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(module.icon, size: 22, color: const Color(0xFF2563EB)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(module.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(module.badge, style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB))),
                        ),
                      ],
                    ),
                    Text(module.subtitle, style: TextStyle(fontSize: 11, color: const Color(0xFF64748B))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 12, color: const Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}


