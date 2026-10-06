import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../analytics/analytics_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../evidence/evidence_screen.dart';
import '../help/help_screen.dart';
import '../notifications/notifications_screen.dart';
import '../orders/orders_screen.dart';
import '../products/products_screen.dart';
import '../profile/profile_screen.dart';
import '../recordings/recordings_screen.dart';
import '../scan_pack/scan_pack_screen.dart';
import '../settings/settings_screen.dart';
import '../team/team_screen.dart';
import '../warehouse/warehouse_screen.dart';

enum SaaSRole { platformAdmin, companyAdmin, manager, operator, viewer }

class SaaSPortalScreen extends StatefulWidget {
  final SaaSRole initialRole;

  const SaaSPortalScreen({super.key, this.initialRole = SaaSRole.companyAdmin});

  @override
  State<SaaSPortalScreen> createState() => _SaaSPortalScreenState();
}

class _NavItem {
  final IconData icon;
  final String label;
  final String id;
  const _NavItem(this.icon, this.label, this.id);
}

class _SaaSPortalScreenState extends State<SaaSPortalScreen> {
  static const navy = Color(0xFF021F4F);
  static const blue = Color(0xFF0061FC);
  static const bg = Color(0xFFF4F8FD);
  static const border = Color(0xFFDCE6F3);
  static const muted = Color(0xFF5B6B85);

  late SaaSRole _role;
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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
        return 'Owner / Admin';
      case SaaSRole.manager:
        return 'Manager';
      case SaaSRole.operator:
        return 'Operator';
      case SaaSRole.viewer:
        return 'Viewer';
    }
  }

  List<_NavItem> get _nav {
    switch (_role) {
      case SaaSRole.operator:
        return const [
          _NavItem(Icons.qr_code_scanner_rounded, 'Scan & Pack', 'C2'),
          _NavItem(Icons.video_library_outlined, 'My Recordings', 'C10a'),
          _NavItem(Icons.notifications_none_rounded, 'Notifications', 'C35'),
          _NavItem(Icons.person_outline_rounded, 'Profile', 'C36'),
          _NavItem(Icons.help_outline_rounded, 'Help', 'C37'),
        ];
      case SaaSRole.viewer:
        return const [
          _NavItem(Icons.dashboard_outlined, 'Dashboard', 'C1'),
          _NavItem(Icons.receipt_long_outlined, 'Orders', 'C4'),
          _NavItem(Icons.fact_check_outlined, 'Evidence', 'C10'),
          _NavItem(Icons.analytics_outlined, 'Analytics', 'C22'),
          _NavItem(Icons.notifications_none_rounded, 'Notifications', 'C35'),
          _NavItem(Icons.person_outline_rounded, 'Profile', 'C36'),
          _NavItem(Icons.help_outline_rounded, 'Help', 'C37'),
        ];
      case SaaSRole.manager:
        return const [
          _NavItem(Icons.dashboard_outlined, 'Dashboard', 'C1'),
          _NavItem(Icons.qr_code_scanner_rounded, 'Scan & Pack', 'C2'),
          _NavItem(Icons.receipt_long_outlined, 'Orders', 'C4'),
          _NavItem(Icons.inventory_2_outlined, 'Products', 'C8'),
          _NavItem(Icons.video_library_outlined, 'Recordings', 'C10'),
          _NavItem(Icons.fact_check_outlined, 'Evidence', 'C11'),
          _NavItem(Icons.people_outline_rounded, 'Team', 'C17'),
          _NavItem(Icons.analytics_outlined, 'Analytics', 'C22'),
          _NavItem(Icons.description_outlined, 'Reports', 'C23'),
          _NavItem(Icons.notifications_none_rounded, 'Notifications', 'C35'),
          _NavItem(Icons.person_outline_rounded, 'Profile', 'C36'),
          _NavItem(Icons.help_outline_rounded, 'Help', 'C37'),
        ];
      case SaaSRole.companyAdmin:
        return const [
          _NavItem(Icons.dashboard_outlined, 'Dashboard', 'C1'),
          _NavItem(Icons.qr_code_scanner_rounded, 'Scan & Pack', 'C2'),
          _NavItem(Icons.receipt_long_outlined, 'Orders', 'C4'),
          _NavItem(Icons.inventory_2_outlined, 'Products', 'C8'),
          _NavItem(Icons.video_library_outlined, 'Recordings', 'C10'),
          _NavItem(Icons.fact_check_outlined, 'Evidence', 'C11'),
          _NavItem(Icons.warehouse_outlined, 'Warehouses', 'C14'),
          _NavItem(Icons.people_outline_rounded, 'Team', 'C17'),
          _NavItem(Icons.analytics_outlined, 'Analytics', 'C22'),
          _NavItem(Icons.description_outlined, 'Reports', 'C23'),
          _NavItem(
            Icons.account_balance_wallet_outlined,
            'Plan & Usage',
            'C24',
          ),
          _NavItem(Icons.receipt_long_outlined, 'Billing', 'C30'),
          _NavItem(Icons.settings_outlined, 'Settings', 'C33'),
          _NavItem(Icons.history_rounded, 'Audit', 'C34'),
          _NavItem(Icons.notifications_none_rounded, 'Notifications', 'C35'),
          _NavItem(Icons.person_outline_rounded, 'Profile', 'C36'),
          _NavItem(Icons.help_outline_rounded, 'Help', 'C37'),
        ];
      case SaaSRole.platformAdmin:
        return const [
          _NavItem(Icons.dashboard_outlined, 'Platform Dashboard', 'P1'),
          _NavItem(Icons.business_outlined, 'Companies', 'P2'),
          _NavItem(Icons.people_outline_rounded, 'Platform Users', 'P5'),
          _NavItem(Icons.credit_card_outlined, 'Subscriptions', 'P10'),
          _NavItem(Icons.layers_outlined, 'Plans', 'P6'),
          _NavItem(Icons.payments_outlined, 'Payments', 'P15'),
          _NavItem(Icons.cloud_outlined, 'Storage', 'P16'),
          _NavItem(Icons.analytics_outlined, 'Analytics', 'P17'),
          _NavItem(Icons.history_rounded, 'Audit Logs', 'P18'),
          _NavItem(Icons.settings_outlined, 'Settings', 'P19'),
          _NavItem(Icons.person_outline_rounded, 'Profile', 'C36'),
          _NavItem(Icons.help_outline_rounded, 'Help', 'C37'),
        ];
    }
  }

  Widget _page() {
    final id = _nav[_index].id;
    switch (id) {
      case 'C1':
        return DashboardScreen(onScanPack: () => _go('C2'));
      case 'C2':
        return const ScanPackScreen();
      case 'C4':
        return const OrdersScreen();
      case 'C8':
        return const ProductsScreen();
      case 'C10':
      case 'C10a':
        return const RecordingsScreen();
      case 'C11':
        return const EvidenceScreen();
      case 'C14':
        return const WarehouseScreen();
      case 'C17':
        return const TeamScreen();
      case 'C22':
        return const AnalyticsScreen();
      case 'C35':
        return const NotificationsScreen();
      case 'C36':
        return const ProfileScreen();
      case 'C33':
        return const SettingsScreen();
      case 'C37':
        return const HelpScreen();
      default:
        return _ModulePlaceholder(
          screenId: id,
          title: _nav[_index].label,
          role: _roleLabel,
        );
    }
  }

  void _go(String id) {
    final i = _nav.indexWhere((item) => item.id == id);
    if (i >= 0) setState(() => _index = i);
  }

  void _select(int index) {
    setState(() => _index = index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  Future<void> _logout() async {
    await context.read<SessionProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      drawer: _drawer(),
      body: LayoutBuilder(
        builder: (context, c) {
          final desktop = c.maxWidth >= 1100;
          if (!desktop) {
            return Column(
              children: [
                _mobileTopbar(),
                Expanded(child: _page()),
                if (_role == SaaSRole.operator && c.maxWidth < 768)
                  _operatorBottomNav(),
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
                    Expanded(child: _page()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sidebar() => Container(
    width: 276,
    color: navy,
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 18, 18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [blue, Color(0xFF22D3EE)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'LOSS DEFENDER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_left_rounded, color: Colors.white70),
              ],
            ),
          ),
          _workspaceSwitcher(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _nav.length,
              itemBuilder: (context, i) {
                final n = _nav[i];
                final selected = i == _index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    selected: selected,
                    selectedTileColor: blue,
                    leading: Icon(
                      n.icon,
                      color: selected ? Colors.white : Colors.white70,
                      size: 20,
                    ),
                    title: Text(
                      n.label,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: .80),
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    onTap: () => _select(i),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Plan & Usage',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Usage is loaded from your account. No demo counters are shown.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .65),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _go('C24'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: .35),
                    ),
                  ),
                  child: const Text('View usage'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _workspaceSwitcher() {
    final user = context.watch<SessionProvider>().user;
    final company = user?.company?.name.trim().isNotEmpty == true
        ? user!.company!.name
        : 'Company workspace';
    final warehouse = user?.primaryWarehouse?.name.trim().isNotEmpty == true
        ? user!.primaryWarehouse!.name
        : 'All assigned warehouses';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          _switchTile(Icons.business_outlined, company),
          const SizedBox(height: 6),
          _switchTile(Icons.location_on_outlined, warehouse),
        ],
      ),
    );
  }

  Widget _switchTile(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.white54,
          size: 17,
        ),
      ],
    ),
  );

  Widget _topbar() {
    final user = context.watch<SessionProvider>().user;
    final name = user?.name.trim().isNotEmpty == true ? user!.name : 'User';

    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _nav[_index].label,
              style: const TextStyle(
                color: navy,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            width: 230,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: const Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: navy),
                SizedBox(width: 8),
                Text(
                  'Today',
                  style: TextStyle(color: navy, fontWeight: FontWeight.w600),
                ),
                Spacer(),
                Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => _go('C35'),
                icon: const Icon(Icons.notifications_none_rounded, color: navy),
              ),
              Positioned(
                right: 4,
                top: 3,
                child: Container(
                  width: 17,
                  height: 17,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                _go('C36');
              } else if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('Profile')),
              PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: blue,
                  child: Text(
                    initials.isEmpty ? 'U' : initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),
                    Text(
                      _roleLabel,
                      style: const TextStyle(fontSize: 10, color: muted),
                    ),
                  ],
                ),
                const SizedBox(width: 7),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: navy,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileTopbar() {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: border)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: blue,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.shield_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                _nav[_index].label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: navy,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.circle, color: Color(0xFF16A34A), size: 9),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  Widget _operatorBottomNav() {
    final items = _nav.take(3).toList();

    return SafeArea(
      top: false,
      child: Container(
        height: 66,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: border)),
        ),
        child: Row(
          children: items.asMap().entries.map((entry) {
            final selected = entry.key == _index;

            return Expanded(
              child: InkWell(
                onTap: () => _select(entry.key),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      entry.value.icon,
                      color: selected ? blue : muted,
                      size: 22,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      entry.value.label.replaceAll('My ', ''),
                      style: TextStyle(
                        fontSize: 10,
                        color: selected ? blue : muted,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _drawer() {
    return Drawer(
      backgroundColor: navy,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),
            const ListTile(
              leading: Icon(Icons.shield_rounded, color: blue),
              title: Text(
                'LOSS DEFENDER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _nav.length,
                itemBuilder: (context, index) {
                  final item = _nav[index];

                  return ListTile(
                    selected: index == _index,
                    selectedTileColor: blue,
                    leading: Icon(item.icon, color: Colors.white70),
                    title: Text(
                      item.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () => _select(index),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.white70),
              title: const Text(
                'Sign out',
                style: TextStyle(color: Colors.white),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModulePlaceholder extends StatelessWidget {
  final String screenId;
  final String title;
  final String role;
  const _ModulePlaceholder({
    required this.screenId,
    required this.title,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F8FD),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                          color: Color(0xFF071A46),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$screenId · $role',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: const Text('Filters'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCE6F3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.layers_outlined,
                      color: Color(0xFF0061FC),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$title UI is ready',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF071A46),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'This module is intentionally empty until its API contract is available. No demo rows or fabricated business values are rendered.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
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
