import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';

import '../../models/models.dart';
import '../../services/orders/order_service.dart';
import '../imports/order_import_screen.dart';
import '../screen_ui.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _service = OrderService();
  final TextEditingController _searchController = TextEditingController();

  List<Order> _orders = <Order>[];
  bool _loading = true;
  String? _error;
  String _status = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await _service.getOrders(
        search: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        status: _status == 'All' ? null : _status,
      );

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final packing = _orders
        .where((o) => o.status.toUpperCase() == 'PACKING')
        .length;
    final packed = _orders
        .where((o) => o.status.toUpperCase() == 'PACKED')
        .length;

    final session = context.watch<SessionProvider>();
    final role = (session.user?.role ?? '').toUpperCase().replaceAll('-', '_');
    final canImport = role == 'OWNER' ||
        role == 'ADMIN' ||
        role == 'MANAGER' ||
        role == 'COMPANY_ADMIN' ||
        role == 'PLATFORM_ADMIN';

    return LDPage(
      title: 'Orders',
      subtitle: 'Live orders from the Loss Defender database.',
      action: Wrap(
        spacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
          FilledButton.icon(
            onPressed: !canImport
                ? null
                : () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrderImportScreen()),
              );
              await _load();
            },
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Import Orders'),
          ),
        ],
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 380,
                child: LDSearch(
                  hint: 'Search order, AWB, SKU or customer...',
                  controller: _searchController,
                  onChanged: (_) => _load(),
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _status,
                  items:
                      const [
                            'All',
                            'PENDING',
                            'CONFIRMED',
                            'PACKING',
                            'PACKED',
                            'SHIPPED',
                            'DELIVERED',
                            'CANCELLED',
                            'RETURNED',
                          ]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                    _load();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: LDStat(
                  label: 'Total Orders',
                  value: '${_orders.length}',
                  icon: Icons.inventory_2_outlined,
                  color: ldBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LDStat(
                  label: 'Packing',
                  value: '$packing',
                  icon: Icons.inventory_outlined,
                  color: ldAmber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LDStat(
                  label: 'Packed',
                  value: '$packed',
                  icon: Icons.verified_outlined,
                  color: ldGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(50),
              child: CircularProgressIndicator(),
            )
          else if (_error != null)
            LDCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 42,
                  ),
                  const SizedBox(height: 10),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          else if (_orders.isEmpty)
            const LDEmpty(
              icon: Icons.inventory_2_outlined,
              title: 'No orders found',
              subtitle: 'Import orders or change your search/filter.',
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
                        subtitle: 'Live database records',
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ..._orders.map(_row),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(Order order) {
    final status = order.status.toUpperCase();
    final color = status == 'PACKED'
        ? ldGreen
        : status == 'PACKING'
        ? ldAmber
        : ldBlue;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
      title: Text(
        order.orderId,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        'AWB ${order.awb} • ${order.product.sku} • ${order.marketplace}',
      ),
      trailing: LDStatus(text: order.status, color: color),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

