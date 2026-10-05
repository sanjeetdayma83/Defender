import 'package:flutter/material.dart';

class SidebarItem {
  final IconData icon;
  final String title;

  const SidebarItem({required this.icon, required this.title});
}

class LossDefenderSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const LossDefenderSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const items = <SidebarItem>[
    SidebarItem(icon: Icons.dashboard_outlined, title: 'Dashboard'),
    SidebarItem(icon: Icons.qr_code_scanner_outlined, title: 'Scan & Pack'),
    SidebarItem(icon: Icons.video_library_outlined, title: 'Recordings'),
    SidebarItem(icon: Icons.local_shipping_outlined, title: 'Orders'),
    SidebarItem(icon: Icons.inventory_2_outlined, title: 'Products'),
    SidebarItem(icon: Icons.fact_check_outlined, title: 'Evidence'),
    SidebarItem(icon: Icons.analytics_outlined, title: 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 238,
      color: const Color(0xFF0B1F33),
      child: Column(
        children: [
          const SizedBox(height: 22),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  'LOSS DEFENDER',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = index == selectedIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF155EEF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: Colors.white.withValues(alpha: 0.92),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            item.title,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onSelected(items.length),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings_outlined,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
