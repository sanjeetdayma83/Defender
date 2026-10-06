import 'package:flutter/material.dart';

import '../../services/platform/platform_ops_service.dart';
import '../../widgets/platform/platform_async_body.dart';

class PlatformStorageScreen extends StatefulWidget {
  const PlatformStorageScreen({super.key});
  @override
  State<PlatformStorageScreen> createState() => _PlatformStorageScreenState();
}

class _PlatformStorageScreenState extends State<PlatformStorageScreen> {
  final _svc = const PlatformOpsService();
  late Future<Map<String, dynamic>> _f;

  @override
  void initState() {
    super.initState();
    _f = _svc.storage();
  }

  void _reload() {
    final fut = _svc.storage();
    setState(() => _f = fut);
  }

  @override
  Widget build(BuildContext context) {
    return _PlatformScaffold(
      title: 'Storage',
      subtitle: 'Usage across tenants',
      actions: [
        OutlinedButton.icon(
          onPressed: _reload,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
        ),
      ],
      child: FutureBuilder(
        future: _f,
        builder: (context, snap) => PlatformAsyncBody(
          snap: snap,
          onRetry: _reload,
          builder: (_) {
            final total = snap.data?['totalBytes'] ?? 0;
            final items = (snap.data?['items'] as List?) ?? [];
            if (items.isEmpty) {
              return PlatformEmptyPage(
                message: 'No storage usage data.',
                onRetry: _reload,
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total: ${_fmtBytes(total)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Company')),
                        DataColumn(label: Text('Used')),
                        DataColumn(label: Text('Objects')),
                      ],
                      rows: items.whereType<Map>().map((raw) {
                        final m = Map<String, dynamic>.from(raw);
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                '${m['companyName'] ?? m['companyId'] ?? '—'}',
                              ),
                            ),
                            DataCell(Text(_fmtBytes(m['usedBytes'] ?? 0))),
                            DataCell(Text('${m['objectCount'] ?? 0}')),
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
    );
  }
}

class PlatformAnalyticsScreen extends StatefulWidget {
  const PlatformAnalyticsScreen({super.key});
  @override
  State<PlatformAnalyticsScreen> createState() =>
      _PlatformAnalyticsScreenState();
}

class _PlatformAnalyticsScreenState extends State<PlatformAnalyticsScreen> {
  final _svc = const PlatformOpsService();
  late Future<Map<String, dynamic>> _f;

  @override
  void initState() {
    super.initState();
    _f = _svc.analytics();
  }

  void _reload() {
    final fut = _svc.analytics();
    setState(() => _f = fut);
  }

  @override
  Widget build(BuildContext context) {
    return _PlatformScaffold(
      title: 'Analytics',
      subtitle: 'High-level platform metrics',
      actions: [
        OutlinedButton.icon(
          onPressed: _reload,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
        ),
      ],
      child: FutureBuilder(
        future: _f,
        builder: (context, snap) => PlatformAsyncBody(
          snap: snap,
          onRetry: _reload,
          builder: (_) {
            final d = snap.data ?? {};
            Widget card(String label, String value) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            );
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 200,
                  child: card('Companies', '${d['companies'] ?? 0}'),
                ),
                SizedBox(
                  width: 200,
                  child: card('Users', '${d['users'] ?? 0}'),
                ),
                SizedBox(
                  width: 200,
                  child: card(
                    'Active subs',
                    '${d['activeSubscriptions'] ?? 0}',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PlatformAuditLogsScreen extends StatefulWidget {
  const PlatformAuditLogsScreen({super.key});
  @override
  State<PlatformAuditLogsScreen> createState() =>
      _PlatformAuditLogsScreenState();
}

class _PlatformAuditLogsScreenState extends State<PlatformAuditLogsScreen> {
  final _svc = const PlatformOpsService();
  late Future<Map<String, dynamic>> _f;

  @override
  void initState() {
    super.initState();
    _f = _svc.auditLogs();
  }

  void _reload() {
    final fut = _svc.auditLogs();
    setState(() => _f = fut);
  }

  @override
  Widget build(BuildContext context) {
    return _PlatformScaffold(
      title: 'Audit Logs',
      subtitle: 'Sensitive admin actions',
      actions: [
        OutlinedButton.icon(
          onPressed: _reload,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
        ),
      ],
      child: FutureBuilder(
        future: _f,
        builder: (context, snap) => PlatformAsyncBody(
          snap: snap,
          onRetry: _reload,
          builder: (_) {
            final items = (snap.data?['items'] as List?) ?? [];
            if (items.isEmpty) {
              return PlatformEmptyPage(
                message: 'No audit logs (or table empty / schema mismatch).',
                onRetry: _reload,
              );
            }
            return SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Time')),
                  DataColumn(label: Text('Action')),
                  DataColumn(label: Text('Entity')),
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Company')),
                ],
                rows: items.whereType<Map>().map((raw) {
                  final m = Map<String, dynamic>.from(raw);
                  final t = '${m['createdAt'] ?? ''}';
                  return DataRow(
                    cells: [
                      DataCell(Text(t.length >= 19 ? t.substring(0, 19) : t)),
                      DataCell(Text('${m['action'] ?? ''}')),
                      DataCell(Text('${m['entity'] ?? '—'}')),
                      DataCell(Text('${m['userId'] ?? '—'}')),
                      DataCell(Text('${m['companyId'] ?? '—'}')),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PlatformSettingsScreen extends StatefulWidget {
  const PlatformSettingsScreen({super.key});
  @override
  State<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends State<PlatformSettingsScreen> {
  final _svc = const PlatformOpsService();
  late Future<Map<String, dynamic>> _f;
  bool _maintenance = false;
  bool _signups = true;

  @override
  void initState() {
    super.initState();
    _f = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final d = await _svc.settings();
    _maintenance = '${d['maintenanceMode']}'.toLowerCase() == 'true';
    _signups = '${d['allowNewSignups']}'.toLowerCase() != 'false';
    return d;
  }

  void _reload() {
    final fut = _load();
    setState(() => _f = fut);
  }

  Future<void> _save() async {
    try {
      await _svc.saveSettings({
        'maintenanceMode': '$_maintenance',
        'allowNewSignups': '$_signups',
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved')));
        _reload();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PlatformScaffold(
      title: 'Settings',
      subtitle: 'Config & feature flags',
      actions: [
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Save'),
        ),
        OutlinedButton.icon(
          onPressed: _reload,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
        ),
      ],
      child: FutureBuilder(
        future: _f,
        builder: (context, snap) => PlatformAsyncBody(
          snap: snap,
          onRetry: _reload,
          builder: (_) {
            return Column(
              children: [
                SwitchListTile(
                  title: const Text('Maintenance mode'),
                  value: _maintenance,
                  onChanged: (v) => setState(() => _maintenance = v),
                ),
                SwitchListTile(
                  title: const Text('Allow new signups'),
                  value: _signups,
                  onChanged: (v) => setState(() => _signups = v),
                ),
                const SizedBox(height: 8),
                Text(
                  'If platform_settings table is missing, Save may no-op; defaults still show.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _fmtBytes(dynamic v) {
  final n = v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  if (n < 1024) return '${n.toStringAsFixed(0)} B';
  if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(1)} KB';
  if (n < 1024 * 1024 * 1024) {
    return '${(n / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(n / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

class _PlatformScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget child;

  const _PlatformScaffold({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
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
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              ...actions.map(
                (w) =>
                    Padding(padding: const EdgeInsets.only(left: 8), child: w),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: child),
        ],
      ),
    );
  }
}



