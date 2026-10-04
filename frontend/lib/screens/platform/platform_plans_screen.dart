import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/platform/platform_plans_service.dart';

class PlatformPlansScreen extends StatefulWidget {
  const PlatformPlansScreen({super.key});

  @override
  State<PlatformPlansScreen> createState() => _PlatformPlansScreenState();
}

class _PlatformPlansScreenState extends State<PlatformPlansScreen> {
  final _service = const PlatformPlansService();
  Future<({int total, List<PlatformPlan> items})>? _future;
  bool _activeOnly = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _service.list(activeOnly: _activeOnly);
    });
  }

  Future<void> _toggle(PlatformPlan p) async {
    try {
      await _service.setActive(p.id, !p.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              p.isActive ? '${p.name} deactivated' : '${p.name} activated',
            ),
          ),
        );
        _reload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '999');
    final scansCtrl = TextEditingController(text: '1000');
    final whCtrl = TextEditingController(text: '1');
    final opsCtrl = TextEditingController(text: '3');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New plan'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Code (e.g. starter)',
                  ),
                ),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Price (INR, whole rupees)',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                TextField(
                  controller: scansCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Included scans / period',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                TextField(
                  controller: whCtrl,
                  decoration: const InputDecoration(labelText: 'Max warehouses'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                TextField(
                  controller: opsCtrl,
                  decoration: const InputDecoration(labelText: 'Max operators'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    try {
      final rupees = int.tryParse(priceCtrl.text) ?? 0;
      await _service.create({
        'code': codeCtrl.text.trim(),
        'name': nameCtrl.text.trim(),
        'pricePaise': rupees * 100,
        'includedScans': int.tryParse(scansCtrl.text) ?? 0,
        'maxWarehouses': int.tryParse(whCtrl.text) ?? 1,
        'maxOperators': int.tryParse(opsCtrl.text) ?? 1,
        'currency': 'INR',
        'billingInterval': 'MONTHLY',
        'isCommercial': true,
        'isActive': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan created')),
        );
        _reload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plans',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Packages, prices, scan & warehouse limits (live).',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              FilterChip(
                label: const Text('Active only'),
                selected: _activeOnly,
                onSelected: (v) {
                  _activeOnly = v;
                  _reload();
                },
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New plan'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${snap.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _reload,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final items = snap.data?.items ?? [];
                final total = snap.data?.total ?? 0;
                if (items.isEmpty) {
                  return const Center(child: Text('No plans yet. Create one.'));
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total plans',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Code')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Scans')),
                            DataColumn(label: Text('Warehouses')),
                            DataColumn(label: Text('Operators')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Action')),
                          ],
                          rows: items.map((p) {
                            return DataRow(
                              cells: [
                                DataCell(Text(p.code)),
                                DataCell(Text(p.name)),
                                DataCell(
                                  Text(
                                    '₹${p.priceInr.toStringAsFixed(0)}',
                                  ),
                                ),
                                DataCell(Text('${p.includedScans}')),
                                DataCell(Text('${p.maxWarehouses}')),
                                DataCell(Text('${p.maxOperators}')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: p.isActive
                                          ? Colors.green.shade50
                                          : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      p.isActive ? 'ACTIVE' : 'INACTIVE',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: p.isActive
                                            ? Colors.green.shade800
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  TextButton(
                                    onPressed: () => _toggle(p),
                                    child: Text(
                                      p.isActive ? 'Deactivate' : 'Activate',
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
