import 'package:flutter/material.dart';
import '../screen_ui.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String query = '';
  String filter = 'All';

  final orders = const [
    [
      '406-3151945-3281902',
      '368275770371',
      '97-U1YR-N3GW',
      'Amazon',
      'Ready to Pack',
    ],
    [
      '331724360573683072_1',
      '1490841263428112',
      'PC-TWISTER-001',
      'Delhivery',
      'Packing',
    ],
    ['FK-3767030215', 'FMPP3767030215', 'DG-LT-S', 'Flipkart', 'Packed'],
    ['ORD-10042', 'AWB-10042', 'SKU-10042', 'Amazon', 'Pending'],
    ['ORD-10043', 'AWB-10043', 'SKU-10043', 'Flipkart', 'Packed'],
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = orders.where((o) {
      final matchesQuery =
          query.isEmpty ||
          o.any((v) => v.toLowerCase().contains(query.toLowerCase()));
      final matchesFilter = filter == 'All' || o[4] == filter;
      return matchesQuery && matchesFilter;
    }).toList();

    return LDPage(
      title: 'Orders',
      subtitle: 'Track orders, shipments, AWBs and packing status.',
      action: ldButton('Refresh', Icons.refresh_rounded),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 360,
                child: LDSearch(
                  hint: 'Search order, AWB or SKU...',
                  onChanged: (v) => setState(() => query = v),
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: filter,
                  items:
                      ['All', 'Pending', 'Ready to Pack', 'Packing', 'Packed']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => filter = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: LDStat(
                  label: 'Total Orders',
                  value: '${orders.length}',
                  icon: Icons.inventory_2_outlined,
                  color: ldBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LDStat(
                  label: 'Packing',
                  value: '1',
                  icon: Icons.inventory_outlined,
                  color: ldAmber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LDStat(
                  label: 'Packed',
                  value: '2',
                  icon: Icons.verified_outlined,
                  color: ldGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (filtered.isEmpty)
            const LDEmpty(
              icon: Icons.search_off_rounded,
              title: 'No orders found',
              subtitle: 'Try changing your search or filters.',
            )
          else
            LDCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: LDSectionTitle(
                        title: 'Order Queue',
                        subtitle: 'Latest operational shipment records',
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ...filtered.map((o) => _orderRow(context, o)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _orderRow(BuildContext context, List<String> o) {
    final color = o[4] == 'Packed'
        ? ldGreen
        : o[4] == 'Packing'
        ? ldAmber
        : ldBlue;

    return InkWell(
      onTap: () => _showOrder(context, o),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: ldBorder)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ldBlue.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_outlined, color: ldBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o[0],
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ldNavy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'AWB ${o[1]} • ${o[2]}',
                    style: const TextStyle(fontSize: 12, color: ldMute),
                  ),
                ],
              ),
            ),
            if (MediaQuery.sizeOf(context).width > 700)
              Text(
                o[3],
                style: const TextStyle(
                  color: ldMute,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 18),
            LDStatus(text: o[4], color: color),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: ldMute),
          ],
        ),
      ),
    );
  }

  void _showOrder(BuildContext context, List<String> o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Wrap(
          children: [
            const Text(
              'Order Details',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: ldNavy,
              ),
            ),
            const SizedBox(height: 20),
            _detail('Order ID', o[0]),
            _detail('AWB', o[1]),
            _detail('SKU', o[2]),
            _detail('Channel', o[3]),
            _detail('Status', o[4]),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: ldMute)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: ldNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
