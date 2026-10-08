import 'package:flutter/material.dart';

import '../../services/platform/platform_companies_service.dart';

class PlatformCompaniesScreen extends StatefulWidget {
  const PlatformCompaniesScreen({super.key});

  @override
  State<PlatformCompaniesScreen> createState() =>
      _PlatformCompaniesScreenState();
}

class _PlatformCompaniesScreenState extends State<PlatformCompaniesScreen> {
  final _service = const PlatformCompaniesService();
  final _search = TextEditingController();

  Future<List<PlatformCompany>>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _service.list(search: _search.text);
    });
  }

  Future<void> _toggle(PlatformCompany company) async {
    try {
      await _service.setActive(company.id, !company.isActive);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            company.isActive ? 'Company suspended.' : 'Company activated.',
          ),
        ),
      );

      _reload();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
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
              Expanded(
                child: TextField(
                  controller: _search,
                  onSubmitted: (_) => _reload(),
                  decoration: InputDecoration(
                    hintText: 'Search company...',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<PlatformCompany>>(
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
                        padding: const EdgeInsets.all(24),
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

              final companies = snapshot.data ?? const <PlatformCompany>[];

              if (companies.isEmpty) {
                return const Center(
                  child: Text(
                    'No companies found in the database.',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: companies.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final company = companies[index];

                  return Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      title: Text(
                        company.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [
                            if (company.code != null &&
                                company.code!.isNotEmpty)
                              company.code!,
                            if (company.planName != null &&
                                company.planName!.isNotEmpty)
                              company.planName!,
                            '${company.usersCount} users',
                            '${company.warehousesCount} WH',
                            '${company.ordersCount} orders this month',
                            company.isActive ? 'Active' : 'Suspended',
                          ].join(' · '),
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () => _toggle(company),
                        child: Text(company.isActive ? 'Suspend' : 'Activate'),
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
