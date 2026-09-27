import 'package:flutter/material.dart';

import '../scan_pack/scan_pack_screen.dart';

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
  }

  

  String get _roleLabel {
    switch (_role) {
      case SaaSRole.platformAdmin:
        return 'Platform Admin';
      case SaaSRole.companyAdmin:
        return 'Company Admin';
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
          _NavItem(Icons.verified_outlined, 'Evidence'),
          _NavItem(Icons.cloud_outlined, 'Storage'),
          _NavItem(Icons.analytics_outlined, 'Analytics'),
          _NavItem(Icons.history_outlined, 'Audit Logs'),
          _NavItem(Icons.settings_outlined, 'Settings'),
          _NavItem(Icons.person_outline, 'Profile'),
          _NavItem(Icons.help_outline, 'Help'),
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
          return const _AdminDashboardPage();
        case 'Companies':
          return const _CompaniesPage();
        case 'Users':
          return const _UsersPage();
        case 'Subscriptions':
          return const _SubscriptionsPage();
        case 'Plans':
          return const _PlansPage();
        case 'Scan Top-Ups':
          return const _TopUpsPage();
        case 'Evidence':
          return const _AdminEvidencePage();
        case 'Storage':
          return const _StoragePage();
        case 'Analytics':
          return const _AdminAnalyticsPage();
        case 'Audit Logs':
          return const _AuditLogsPage();
        case 'Settings':
          return const _PlatformSettingsPage();
        case 'Profile':
          return const _ProfilePage();
        case 'Help':
          return const _HelpPage();
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
          return const _TeamPage();
        case 'Warehouses':
          return const _WarehousePage();
        case 'Orders':
          return const _SellerOrdersPage();
        case 'Evidence':
          return const _SellerEvidencePage();
        case 'Integrations':
          return const _IntegrationsPage();
        case 'Onboarding':
          return const _OnboardingPage();
        case 'Profile':
          return const _ProfilePage();
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
        return const _ProfilePage();
      case 'Help':
        return const _HelpPage();
    }

    return const _AdminDashboardPage();
  }

  void _select(int index) {
    setState(() => _index = index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  void _changeRole(SaaSRole role) {
    setState(() {
      _role = role;
      _index = 0;
    });
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
            _roleSwitcher(),
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
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      selected: selected,
                      selectedTileColor: Colors.white.withAlpha(18),
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
                  );
                },
              ),
            ),
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

  Widget _roleSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: PopupMenuButton<SaaSRole>(
        tooltip: 'Preview role',
        onSelected: _changeRole,
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: SaaSRole.platformAdmin,
            child: Text('Platform Admin'),
          ),
          PopupMenuItem(
            value: SaaSRole.companyAdmin,
            child: Text('Company Admin'),
          ),
          PopupMenuItem(
            value: SaaSRole.operator,
            child: Text('Packing Operator'),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withAlpha(15)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_outlined,
                color: Colors.white70,
                size: 19,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _roleLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white54,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topbar() {
    final title = _navigation[_index].label;

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
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 5),
          CircleAvatar(
            radius: 18,
            backgroundColor: _navy,
            child: const Text(
              'S',
              style: TextStyle(
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

                  return ListTile(
                    selected: index == _index,
                    selectedTileColor: Colors.white.withAlpha(18),
                    leading: Icon(
                      item.icon,
                      color: index == _index ? Colors.white : Colors.white60,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: index == _index ? Colors.white : Colors.white70,
                      ),
                    ),
                    onTap: () => _select(index),
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

class _CompaniesPage extends StatelessWidget {
  const _CompaniesPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Companies',
      subtitle: 'Manage every seller and organization using Loss Defender.',
      action: _PrimaryButton(
        label: 'Add Company',
        icon: Icons.add_business_outlined,
        onPressed: () {},
      ),
      children: [
        const _FilterBar(
          search: 'Search companies...',
          filters: ['All', 'Active', 'Trial', 'Expired'],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: '248 Companies',
          child: _DataTableCard(
            columns: const [
              'Company',
              'Plan',
              'Users',
              'Scans',
              'Storage',
              'Status',
            ],
            rows: const [
              ['ABC Traders', 'Business', '18', '42,184', '86.4 GB', 'ACTIVE'],
              ['Nova Retail', 'Starter', '5', '7,428', '12.8 GB', 'ACTIVE'],
              [
                'Prime Distribution',
                'Enterprise',
                '64',
                '184,921',
                '482 GB',
                'ACTIVE',
              ],
              [
                'XYZ Enterprises',
                'Business',
                '12',
                '31,802',
                '58.2 GB',
                'TRIAL',
              ],
              ['Metro Commerce', 'Starter', '3', '2,194', '4.2 GB', 'EXPIRED'],
            ],
          ),
        ),
      ],
    );
  }
}

class _UsersPage extends StatelessWidget {
  const _UsersPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Users',
      subtitle: 'Inspect user profiles, activity, scans and storage usage.',
      action: _PrimaryButton(
        label: 'Export Users',
        icon: Icons.download_outlined,
        onPressed: () {},
      ),
      children: [
        const _FilterBar(
          search: 'Search name, email or company...',
          filters: ['All Roles', 'Admin', 'Operator', 'Active', 'Suspended'],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: '1,842 Users',
          child: _DataTableCard(
            columns: const [
              'User',
              'Company',
              'Role',
              'Plan',
              'Scans',
              'Storage',
            ],
            rows: const [
              [
                'Sanjeet Dayma',
                'ABC Traders',
                'Admin',
                'Business',
                '6,482',
                '36 GB',
              ],
              [
                'Rahul Kumar',
                'ABC Traders',
                'Operator',
                'Business',
                '1,238',
                '8 GB',
              ],
              [
                'Amit Sharma',
                'Nova Retail',
                'Operator',
                'Starter',
                '842',
                '2.8 GB',
              ],
              [
                'Vikas Yadav',
                'Prime Distribution',
                'Admin',
                'Enterprise',
                '22,482',
                '74 GB',
              ],
              [
                'Neeraj Singh',
                'XYZ Enterprises',
                'Operator',
                'Business',
                '3,128',
                '14 GB',
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SubscriptionsPage extends StatelessWidget {
  const _SubscriptionsPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Subscriptions',
      subtitle: 'Track active plans, renewals, expiry and subscription health.',
      children: [
        _ResponsiveGrid(
          children: const [
            _MetricCard(
              title: 'Active',
              value: '219',
              change: '88.3%',
              icon: Icons.check_circle_outline,
              color: _green,
            ),
            _MetricCard(
              title: 'Trial',
              value: '21',
              change: '8.5%',
              icon: Icons.timelapse_outlined,
              color: _cyan,
            ),
            _MetricCard(
              title: 'Expiring Soon',
              value: '8',
              change: 'Next 7 days',
              icon: Icons.warning_amber_rounded,
              color: _amber,
            ),
            _MetricCard(
              title: 'Expired',
              value: '12',
              change: '4.8%',
              icon: Icons.cancel_outlined,
              color: _red,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Recent Subscriptions',
          child: _DataTableCard(
            columns: const [
              'Company',
              'Plan',
              'Started',
              'Renewal',
              'Scans',
              'Status',
            ],
            rows: const [
              [
                'ABC Traders',
                'Business',
                '15 Sep',
                '15 Oct',
                '3,518 left',
                'ACTIVE',
              ],
              [
                'Nova Retail',
                'Starter',
                '22 Sep',
                '22 Oct',
                '2,572 left',
                'ACTIVE',
              ],
              [
                'Prime Distribution',
                'Enterprise',
                '01 Sep',
                '01 Oct',
                '74,820 left',
                'ACTIVE',
              ],
              [
                'Metro Commerce',
                'Starter',
                '26 Aug',
                '26 Sep',
                '0 left',
                'EXPIRED',
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlansPage extends StatelessWidget {
  const _PlansPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Subscription Plans',
      subtitle: 'Configure plans, limits, included scans and storage.',
      action: _PrimaryButton(
        label: 'Create Plan',
        icon: Icons.add_rounded,
        onPressed: () {},
      ),
      children: [
        _ResponsiveGrid(
          children: const [
            _PlanCard(
              name: 'Starter',
              price: '₹999',
              scans: '5,000 scans',
              users: '3 team members',
              storage: '25 GB',
              color: _blue,
            ),
            _PlanCard(
              name: 'Business',
              price: '₹2,999',
              scans: '25,000 scans',
              users: '15 team members',
              storage: '100 GB',
              color: _cyan,
              popular: true,
            ),
            _PlanCard(
              name: 'Enterprise',
              price: 'Custom',
              scans: 'Unlimited / custom',
              users: 'Custom',
              storage: 'Custom',
              color: _navy,
            ),
          ],
        ),
      ],
    );
  }
}

class _TopUpsPage extends StatelessWidget {
  const _TopUpsPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Scan Top-Ups',
      subtitle: 'Create additional scan packages for customers.',
      action: _PrimaryButton(
        label: 'Create Top-Up',
        icon: Icons.add_rounded,
        onPressed: () {},
      ),
      children: [
        _ResponsiveGrid(
          children: const [
            _TopUpCard(scans: '10,000', price: '₹499'),
            _TopUpCard(scans: '25,000', price: '₹999'),
            _TopUpCard(scans: '50,000', price: '₹1,799'),
            _TopUpCard(scans: '100,000', price: '₹2,999'),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Recent Top-Up Purchases',
          child: _DataTableCard(
            columns: const [
              'Company',
              'Package',
              'Scans',
              'Amount',
              'Date',
              'Status',
            ],
            rows: const [
              ['ABC Traders', '25K', '25,000', '₹999', '26 Sep', 'PAID'],
              ['Nova Retail', '10K', '10,000', '₹499', '25 Sep', 'PAID'],
              [
                'Prime Distribution',
                '100K',
                '100,000',
                '₹2,999',
                '24 Sep',
                'PAID',
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminEvidencePage extends StatelessWidget {
  const _AdminEvidencePage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Evidence',
      subtitle: 'Global evidence library across every company and warehouse.',
      children: [
        _ResponsiveGrid(
          children: const [
            _MetricCard(
              title: 'Total Evidence',
              value: '1.24M',
              change: 'All companies',
              icon: Icons.verified_outlined,
              color: _green,
            ),
            _MetricCard(
              title: 'Videos',
              value: '842K',
              change: '2.31 TB',
              icon: Icons.videocam_outlined,
              color: _blue,
            ),
            _MetricCard(
              title: 'Photos',
              value: '442K',
              change: '530 GB',
              icon: Icons.photo_outlined,
              color: _cyan,
            ),
            _MetricCard(
              title: 'Verified',
              value: '99.4%',
              change: 'Evidence status',
              icon: Icons.verified_rounded,
              color: _green,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _FilterBar(
          search: 'AWB, order, SKU, company or user...',
          filters: ['All', 'Video', 'Photo', 'Verified', 'Processing'],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Recent Evidence',
          child: _DataTableCard(
            columns: const [
              'AWB',
              'Company',
              'SKU',
              'Operator',
              'Type',
              'Status',
            ],
            rows: const [
              [
                'FMPP3767030215',
                'ABC Traders',
                'DG-LT-S',
                'Rahul',
                'Video',
                'VERIFIED',
              ],
              [
                '368275770371',
                'Nova Retail',
                '97-U1YR-N3GW',
                'Amit',
                'Video',
                'VERIFIED',
              ],
              [
                '1490841263428112',
                'Prime Distribution',
                'PC-TWISTER-001',
                'Vikas',
                'Video',
                'READY',
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StoragePage extends StatelessWidget {
  const _StoragePage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Storage',
      subtitle: 'Monitor B2 media usage and company-level storage consumption.',
      children: [
        _ResponsiveGrid(
          children: const [
            _MetricCard(
              title: 'Total Storage',
              value: '2.84 TB',
              change: 'of 5 TB capacity',
              icon: Icons.cloud_outlined,
              color: _blue,
            ),
            _MetricCard(
              title: 'Videos',
              value: '2.31 TB',
              change: '81.3%',
              icon: Icons.video_library_outlined,
              color: _cyan,
            ),
            _MetricCard(
              title: 'Photos',
              value: '530 GB',
              change: '18.7%',
              icon: Icons.photo_library_outlined,
              color: _green,
            ),
            _MetricCard(
              title: 'This Month',
              value: '+184 GB',
              change: '+6.9%',
              icon: Icons.trending_up_rounded,
              color: _amber,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Company Storage',
          child: _DataTableCard(
            columns: const ['Company', 'Videos', 'Photos', 'Total', 'Usage'],
            rows: const [
              ['Prime Distribution', '410 GB', '72 GB', '482 GB', '9.6%'],
              ['ABC Traders', '73 GB', '13 GB', '86 GB', '8.6%'],
              ['XYZ Enterprises', '46 GB', '12 GB', '58 GB', '58.2%'],
              ['Nova Retail', '9 GB', '3 GB', '12 GB', '51.2%'],
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminAnalyticsPage extends StatelessWidget {
  const _AdminAnalyticsPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Platform Analytics',
      subtitle: 'Usage, scans, storage and subscription performance.',
      children: [
        _ResponsiveGrid(
          children: const [
            _MetricCard(
              title: 'Daily Scans',
              value: '48,284',
              change: '+8.4%',
              icon: Icons.qr_code_scanner_rounded,
              color: _blue,
            ),
            _MetricCard(
              title: 'Success Rate',
              value: '99.4%',
              change: '+0.7%',
              icon: Icons.check_circle_outline,
              color: _green,
            ),
            _MetricCard(
              title: 'New Companies',
              value: '18',
              change: 'This month',
              icon: Icons.business_outlined,
              color: _cyan,
            ),
            _MetricCard(
              title: 'Revenue',
              value: '₹8.42L',
              change: '+12.7%',
              icon: Icons.currency_rupee_rounded,
              color: _green,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _ChartCard(title: 'Scan Volume', subtitle: 'Last 30 days'),
        const SizedBox(height: 18),
        _ResponsiveGrid(
          children: const [
            _ChartCard(
              title: 'Subscription Mix',
              subtitle: 'Starter / Business / Enterprise',
            ),
            _ChartCard(title: 'Storage Growth', subtitle: 'Media consumption'),
          ],
        ),
      ],
    );
  }
}

class _AuditLogsPage extends StatelessWidget {
  const _AuditLogsPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Audit Logs',
      subtitle: 'Security and administrative activity across the platform.',
      children: [
        const _FilterBar(
          search: 'Search activity...',
          filters: ['All Actions', 'Login', 'Subscription', 'User', 'Company'],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Recent Activity',
          child: Column(
            children: const [
              _AuditRow(
                actor: 'Sanjeet Dayma',
                action: 'Updated Business plan',
                target: 'Subscription Plans',
                time: '10 min ago',
              ),
              _AuditRow(
                actor: 'System',
                action: 'Subscription renewed',
                target: 'ABC Traders',
                time: '28 min ago',
              ),
              _AuditRow(
                actor: 'Admin',
                action: 'Invited user',
                target: 'rahul@example.com',
                time: '1 hr ago',
              ),
              _AuditRow(
                actor: 'System',
                action: 'Storage threshold warning',
                target: 'XYZ Enterprises',
                time: '2 hr ago',
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

class _TeamPage extends StatelessWidget {
  const _TeamPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Packing Team',
      subtitle: 'Manage operators and warehouse access.',
      action: _PrimaryButton(
        label: 'Invite Operator',
        icon: Icons.person_add_alt_1_outlined,
        onPressed: () {},
      ),
      children: [
        _SectionCard(
          title: '12 Team Members',
          child: _DataTableCard(
            columns: const ['Member', 'Role', 'Warehouse', 'Scans', 'Status'],
            rows: const [
              ['Sanjeet Dayma', 'Admin', 'All', '6,482', 'ACTIVE'],
              ['Rahul Kumar', 'Operator', 'Main Warehouse', '1,238', 'ACTIVE'],
              ['Amit Sharma', 'Operator', 'Main Warehouse', '842', 'ACTIVE'],
              ['Vikas Yadav', 'Operator', 'Second Warehouse', '614', 'ACTIVE'],
              ['Neeraj Singh', 'Operator', 'Main Warehouse', '428', 'INVITED'],
            ],
          ),
        ),
      ],
    );
  }
}

class _WarehousePage extends StatelessWidget {
  const _WarehousePage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Warehouses',
      subtitle: 'Manage packing locations and operator assignments.',
      action: _PrimaryButton(
        label: 'Add Warehouse',
        icon: Icons.add_business_outlined,
        onPressed: () {},
      ),
      children: [
        _ResponsiveGrid(
          children: const [
            _WarehouseCard(
              name: 'Main Warehouse',
              code: 'MAIN',
              operators: '8 operators',
              orders: '428 today',
              status: 'ACTIVE',
            ),
            _WarehouseCard(
              name: 'Second Warehouse',
              code: 'WH-02',
              operators: '4 operators',
              orders: '182 today',
              status: 'ACTIVE',
            ),
          ],
        ),
      ],
    );
  }
}

class _SellerOrdersPage extends StatelessWidget {
  const _SellerOrdersPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Orders',
      subtitle: 'Orders across your connected marketplaces.',
      children: [
        const _FilterBar(
          search: 'Search AWB, order or SKU...',
          filters: ['All', 'Ready', 'Packing', 'Packed', 'Exception'],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Today',
          child: _DataTableCard(
            columns: const ['Order', 'AWB', 'SKU', 'Marketplace', 'Status'],
            rows: const [
              [
                '406-3151945-3281902',
                '368275770371',
                '97-U1YR-N3GW',
                'Amazon',
                'PACKING',
              ],
              [
                '331724360573683072_1',
                'FMPP3767030215',
                'DG-LT-S',
                'Flipkart',
                'PACKED',
              ],
              [
                '331724360573683072_2',
                '1490841263428112',
                'PC-TWISTER-001',
                'Other',
                'READY',
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SellerEvidencePage extends StatelessWidget {
  const _SellerEvidencePage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Evidence',
      subtitle: 'Packing proof generated by your team.',
      children: [
        _ResponsiveGrid(
          children: const [
            _MetricCard(
              title: 'Evidence',
              value: '6,492',
              change: 'This month',
              icon: Icons.verified_outlined,
              color: _green,
            ),
            _MetricCard(
              title: 'Videos',
              value: '5,982',
              change: '28.4 GB',
              icon: Icons.videocam_outlined,
              color: _blue,
            ),
            _MetricCard(
              title: 'Photos',
              value: '510',
              change: '7.6 GB',
              icon: Icons.photo_outlined,
              color: _cyan,
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: 'Latest Evidence',
          child: _DataTableCard(
            columns: const ['AWB', 'Order', 'Operator', 'Created', 'Status'],
            rows: const [
              [
                '368275770371',
                '406-3151945-3281902',
                'Rahul',
                '12:48',
                'VERIFIED',
              ],
              [
                'FMPP3767030215',
                '331724360573683072_1',
                'Amit',
                '12:42',
                'VERIFIED',
              ],
              [
                '1490841263428112',
                '331724360573683072_2',
                'Vikas',
                '12:37',
                'READY',
              ],
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Company Setup',
      subtitle: 'Complete the steps required to start packing.',
      children: const [
        _OnboardingStep(
          number: '01',
          title: 'Company Profile',
          subtitle: 'Business details and GST information',
          complete: true,
        ),
        _OnboardingStep(
          number: '02',
          title: 'Subscription',
          subtitle: 'Business plan selected and active',
          complete: true,
        ),
        _OnboardingStep(
          number: '03',
          title: 'Warehouse',
          subtitle: 'Main Warehouse configured',
          complete: true,
        ),
        _OnboardingStep(
          number: '04',
          title: 'Packing Team',
          subtitle: 'Invite operators and assign warehouses',
          complete: false,
        ),
        _OnboardingStep(
          number: '05',
          title: 'Marketplace',
          subtitle: 'Connect Amazon, Flipkart or API',
          complete: false,
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

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      title: 'Profile',
      subtitle: 'Your Loss Defender account and work profile.',
      action: _PrimaryButton(
        label: 'Edit Profile',
        icon: Icons.edit_outlined,
        onPressed: () {},
      ),
      children: [
        _SectionCard(
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: _navy,
                child: const Text(
                  'S',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sanjeet Dayma',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Administrator • Loss Defender',
                      style: TextStyle(color: _muted),
                    ),
                  ],
                ),
              ),
              _StatusBadge(text: 'ACTIVE', color: _green),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ResponsiveGrid(
          children: const [
            _InfoCard(
              title: 'Personal Information',
              items: [
                'Name: Sanjeet Dayma',
                'Email: Account email',
                'Role: Administrator',
              ],
            ),
            _InfoCard(
              title: 'Work Information',
              items: [
                'Company: Loss Defender',
                'Warehouse: Main Warehouse',
                'Access: Full operational access',
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Security',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.lock_outline, color: _blue),
            title: const Text('Password & authentication'),
            subtitle: const Text('Manage sign-in methods and active sessions.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _PlatformSettingsPage extends StatelessWidget {
  const _PlatformSettingsPage();

  @override
  Widget build(BuildContext context) {
    return const _SettingsPage(
      title: 'Platform Settings',
      subtitle: 'Global platform configuration.',
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

class _FilterBar extends StatelessWidget {
  final String search;
  final List<String> filters;

  const _FilterBar({required this.search, required this.filters});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 300,
          height: 42,
          child: TextField(
            decoration: InputDecoration(
              hintText: search,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
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
        ...filters.map(
          (filter) => OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
            label: Text(filter),
          ),
        ),
      ],
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

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String scans;
  final String users;
  final String storage;
  final Color color;
  final bool popular;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.scans,
    required this.users,
    required this.storage,
    required this.color,
    this.popular = false,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (popular) const _StatusBadge(text: 'POPULAR', color: _blue),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            price,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          _Bullet(text: scans),
          _Bullet(text: users),
          _Bullet(text: storage),
          const SizedBox(height: 18),
          OutlinedButton(onPressed: () {}, child: const Text('Edit Plan')),
        ],
      ),
    );
  }
}

class _TopUpCard extends StatelessWidget {
  final String scans;
  final String price;

  const _TopUpCard({required this.scans, required this.price});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.add_card_outlined, color: _blue),
          const SizedBox(height: 14),
          Text(
            '$scans scans',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              color: _blue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 15),
          OutlinedButton(onPressed: () {}, child: const Text('Edit')),
        ],
      ),
    );
  }
}

class _WarehouseCard extends StatelessWidget {
  final String name;
  final String code;
  final String operators;
  final String orders;
  final String status;

  const _WarehouseCard({
    required this.name,
    required this.code,
    required this.operators,
    required this.orders,
    required this.status,
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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _blue.withAlpha(18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.warehouse_outlined, color: _blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              _StatusBadge(text: status, color: _green),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Code: $code',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            '$operators • $orders',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
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

class _OnboardingStep extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final bool complete;

  const _OnboardingStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _SectionCard(
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: complete ? _green.withAlpha(18) : _blue.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: complete
                  ? const Icon(Icons.check_rounded, color: _green)
                  : Text(
                      number,
                      style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              child: Text(complete ? 'Review' : 'Continue'),
            ),
          ],
        ),
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

class _AuditRow extends StatelessWidget {
  final String actor;
  final String action;
  final String target;
  final String time;

  const _AuditRow({
    required this.actor,
    required this.action,
    required this.target,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFEFF6FF),
        child: Icon(Icons.security_outlined, color: _blue, size: 19),
      ),
      title: Text(
        '$actor • $action',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      ),
      subtitle: Text(
        target,
        style: const TextStyle(color: _muted, fontSize: 11),
      ),
      trailing: Text(time, style: const TextStyle(color: _muted, fontSize: 10)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
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

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 17, color: _green),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
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



