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

  Future<List<PlatformPlan>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = _service.list();
    });
  }

  Future<void> _openEditor({PlatformPlan? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final code = TextEditingController(text: existing?.code ?? '');
    final price = TextEditingController(
      text: existing == null
          ? '999'
          : (existing.pricePaise / 100).toStringAsFixed(0),
    );
    final scans = TextEditingController(
      text: '${existing?.includedScans ?? 1000}',
    );
    final warehouses = TextEditingController(
      text: '${existing?.maxWarehouses ?? 2}',
    );
    final operators = TextEditingController(
      text: '${existing?.maxOperators ?? 5}',
    );

    var period = existing?.period ?? 'monthly';
    var active = existing?.isActive ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) {
          return AlertDialog(
            title: Text(existing == null ? 'Create plan' : 'Edit plan'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Plan name *',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: code,
                      decoration: const InputDecoration(labelText: 'Plan code'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Price (₹) *',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: period,
                      decoration: const InputDecoration(
                        labelText: 'Billing interval',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'monthly',
                          child: Text('Monthly'),
                        ),
                        DropdownMenuItem(
                          value: 'yearly',
                          child: Text('Yearly'),
                        ),
                      ],
                      onChanged: (value) {
                        setLocal(() {
                          period = value ?? 'monthly';
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: scans,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Included scans',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: warehouses,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max warehouses',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: operators,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max operators',
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (existing != null)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active'),
                        value: active,
                        onChanged: (value) {
                          setLocal(() {
                            active = value;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(existing == null ? 'Create' : 'Save changes'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true || !mounted) {
      name.dispose();
      code.dispose();
      price.dispose();
      scans.dispose();
      warehouses.dispose();
      operators.dispose();
      return;
    }

    final planName = name.text.trim();

    if (planName.isEmpty) {
      _showMessage('Plan name is required.');
      return;
    }

    final rupees = int.tryParse(price.text.trim());

    if (rupees == null || rupees < 0) {
      _showMessage('Enter a valid price.');
      return;
    }

    try {
      if (existing == null) {
        await _service.create(
          name: planName,
          code: code.text.trim().isEmpty ? null : code.text.trim(),
          pricePaise: rupees * 100,
          period: period,
          includedScans: int.tryParse(scans.text.trim()),
          maxWarehouses: int.tryParse(warehouses.text.trim()),
          maxOperators: int.tryParse(operators.text.trim()),
        );
        _showMessage('Plan created successfully.');
      } else {
        await _service.update(
          existing.id,
          name: planName,
          code: code.text.trim().isEmpty ? null : code.text.trim(),
          pricePaise: rupees * 100,
          period: period,
          includedScans: int.tryParse(scans.text.trim()),
          maxWarehouses: int.tryParse(warehouses.text.trim()),
          maxOperators: int.tryParse(operators.text.trim()),
          isActive: active,
        );
        _showMessage('Plan updated successfully.');
      }

      _reload();
    } catch (error) {
      _showMessage('$error');
    } finally {
      name.dispose();
      code.dispose();
      price.dispose();
      scans.dispose();
      warehouses.dispose();
      operators.dispose();
    }
  }

  Future<void> _deletePlan(PlatformPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete plan?'),
          content: Text(
            'This will permanently delete "${plan.name}". '
            'Plans linked to active subscriptions may be rejected by the database.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _service.delete(plan.id);
      _showMessage('Plan deleted.');
      _reload();
    } catch (error) {
      _showMessage('$error');
    }
  }

  Future<void> _togglePlan(PlatformPlan plan) async {
    try {
      await _service.setActive(plan.id, !plan.isActive);
      _showMessage(plan.isActive ? 'Plan deactivated.' : 'Plan activated.');
      _reload();
    } catch (error) {
      _showMessage('$error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                child: Text(
                  'Plans',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create plan'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<PlatformPlan>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      FilledButton(
                        onPressed: _reload,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final plans = snapshot.data ?? const <PlatformPlan>[];

              if (plans.isEmpty) {
                return const Center(child: Text('No plans in database yet.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: plans.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final plan = plans[index];

                  return Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      title: Text(
                        plan.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (plan.code != null && plan.code!.isNotEmpty)
                              Text(plan.code!),
                            Text(plan.priceLabel),
                            if (plan.includedScans != null)
                              Text('${plan.includedScans} scans'),
                            if (plan.maxWarehouses != null)
                              Text('${plan.maxWarehouses} WH'),
                            if (plan.maxOperators != null)
                              Text('${plan.maxOperators} operators'),
                            Text(plan.isActive ? 'Active' : 'Inactive'),
                          ],
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Plan actions',
                        onSelected: (action) {
                          switch (action) {
                            case 'edit':
                              _openEditor(existing: plan);
                              break;
                            case 'toggle':
                              _togglePlan(plan);
                              break;
                            case 'delete':
                              _deletePlan(plan);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit / Modify'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'toggle',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.power_settings_new_outlined),
                              title: Text(
                                plan.isActive ? 'Deactivate' : 'Activate',
                              ),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.delete_outline,
                                color: Color(0xFFDC2626),
                              ),
                              title: Text('Delete'),
                            ),
                          ),
                        ],
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
