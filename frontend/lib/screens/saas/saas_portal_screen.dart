import '../platform/platform_topups_screen.dart';
import '../platform/platform_ops_screens.dart';
import '../platform/platform_subscriptions_screen.dart';
import '../platform/platform_plans_screen.dart';
import '../platform/platform_users_screen.dart';
import 'package:flutter/material.dart';
import '../platform/platform_dashboard_screen.dart';
import '../platform/platform_companies_screen.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../orders/orders_screen.dart';
import '../warehouse/warehouse_screen.dart';
import '../scan_pack/scan_pack_screen.dart';
import '../team/team_screen.dart';
import '../evidence/evidence_screen.dart';
import '../profile/profile_screen.dart';
import 'company_workspace_live_screens.dart';

enum SaaSRole { platformAdmin, companyAdmin, operator }

class SaaSPortalScreen extends StatefulWidget {
  final SaaSRole initialRole;

  const SaaSPortalScreen({
    super.key,
    this.initialRole = SaaSRole.platformAdmin,
  });

  @override
  State<SaaSPortalScreen> createState() => _SaaSPortalScreenState();
}

class _SaaSPortalScreenState extends State<SaaSPortalScreen> {
  late SaaSRole _role;
  int _index = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
    // Real role wins over preview (security + UX)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = context.read<SessionProvider>();
      final mapped = _mapSessionRole(session.user?.role);
      if (mapped != null && mapped != _role) {
        setState(() {
          _role = mapped;
          _index = 0;
        });
      }
    });
  }

  SaaSRole? _mapSessionRole(String? role) {
    final r = (role ?? '').trim().toUpperCase().replaceAll('-', '_');
    if (r == 'PLATFORM_ADMIN' || r == 'SUPER_ADMIN') {
      return SaaSRole.platformAdmin;
    }
    if (r == 'OPERATOR' || r == 'PACKING_OPERATOR') return SaaSRole.operator;
    if (r.isEmpty) {
      return null;
    }
    return SaaSRole.companyAdmin;
  }

  String get _roleLabel {
    switch (_role) {
      case SaaSRole.platformAdmin:
        return 'Platform Admin';
      case SaaSRole.companyAdmin:
        return 'Company Owner';
      case SaaSRole.operator:
        return 'Packing Operator';
    }
  }

  List<_NavItem> get _navigation {
    switch (_role) {
      case SaaSRole.platformAdmin:
        return const [
          _NavItem(Icons.dashboard_outlined, 'Dashboard'),
          _NavItem(Icons.business_outlined, 'Companies'),
          _NavItem(Icons.people_outline, 'Users'),
          _NavItem(Icons.credit_card_outlined, 'Subscriptions'),
          _NavItem(Icons.layers_outlined, 'Plans'),
          _NavItem(Icons.add_card_outlined, 'Scan Top-Ups'),
          _NavItem(Icons.cloud_outlined, 'Storage'),
          _NavItem(Icons.analytics_outlined, 'Analytics'),
          _NavItem(Icons.history_outlined, 'Audit Logs'),
          _NavItem(Icons.settings_outlined, 'Settings'),
          _NavItem(Icons.person_outline, 'Profile'),
        ];

      case SaaSRole.companyAdmin:
        return const [
          _NavItem(Icons.dashboard_outlined, 'Dashboard'),
          _NavItem(Icons.qr_code_scanner_outlined, 'Scan & Pack'),
          _NavItem(Icons.account_balance_wallet_outlined, 'Scan Wallet'),
          _NavItem(Icons.credit_card_outlined, 'Subscription'),
          _NavItem(Icons.receipt_long_outlined, 'Billing'),
          _NavItem(Icons.people_outline, 'Team'),
          _NavItem(Icons.warehouse_outlined, 'Warehouses'),
          _NavItem(Icons.inventory_2_outlined, 'Orders'),
          _NavItem(Icons.verified_outlined, 'Evidence'),
          _NavItem(Icons.extension_outlined, 'Integrations'),
          _NavItem(Icons.person_outline, 'Profile'),
          _NavItem(Icons.settings_outlined, 'Settings'),
          _NavItem(Icons.help_outline, 'Help'),
        ];

      case SaaSRole.operator:
        return const [
          _NavItem(Icons.dashboard_outlined, 'Dashboard'),
          _NavItem(Icons.qr_code_scanner_outlined, 'Scan & Pack'),
          _NavItem(Icons.play_circle_outline, 'My Sessions'),
          _NavItem(Icons.video_library_outlined, 'Recordings'),
          _NavItem(Icons.verified_outlined, 'Evidence'),
          _NavItem(Icons.person_outline, 'Profile'),
          _NavItem(Icons.help_outline, 'Help'),
        ];
    }
  }

  Widget _currentPage() {
    final label = _navigation[_index].label;

    if (_role == SaaSRole.platformAdmin) {
      switch (label) {
        case 'Dashboard':
          return PlatformDashboardScreen(
            onOpenSection: (label) {
              final items = _navigation;
              final i = items.indexWhere((e) => e.label == label);
              if (i >= 0) setState(() => _index = i);
            },
          );
        case 'Companies':
          return const PlatformCompaniesScreen();
        case 'Users':
          return const PlatformUsersScreen();
        case 'Subscriptions':
          return const PlatformSubscriptionsScreen();
        case 'Plans':
          return const PlatformPlansScreen();
        case 'Scan Top-Ups':
          return const PlatformTopUpsScreen();
        case 'Storage':
          return const PlatformStorageScreen();
        case 'Analytics':
          return const PlatformAnalyticsScreen();
        case 'Audit Logs':
          return const PlatformAuditLogsScreen();
        case 'Settings':
          return const PlatformSettingsScreen();
        case 'Profile':
          return const ProfileScreen();
      }
    }

    if (_role == SaaSRole.companyAdmin) {
      switch (label) {
        case 'Dashboard':
          return CompanyWorkspaceDashboardScreen(
            onScanPack: () {
              final target = _navigation.indexWhere(
                (item) => item.label == 'Scan & Pack',
              );

              if (target >= 0) {
                setState(() => _index = target);
              }
            },
          );

        case 'Scan & Pack':
          return const ScanPackScreen();

        case 'Scan Wallet':
          return const CompanyWalletScreen();

        case 'Subscription':
          return const CompanySubscriptionScreen();

        case 'Billing':
          return const CompanyBillingScreen();

        case 'Team':
          return const TeamScreen();

        case 'Warehouses':
          return const WarehouseScreen();

        case 'Orders':
          return const OrdersScreen();

        case 'Evidence':
          return const EvidenceScreen();

        case 'Integrations':
          return const _IntegrationsPage();

        case 'Profile':
          return const ProfileScreen();

        case 'Settings':
          return const _CompanySettingsPage();

        case 'Help':
          return const _HelpPage();
      }
    }
    switch (label) {
      case 'Dashboard':
        return const _OperatorDashboardPage();
      case 'Scan & Pack':
        return const ScanPackScreen();
      case 'My Sessions':
        return const _SessionsPage();
      case 'Recordings':
        return const _RecordingsPage();
      case 'Evidence':
        return const _OperatorEvidencePage();
      case 'Profile':
        return const ProfileScreen();
      case 'Help':
        return const _HelpPage();
    }

    return const _OperatorDashboardPage();
  }

  Future<void> _logout() async {
    final shouldLogout =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Logout'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldLogout || !mounted) {
      return;
    }

    await context.read<SessionProvider>().signOut();
  }

  void _select(int index) {
    setState(() => _index = index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: _mobileDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 1100;

          if (!desktop) {
            return Column(
              children: [
                _mobileHeader(),
                Expanded(child: _currentPage()),
              ],
            );
          }

          return Row(
            children: [
              _sidebar(),
              Expanded(
                child: Column(
                  children: [
                    _topbar(),
                    Expanded(child: _currentPage()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sidebar() {
    final sessionUser = context.watch<SessionProvider>().user;
    final isPlatform = sessionUser?.isPlatformAdmin == true;
    final companyName = sessionUser?.company?.name.trim() ?? '';

    return Container(
      width: 252,
      color: _navy,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 18, 22),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_blue, _cyan]),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'LOSS DEFENDER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(15)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPlatform
                          ? Icons.admin_panel_settings_outlined
                          : Icons.business_center_outlined,
                      color: Colors.white70,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPlatform ? 'Platform Admin' : 'Company Owner',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          if (companyName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              companyName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _navigation.length,
                itemBuilder: (context, index) {
                  final item = _navigation[index];
                  final selected = index == _index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        selected: selected,
                        leading: Icon(
                          item.icon,
                          size: 20,
                          color: selected ? Colors.white : Colors.white60,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.white70,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        onTap: () => _select(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withAlpha(55)),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 9, color: _green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'System operational',
                      style: TextStyle(
                        color: Colors.white.withAlpha(180),
                        fontSize: 11,
                      ),
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

  Widget _topbar() {
    final title = _navigation[_index].label;
    final user = context.watch<SessionProvider>().user;

    final avatarText =
        (user?.name.trim().isNotEmpty == true
                ? user!.name.trim()
                : user?.email.trim().isNotEmpty == true
                ? user!.email.trim()
                : 'U')
            .characters
            .first
            .toUpperCase();

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _roleLabel,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 240,
            height: 40,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                filled: true,
                fillColor: _bg,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: _border),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: _navy,
            child: Text(
              avatarText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _border)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.shield_rounded, color: _blue),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                _navigation[_index].label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.circle, color: _green, size: 9),
          ],
        ),
      ),
    );
  }

  Widget _mobileDrawer() {
    return Drawer(
      backgroundColor: _navy,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const ListTile(
              leading: Icon(Icons.shield_rounded, color: _blue),
              title: Text(
                'LOSS DEFENDER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: ListView.builder(
                itemCount: _navigation.length,
                itemBuilder: (context, index) {
                  final item = _navigation[index];
                  final selected = index == _index;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        selected: selected,
                        leading: Icon(
                          item.icon,
                          size: 20,
                          color: selected ? Colors.white : Colors.white60,
                        ),
                        title: Text(
                          item.label,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.white70,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        onTap: () => _select(index),
                      ),
                    ),
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

class _IntegrationsPage extends StatelessWidget {
  const _IntegrationsPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Integrations',
      subtitle: 'Connect marketplaces and warehouse systems.',
      children: [
        _IntegrationCard(
          name: 'Amazon',
          description: 'Orders, shipments and marketplace synchronization.',
          icon: Icons.shopping_cart_outlined,
          status: 'CONNECTED',
          color: _amber,
        ),
        const SizedBox(height: 12),
        _IntegrationCard(
          name: 'Flipkart',
          description: 'Shipment and order synchronization.',
          icon: Icons.storefront_outlined,
          status: 'PENDING',
          color: _blue,
        ),
        const SizedBox(height: 12),
        _IntegrationCard(
          name: 'Webhooks / API',
          description: 'Connect your own order management system.',
          icon: Icons.api_outlined,
          status: 'AVAILABLE',
          color: _cyan,
        ),
      ],
    );
  }
}

class _OperatorDashboardPage extends StatelessWidget {
  const _OperatorDashboardPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Packing Dashboard',
      subtitle: 'Main Warehouse • Rahul Kumar',
      action: _PrimaryButton(
        label: 'Start Scan',
        icon: Icons.qr_code_scanner_rounded,
        onPressed: () {},
      ),
      children: [
        _ResponsiveGrid(
          children: const [
            _MetricCard(
              title: 'My Scans',
              value: '1,238',
              change: 'This month',
              icon: Icons.qr_code_scanner_rounded,
              color: _blue,
            ),
            _MetricCard(
              title: 'Packed Today',
              value: '184',
              change: '+14.2%',
              icon: Icons.inventory_2_outlined,
              color: _green,
            ),
            _MetricCard(
              title: 'Evidence',
              value: '184',
              change: 'Today',
              icon: Icons.verified_outlined,
              color: _cyan,
            ),
            _MetricCard(
              title: 'Exceptions',
              value: '3',
              change: 'Needs attention',
              icon: Icons.warning_amber_rounded,
              color: _amber,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Current Session',
          child: Row(
            children: const [
              Icon(Icons.circle, color: _green, size: 10),
              SizedBox(width: 9),
              Text(
                'Scanner connected • Camera ready',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SessionsPage extends StatelessWidget {
  const _SessionsPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'My Packing Sessions',
      subtitle: 'Your recent packing activity.',
      children: [
        _SectionCard(
          title: 'Recent Sessions',
          child: _DataTableCard(
            columns: const [
              'AWB',
              'Order',
              'Started',
              'Duration',
              'Evidence',
              'Status',
            ],
            rows: const [
              [
                '368275770371',
                '406-3151945-3281902',
                '12:48',
                '00:16',
                '1',
                'COMPLETED',
              ],
              [
                'FMPP3767030215',
                '331724360573683072_1',
                '12:42',
                '00:21',
                '2',
                'COMPLETED',
              ],
              [
                '1490841263428112',
                '331724360573683072_2',
                '12:37',
                '00:09',
                '1',
                'ACTIVE',
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RecordingsPage extends StatelessWidget {
  const _RecordingsPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Recordings',
      subtitle: 'Packing videos captured during your sessions.',
      children: [
        _ResponsiveGrid(
          children: const [
            _MetricCard(
              title: 'Videos',
              value: '5,982',
              change: '28.4 GB',
              icon: Icons.video_library_outlined,
              color: _blue,
            ),
            _MetricCard(
              title: 'Verified',
              value: '5,941',
              change: '99.3%',
              icon: Icons.verified_outlined,
              color: _green,
            ),
            _MetricCard(
              title: 'Processing',
              value: '8',
              change: 'In progress',
              icon: Icons.sync_outlined,
              color: _amber,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Latest Recordings',
          child: _DataTableCard(
            columns: const ['AWB', 'SKU', 'Duration', 'Size', 'Status'],
            rows: const [
              ['368275770371', '97-U1YR-N3GW', '16 sec', '4.8 MB', 'VERIFIED'],
              ['FMPP3767030215', 'DG-LT-S', '21 sec', '6.1 MB', 'VERIFIED'],
              [
                '1490841263428112',
                'PC-TWISTER-001',
                '9 sec',
                '3.2 MB',
                'READY',
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OperatorEvidencePage extends StatelessWidget {
  const _OperatorEvidencePage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'My Evidence',
      subtitle: 'Evidence generated by your packing sessions.',
      children: [
        _SectionCard(
          title: 'Recent Evidence',
          child: _DataTableCard(
            columns: const ['AWB', 'SKU', 'Type', 'Created', 'Status'],
            rows: const [
              ['368275770371', '97-U1YR-N3GW', 'Video', '12:48', 'VERIFIED'],
              ['FMPP3767030215', 'DG-LT-S', 'Video', '12:42', 'VERIFIED'],
              ['1490841263428112', 'PC-TWISTER-001', 'Video', '12:37', 'READY'],
            ],
          ),
        ),
      ],
    );
  }
}

class _CompanySettingsPage extends StatelessWidget {
  const _CompanySettingsPage();

  @override
  Widget build(BuildContext context) {
    return const _SettingsPage(
      title: 'Company Settings',
      subtitle: 'Configure your company workspace.',
    );
  }
}

class _SettingsPage extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SettingsPage({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: title,
      subtitle: subtitle,
      children: [
        _SettingTile(
          icon: Icons.business_outlined,
          title: 'Company',
          subtitle: 'Company identity, address and business details.',
        ),
        _SettingTile(
          icon: Icons.notifications_none_outlined,
          title: 'Notifications',
          subtitle: 'Email, system and operational notifications.',
        ),
        _SettingTile(
          icon: Icons.security_outlined,
          title: 'Security',
          subtitle: 'Authentication, sessions and security policies.',
        ),
        _SettingTile(
          icon: Icons.tune_outlined,
          title: 'Packing Preferences',
          subtitle: 'Scanner, camera and evidence preferences.',
        ),
        _SettingTile(
          icon: Icons.palette_outlined,
          title: 'Appearance',
          subtitle: 'Theme, density and interface preferences.',
        ),
      ],
    );
  }
}

class _HelpPage extends StatelessWidget {
  const _HelpPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Help & Support',
      subtitle: 'Get help with Loss Defender.',
      children: [
        _ResponsiveGrid(
          children: const [
            _HelpCard(
              icon: Icons.menu_book_outlined,
              title: 'Documentation',
              subtitle: 'Learn how scanning, packing and evidence work.',
            ),
            _HelpCard(
              icon: Icons.chat_bubble_outline,
              title: 'Contact Support',
              subtitle: 'Create a support request with our team.',
            ),
            _HelpCard(
              icon: Icons.play_circle_outline,
              title: 'Getting Started',
              subtitle: 'Follow the setup guide for your warehouse.',
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Frequently Asked Questions',
          child: Column(
            children: const [
              _FaqRow(question: 'How does a packing scan consume credits?'),
              _FaqRow(question: 'Where are packing videos stored?'),
              _FaqRow(question: 'How can I add a packing operator?'),
              _FaqRow(question: 'How do scan top-ups work?'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Page extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  final List<Widget> children;

  const _Page({
    required this.title,
    required this.subtitle,
    this.action,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: const TextStyle(color: _muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  action ?? const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: 22),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = 1;

        if (constraints.maxWidth >= 1250) {
          columns = 4;
        } else if (constraints.maxWidth >= 800) {
          columns = 2;
        }

        final width = (constraints.maxWidth - ((columns - 1) * 14)) / columns;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: _muted, size: 20),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _navy,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _navy,
              ),
            ),

            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}

class _DataTableCard extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;

  const _DataTableCard({required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(_bg),
        columnSpacing: 30,
        columns: columns
            .map(
              (column) => DataColumn(
                label: Text(
                  column,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: _muted,
                  ),
                ),
              ),
            )
            .toList(),
        rows: rows
            .map(
              (row) => DataRow(
                cells: row
                    .asMap()
                    .entries
                    .map(
                      (entry) => DataCell(
                        entry.key == row.length - 1
                            ? _StatusBadge(
                                text: entry.value,
                                color: _statusColor(entry.value),
                              )
                            : Text(
                                entry.value,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    )
                    .toList(),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: .3,
        ),
      ),
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  final String name;
  final String description;
  final IconData icon;
  final String status;
  final Color color;

  const _IntegrationCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          _StatusBadge(text: status, color: _statusColor(status)),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: () {},
            child: Text(status == 'CONNECTED' ? 'Manage' : 'Connect'),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _blue.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _blue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: _muted, fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {},
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HelpCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _blue, size: 28),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: () {}, child: const Text('Open')),
        ],
      ),
    );
  }
}

class _FaqRow extends StatelessWidget {
  final String question;

  const _FaqRow({required this.question});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text(
        question,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
      children: const [
        Padding(
          padding: EdgeInsets.only(left: 0, right: 0, bottom: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'This section will contain the final Loss Defender documentation and workflow guidance.',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}

Color _statusColor(String status) {
  final value = status.toUpperCase();

  if (value.contains('ACTIVE') ||
      value.contains('PAID') ||
      value.contains('VERIFIED') ||
      value.contains('COMPLETED')) {
    return _green;
  }

  if (value.contains('PENDING') ||
      value.contains('TRIAL') ||
      value.contains('READY') ||
      value.contains('PROCESSING') ||
      value.contains('INVITED')) {
    return _amber;
  }

  if (value.contains('EXPIRED') ||
      value.contains('CANCELLED') ||
      value.contains('FAILED') ||
      value.contains('SUSPENDED')) {
    return _red;
  }

  return _blue;
}

const _navy = Color(0xFF0F172A);
const _blue = Color(0xFF2563EB);
const _cyan = Color(0xFF06B6D4);
const _green = Color(0xFF16A34A);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFDC2626);
const _bg = Color(0xFFF8FAFC);
const _border = Color(0xFFE2E8F0);
const _muted = Color(0xFF64748B);
