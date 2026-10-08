import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/platform/platform_topups_service.dart';

class PlatformTopUpsScreen extends StatefulWidget {
  const PlatformTopUpsScreen({super.key});

  @override
  State<PlatformTopUpsScreen> createState() => _PlatformTopUpsScreenState();
}

class _PlatformTopUpsScreenState extends State<PlatformTopUpsScreen> {
  final _service = const PlatformTopupsService();

  Future<List<PlatformTopUp>>? _future;

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

  Future<void> _openEditor({PlatformTopUp? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final code = TextEditingController(text: existing?.code ?? '');
    final credits = TextEditingController(text: '${existing?.credits ?? 1000}');
    final price = TextEditingController(
      text: existing == null
          ? '499'
          : (existing.pricePaise / 100).toStringAsFixed(0),
    );

    var active = existing?.isActive ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: Text(
            existing == null ? 'Create scan top-up' : 'Edit scan top-up',
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Pack name *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: code,
                  decoration: const InputDecoration(labelText: 'Code *'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: credits,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Scan credits *',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Price (₹) *'),
                ),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(existing == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) {
      name.dispose();
      code.dispose();
      credits.dispose();
      price.dispose();
      return;
    }

    final packName = name.text.trim();
    final packCode = code.text.trim().toLowerCase();
    final creditValue = int.tryParse(credits.text.trim());
    final rupees = int.tryParse(price.text.trim());

    if (packName.isEmpty || packCode.isEmpty) {
      _showMessage('Pack name and code are required.');
      return;
    }

    if (creditValue == null || creditValue <= 0) {
      _showMessage('Credits must be greater than 0.');
      return;
    }

    if (rupees == null || rupees < 0) {
      _showMessage('Enter a valid price.');
      return;
    }

    try {
      if (existing == null) {
        await _service.create(
          name: packName,
          code: packCode,
          credits: creditValue,
          pricePaise: rupees * 100,
        );
        _showMessage('Top-up pack created.');
      } else {
        await _service.update(
          existing.id,
          name: packName,
          code: packCode,
          credits: creditValue,
          pricePaise: rupees * 100,
          isActive: active,
        );
        _showMessage('Top-up pack updated.');
      }

      _reload();
    } catch (error) {
      _showMessage('$error');
    } finally {
      name.dispose();
      code.dispose();
      credits.dispose();
      price.dispose();
    }
  }

  Future<void> _delete(PlatformTopUp pack) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete top-up pack?'),
        content: Text('Delete "${pack.name}" permanently?'),
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
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.delete(pack.id);
      _showMessage('Top-up pack deleted.');
      _reload();
    } catch (error) {
      _showMessage('$error');
    }
  }

  Future<void> _toggle(PlatformTopUp pack) async {
    try {
      await _service.setActive(pack.id, !pack.isActive);
      _showMessage(
        pack.isActive ? 'Top-up pack deactivated.' : 'Top-up pack activated.',
      );
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
                  'Scan Top-Ups',
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
                label: const Text('Create pack'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<PlatformTopUp>>(
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
                        padding: const EdgeInsets.all(20),
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

              final packs = snapshot.data ?? const <PlatformTopUp>[];

              if (packs.isEmpty) {
                return const Center(
                  child: Text('No top-up packs in database yet.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: packs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final pack = packs[index];

                  return Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      title: Text(
                        pack.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        [
                          if (pack.code.isNotEmpty) pack.code,
                          '${pack.credits} scans',
                          pack.priceLabel,
                          pack.isActive ? 'Active' : 'Inactive',
                        ].join(' · '),
                      ),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Pack actions',
                        onSelected: (action) {
                          switch (action) {
                            case 'edit':
                              _openEditor(existing: pack);
                              break;
                            case 'toggle':
                              _toggle(pack);
                              break;
                            case 'delete':
                              _delete(pack);
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
                              leading: const Icon(
                                Icons.power_settings_new_outlined,
                              ),
                              title: Text(
                                pack.isActive ? 'Deactivate' : 'Activate',
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
