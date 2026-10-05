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
import '../onboarding/onboarding_screen.dart';
import '../profile/profile_screen.dart';
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
    if (((r == 'PLATFORM_ADMIN' || r == 'SUPER_ADMIN') || r == 'SUPER_ADMIN')) return SaaSRole.platformAdmin;
    if (r == 'OPERATOR' || r == 'PACKING_OPERATOR') return SaaSRole.operator;
    if (r.isEmpty) return null;
    return SaaSRole.companyAdmin;
  }
  List<_NavItem> get _navigation {
    switch (_role) {
      case SaaSRole.platformAdmin:
        return const [
          _NavItem(Icons.dashboard_outlined, 'Dashboard'),
          _NavItem(Icons.business_outlined, 'Companies'),
          _NavItem(Icons.people_alt_outlined, 'Users & Roles'),
          _NavItem(Icons.warehouse_outlined, 'Warehouses'),
          _NavItem(Icons.local_shipping_outlined, 'Orders & Shipments'),
          _NavItem(Icons.video_library_outlined, 'Evidence & Recordings'),
          _NavItem(Icons.payments_outlined, 'Billing & Revenue'),
          _NavItem(Icons.workspace_premium_outlined, 'Plans & Subscriptions'),
          _NavItem(Icons.account_balance_wallet_outlined, 'Wallet & Credits'),
          _NavItem(Icons.analytics_outlined, 'Analytics & Reports'),
          _NavItem(Icons.history_outlined, 'Audit Logs'),
          _NavItem(Icons.monitor_heart_outlined, 'System Health'),
          _NavItem(Icons.extension_outlined, 'Integrations'),
          _NavItem(Icons.settings_outlined, 'Settings'),
        ];
      case SaaSRole.companyAdmin:
        return const [
          _NavItem(Icons.dashboard_outlined, 'Dashboard'),
          _NavItem(Icons.account_balance_wallet_outlined, 'Scan Wallet'),
          _NavItem(Icons.credit_card_outlined, 'Subscription'),
          _NavItem(Icons.receipt_long_outlined, 'Billing'),
          _NavItem(Icons.people_outline, 'Team'),
          _NavItem(Icons.warehouse_outlined, 'Warehouses'),
          _NavItem(Icons.inventory_2_outlined, 'Orders'),
          _NavItem(Icons.verified_outlined, 'Evidence'),
          _NavItem(Icons.extension_outlined, 'Integrations'),
          _NavItem(Icons.rocket_launch_outlined, 'Onboarding'),
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
            onOpenSection: (section) {
              final items = _navigation;
              final i = items.indexWhere(
                (e) => e.label == section,
              );

              if (i >= 0 && mounted) {
                setState(() => _index = i);
              }
            },
          );

        case 'Companies':
          return const PlatformCompaniesScreen();

        case 'Users & Roles':
          return const PlatformUsersScreen();

        case 'Warehouses':
          return const WarehouseScreen();

        case 'Orders & Shipments':
          return const OrdersScreen();

        case 'Evidence & Recordings':
          return const EvidenceScreen();

        case 'Billing & Revenue':
          return const PlatformSubscriptionsScreen();

        case 'Plans & Subscriptions':
          return const PlatformPlansScreen();

        case 'Wallet & Credits':
          return const PlatformTopUpsScreen();

        case 'Analytics & Reports':
          return const PlatformAnalyticsScreen();

        case 'Audit Logs':
          return const PlatformAuditLogsScreen();

        case 'System Health':
          return const PlatformStorageScreen();

        case 'Integrations':
          return const PlatformSettingsScreen();

        case 'Settings':
          return const PlatformSettingsScreen();
      }
    }
    if (_role == SaaSRole.companyAdmin) {
      switch (label) {
        case 'Dashboard':
          return const _SellerDashboardPage();
        case 'Scan Wallet':
          return const _ScanWalletPage();
        case 'Subscription':
          return const _SellerSubscriptionPage();
        case 'Billing':
          return const _BillingPage();
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
        case 'Onboarding':
          return const OnboardingScreen();
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

    return const _AdminDashboardPage();
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
    return Container(
      width: 232,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF071B48),
            Color(0xFF04132F),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ------------------------------------------------
            // BRAND
            // ------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(
                15,
                16,
                15,
                14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1769FF),
                          Color(0xFF0BC6FF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loss Defender',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Platform Administration',
                          style: TextStyle(
                            color: Color(0xFFB6C4E2),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------------------------
            // NAVIGATION
            // ------------------------------------------------
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  14,
                  4,
                  14,
                  8,
                ),
                itemCount: _navigation.length,
                itemBuilder: (context, index) {
                  final item = _navigation[index];
                  final selected = index == _index;

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 3,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius:
                            BorderRadius.circular(8),
                        onTap: () => _select(index),
                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 160,
                          ),
                          height: 42,
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 11,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF1769FF)
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(8),
                            boxShadow: selected
                                ? const [
                                    BoxShadow(
                                      color:
                                          Color(0x441769FF),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 19,
                                color: selected
                                    ? Colors.white
                                    : const Color(
                                        0xFFB7C3DA,
                                      ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : const Color(
                                            0xFFD4DCEE,
                                          ),
                                    fontSize: 11,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ------------------------------------------------
            // ADMIN PROFILE CARD
            // ------------------------------------------------
            Container(
              margin: const EdgeInsets.fromLTRB(
                14,
                8,
                14,
                10,
              ),
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: Colors.white.withAlpha(15),
                ),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: Color(0xFFFFA116),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Platform Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Full Access',
                          style: TextStyle(
                            color: Color(0xFF9EADCB),
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------------------------
            // LOGOUT
            // ------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                14,
              ),
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(7),
                onTap: () {
                  // Existing auth/session logout flow
                  // can be connected here.
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFC1CCE0),
                        size: 18,
                      ),
                      SizedBox(width: 11),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFFC1CCE0),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _topbar() {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(
        horizontal: 17,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE4E9F1),
          ),
        ),
      ),
      child: Row(
        children: [
          // MENU
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5FF),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.menu_rounded,
                color: Color(0xFF1769FF),
                size: 21,
              ),
            ),
          ),

          const SizedBox(width: 13),

          // GLOBAL SEARCH
          SizedBox(
            width: 570,
            height: 38,
            child: TextField(
              decoration: InputDecoration(
                hintText:
                    'Search companies, users, orders, warehouses...',
                hintStyle: const TextStyle(
                  color: Color(0xFF7B89A5),
                  fontSize: 11,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF1769FF),
                ),
                suffixIcon: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      'Ctrl + K',
                      style: TextStyle(
                        color: Color(0xFF8895AD),
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
                filled: true,
                fillColor:
                    const Color(0xFFF8FAFD),
                contentPadding:
                    const EdgeInsets.symmetric(
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: Color(0xFFDCE3EE),
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: Color(0xFFDCE3EE),
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: Color(0xFF1769FF),
                  ),
                ),
              ),
            ),
          ),

          const Spacer(),

          // DATE RANGE
          Container(
            height: 38,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 11,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(7),
              border: Border.all(
                color: const Color(0xFFDCE3EE),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: Color(0xFF0A1B55),
                ),
                SizedBox(width: 7),
                Text(
                  'Date Range',
                  style: TextStyle(
                    color: Color(0xFF10235E),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: Color(0xFF6F7D9E),
                ),
              ],
            ),
          ),

          const SizedBox(width: 11),

          // NOTIFICATIONS
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF10235E),
                  size: 23,
                ),
              ),
              Positioned(
                right: 5,
                top: 4,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration:
                      const BoxDecoration(
                    color: Color(0xFFF23D4F),
                    shape: BoxShape.circle,
                  ),
                  alignment:
                      Alignment.center,
                  child: const Text(
                    '!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 3),

          // PROFILE
          const CircleAvatar(
            radius: 18,
            backgroundColor:
                Color(0xFF1E4FBB),
            child: Text(
              'PA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 8),

          const Text(
            'Platform Admin',
            style: TextStyle(
              color: Color(0xFF10235E),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),

          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: Color(0xFF6F7D9E),
          ),
        ],
      ),
    );
  }
  Widget _mobileHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 62,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration:
            const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE4E9F1),
            ),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () =>
                  _scaffoldKey.currentState
                      ?.openDrawer(),
              icon: const Icon(
                Icons.menu_rounded,
                color: Color(0xFF10235E),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                gradient:
                    const LinearGradient(
                  colors: [
                    Color(0xFF1769FF),
                    Color(0xFF0BC6FF),
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                _navigation[_index].label,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF10235E),
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
            const CircleAvatar(
              radius: 15,
              backgroundColor:
                  Color(0xFF1E4FBB),
              child: Text(
                'PA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
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

class _AdminDashboardPage extends StatelessWidget {
  const _AdminDashboardPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Platform Overview',
      subtitle: 'Monitor the entire Loss Defender SaaS platform.',
      action: _PrimaryButton(
        label: 'View Analytics',
        icon: Icons.analytics_outlined,
        onPressed: () {},
      ),
      children: [
        _ResponsiveGrid(
          children: const [
            _MetricCard(
              title: 'Companies',
              value: '248',
              change: '+18 this month',
              icon: Icons.business_outlined,
              color: _blue,
            ),
            _MetricCard(
              title: 'Total Users',
              value: '1,842',
              change: '+126 this month',
              icon: Icons.people_outline,
              color: _cyan,
            ),
            _MetricCard(
              title: 'Scans',
              value: '1.28M',
              change: '+8.4% this month',
              icon: Icons.qr_code_scanner_rounded,
              color: _green,
            ),
            _MetricCard(
              title: 'Storage',
              value: '2.84 TB',
              change: '+184 GB this month',
              icon: Icons.cloud_outlined,
              color: _amber,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ResponsiveGrid(
          children: const [
            _MetricCard(
              title: 'Active Subscriptions',
              value: '219',
              change: '88.3% of companies',
              icon: Icons.credit_card_outlined,
              color: _blue,
            ),
            _MetricCard(
              title: 'Evidence',
              value: '1.24M',
              change: 'Videos + photos',
              icon: Icons.verified_outlined,
              color: _green,
            ),
            _MetricCard(
              title: 'Packing Operators',
              value: '1,426',
              change: 'Across 248 companies',
              icon: Icons.badge_outlined,
              color: _cyan,
            ),
            _MetricCard(
              title: 'Monthly Revenue',
              value: '₹8.42L',
              change: '+12.7%',
              icon: Icons.currency_rupee_rounded,
              color: _green,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Platform Activity',
          subtitle: 'Latest events across the platform.',
          child: Column(
            children: const [
              _ActivityRow(
                icon: Icons.person_add_alt_1_outlined,
                title: 'New company registered',
                subtitle: 'Nova Retail • Business plan',
                time: '4 min ago',
                color: _blue,
              ),
              _ActivityRow(
                icon: Icons.qr_code_scanner_rounded,
                title: '10,000 scans processed',
                subtitle: 'ABC Traders • Main Warehouse',
                time: '18 min ago',
                color: _green,
              ),
              _ActivityRow(
                icon: Icons.cloud_upload_outlined,
                title: 'Evidence storage increased',
                subtitle: 'XYZ Enterprises • +4.8 GB',
                time: '42 min ago',
                color: _cyan,
              ),
              _ActivityRow(
                icon: Icons.credit_card_outlined,
                title: 'Subscription renewed',
                subtitle: 'Prime Distribution • Enterprise',
                time: '1 hr ago',
                color: _amber,
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _SellerDashboardPage extends StatelessWidget {
  const _SellerDashboardPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Company Dashboard',
      subtitle: 'ABC Traders • Main Warehouse',
      action: _PrimaryButton(
        label: 'Start Packing',
        icon: Icons.qr_code_scanner_rounded,
        onPressed: () {},
      ),
      children: [
        _ResponsiveGrid(
          children: const [
            _MetricCard(
              title: 'Scans Remaining',
              value: '3,518',
              change: 'of 10,000',
              icon: Icons.qr_code_scanner_rounded,
              color: _blue,
            ),
            _MetricCard(
              title: 'Orders Today',
              value: '428',
              change: '+12.4%',
              icon: Icons.inventory_2_outlined,
              color: _cyan,
            ),
            _MetricCard(
              title: 'Evidence',
              value: '6,492',
              change: 'This month',
              icon: Icons.verified_outlined,
              color: _green,
            ),
            _MetricCard(
              title: 'Storage',
              value: '36 GB',
              change: 'of 100 GB',
              icon: Icons.cloud_outlined,
              color: _amber,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ResponsiveGrid(
          children: const [
            _ChartCard(
              title: 'Packing Volume',
              subtitle: 'Today vs previous 7 days',
            ),
            _ChartCard(
              title: 'Scan Usage',
              subtitle: 'Subscription consumption',
            ),
          ],
        ),
      ],
    );
  }
}

class _ScanWalletPage extends StatelessWidget {
  const _ScanWalletPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Scan Wallet',
      subtitle: 'Track subscription scans and purchased top-ups.',
      action: _PrimaryButton(
        label: 'Buy Top-Up',
        icon: Icons.add_card_outlined,
        onPressed: () {},
      ),
      children: [
        _ResponsiveGrid(
          children: const [
            _MetricCard(
              title: 'Allocated',
              value: '10,000',
              change: 'Business plan',
              icon: Icons.account_balance_wallet_outlined,
              color: _blue,
            ),
            _MetricCard(
              title: 'Used',
              value: '6,482',
              change: '64.8%',
              icon: Icons.qr_code_scanner_rounded,
              color: _cyan,
            ),
            _MetricCard(
              title: 'Top-Ups',
              value: '10,000',
              change: 'Purchased',
              icon: Icons.add_card_outlined,
              color: _amber,
            ),
            _MetricCard(
              title: 'Remaining',
              value: '3,518',
              change: 'Available',
              icon: Icons.check_circle_outline,
              color: _green,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Wallet Ledger',
          child: _DataTableCard(
            columns: const [
              'Date',
              'Type',
              'Description',
              'Credit',
              'Debit',
              'Balance',
            ],
            rows: const [
              ['26 Sep', 'Usage', 'Packing scans', '-', '428', '3,518'],
              ['25 Sep', 'Usage', 'Packing scans', '-', '512', '3,946'],
              ['22 Sep', 'Top-Up', '10K package', '10,000', '-', '4,458'],
            ],
          ),
        ),
      ],
    );
  }
}

class _SellerSubscriptionPage extends StatelessWidget {
  const _SellerSubscriptionPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Subscription',
      subtitle: 'Manage your current plan and usage limits.',
      children: [
        _SectionCard(
          title: 'Business Plan',
          subtitle: 'Active subscription',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text(
                    '₹2,999',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _navy,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('/ month', style: TextStyle(color: _muted)),
                  Spacer(),
                  _StatusBadge(text: 'ACTIVE', color: _green),
                ],
              ),
              const SizedBox(height: 20),
              const _UsageBar(
                label: 'Scans',
                used: '6,482',
                total: '10,000',
                value: .648,
              ),
              const SizedBox(height: 14),
              const _UsageBar(
                label: 'Storage',
                used: '36 GB',
                total: '100 GB',
                value: .36,
              ),
              const SizedBox(height: 20),
              const Text(
                'Started: 15 Sep 2026',
                style: TextStyle(color: _muted),
              ),
              const SizedBox(height: 4),
              const Text(
                'Renewal: 15 Oct 2026',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BillingPage extends StatelessWidget {
  const _BillingPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Billing',
      subtitle: 'Invoices, payments and transaction history.',
      action: _PrimaryButton(
        label: 'Download Statement',
        icon: Icons.download_outlined,
        onPressed: () {},
      ),
      children: [
        _ResponsiveGrid(
          children: const [
            _MetricCard(
              title: 'Current Plan',
              value: '₹2,999',
              change: 'Monthly',
              icon: Icons.credit_card_outlined,
              color: _blue,
            ),
            _MetricCard(
              title: 'Top-Ups',
              value: '₹999',
              change: 'This month',
              icon: Icons.add_card_outlined,
              color: _cyan,
            ),
            _MetricCard(
              title: 'Total',
              value: '₹3,998',
              change: 'September',
              icon: Icons.currency_rupee_rounded,
              color: _green,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Invoices',
          child: _DataTableCard(
            columns: const [
              'Invoice',
              'Date',
              'Description',
              'Amount',
              'Status',
            ],
            rows: const [
              ['INV-2026-0915', '15 Sep', 'Business Plan', '₹2,999', 'PAID'],
              ['TOP-2026-0922', '22 Sep', '10K Scan Top-Up', '₹499', 'PAID'],
              ['TOP-2026-0925', '25 Sep', '25K Scan Top-Up', '₹999', 'PAID'],
            ],
          ),
        ),
      ],
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
  final String? subtitle;
  final Widget child;

  const _SectionCard({this.title, this.subtitle, required this.child});

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
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ],
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


class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ChartCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      subtitle: subtitle,
      child: SizedBox(
        height: 180,
        child: CustomPaint(
          painter: _MiniChartPainter(),
          child: const Center(
            child: Text(
              'Live analytics',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _border
      ..strokeWidth = 1;

    final linePaint = Paint()
      ..color = _blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = [
      Offset(0, size.height * .72),
      Offset(size.width * .12, size.height * .58),
      Offset(size.width * .25, size.height * .66),
      Offset(size.width * .38, size.height * .35),
      Offset(size.width * .50, size.height * .47),
      Offset(size.width * .64, size.height * .26),
      Offset(size.width * .78, size.height * .38),
      Offset(size.width * .90, size.height * .18),
      Offset(size.width, size.height * .24),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _UsageBar extends StatelessWidget {
  final String label;
  final String used;
  final String total;
  final double value;

  const _UsageBar({
    required this.label,
    required this.used,
    required this.total,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(
              '$used / $total',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: _border,
            valueColor: const AlwaysStoppedAnimation(_blue),
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  const _ActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: _muted, fontSize: 10)),
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
