import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/platform/platform_plans_service.dart';

class PlatformPlansScreen extends StatefulWidget {
  const PlatformPlansScreen({super.key});

  @override
  State<PlatformPlansScreen> createState() => _PlatformPlansScreenState();
}

class _PlatformPlansScreenState extends State<PlatformPlansScreen> {
  final _svc = const PlatformPlansService();
  Future<List<PlatformPlan>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _svc.list();
    });
  }

  Future<void> _openCreate() async {
    final name = TextEditingController();
    final code = TextEditingController();
    final price = TextEditingController(text: '999');
    final scans = TextEditingController(text: '1000');
    final wh = TextEditingController(text: '2');
    final ops = TextEditingController(text: '5');
    var period = 'monthly';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Create plan'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
                  TextField(controller: code, decoration: const InputDecoration(labelText: 'Code')),
                  TextField(
                    controller: price,
                    decoration: const InputDecoration(labelText: 'Price (₹) *'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: period,
                    decoration: const InputDecoration(labelText: 'Period'),
                    items: const [
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                    ],
                    onChanged: (v) => setLocal(() => period = v ?? 'monthly'),
                  ),
                  TextField(controller: scans, decoration: const InputDecoration(labelText: 'Included scans')),
                  TextField(controller: wh, decoration: const InputDecoration(labelText: 'Max warehouses')),
                  TextField(controller: ops, decoration: const InputDecoration(labelText: 'Max operators')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name required')));
      return;
    }
    final rupees = int.tryParse(price.text) ?? 0;
    try {
      await _svc.create(
        name: name.text.trim(),
        code: code.text.trim().isEmpty ? null : code.text.trim(),
        pricePaise: rupees * 100,
        period: period,
        includedScans: int.tryParse(scans.text),
        maxWarehouses: int.tryParse(wh.text),
        maxOperators: int.tryParse(ops.text),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan created')));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text('Plans', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ),
              OutlinedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh, size: 18), label: const Text('Refresh')),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: _openCreate, icon: const Icon(Icons.add, size: 18), label: const Text('Create plan')),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<PlatformPlan>>(
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
                      Padding(padding: const EdgeInsets.all(16), child: Text('${snap.error}', textAlign: TextAlign.center)),
                      FilledButton(onPressed: _reload, child: const Text('Retry')),
                    ],
                  ),
                );
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const Center(child: Text('No plans yet. Create the first plan.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = items[i];
                  return Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        [
                          if (p.code != null) p.code!,
                          p.priceLabel,
                          if (p.includedScans != null) '${p.includedScans} scans',
                          if (p.maxWarehouses != null) '${p.maxWarehouses} WH',
                          p.isActive ? 'Active' : 'Off',
                        ].join(' · '),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}



