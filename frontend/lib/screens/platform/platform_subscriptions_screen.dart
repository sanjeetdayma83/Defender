import 'package:flutter/material.dart';

import '../../services/platform/platform_subscriptions_service.dart';

class PlatformSubscriptionsScreen extends StatefulWidget {
  const PlatformSubscriptionsScreen({super.key});

  @override
  State<PlatformSubscriptionsScreen> createState() =>
      _PlatformSubscriptionsScreenState();
}

class _PlatformSubscriptionsScreenState
    extends State<PlatformSubscriptionsScreen> {
  final _service = const PlatformSubscriptionsService();
  final _searchCtrl = TextEditingController();
  Future<({int total, List<PlatformSubscription> items})>? _future;
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _service.list(search: _searchCtrl.text, status: _status);
    });
  }

  Color _statusColor(String s) {
    switch (s.toUpperCase()) {
      case 'ACTIVE':
      case 'AUTHENTICATED':
        return Colors.green;
      case 'TRIALING':
        return Colors.blue;
      case 'PAST_DUE':
      case 'HALTED':
        return Colors.orange;
      case 'CANCELLED':
      case 'EXPIRED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Subscriptions',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Which tenant is on which plan (live BillingSubscription).',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Company, plan, Razorpay id...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _reload(),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _status,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All status')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'trialing', child: Text('Trialing')),
                  DropdownMenuItem(value: 'past_due', child: Text('Past due')),
                  DropdownMenuItem(
                    value: 'cancelled',
                    child: Text('Cancelled'),
                  ),
                  DropdownMenuItem(value: 'expired', child: Text('Expired')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  _status = v;
                  _reload();
                },
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
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
                  return Center(
                    child: Text(
                      'No subscriptions found.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$total subscriptions',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Company')),
                            DataColumn(label: Text('Plan')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Scans')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Period end')),
                            DataColumn(label: Text('Razorpay')),
                          ],
                          rows: items.map((s) {
                            final color = _statusColor(s.status);
                            final periodEnd = s.currentPeriodEnd;
                            final periodLabel = periodEnd == null
                                ? '—'
                                : periodEnd.length >= 10
                                ? periodEnd.substring(0, 10)
                                : periodEnd;
                            return DataRow(
                              cells: [
                                DataCell(Text(s.companyName ?? s.companyId)),
                                DataCell(Text(s.planName ?? s.planCode ?? '—')),
                                DataCell(Text(s.priceLabel)),
                                DataCell(
                                  Text(s.includedScans?.toString() ?? '—'),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      s.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(periodLabel)),
                                DataCell(
                                  Text(
                                    s.razorpaySubId ?? '—',
                                    style: const TextStyle(fontSize: 12),
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
