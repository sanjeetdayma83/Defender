import 'package:flutter/material.dart';

import '../../services/platform/platform_companies_service.dart';

class PlatformCompaniesScreen extends StatefulWidget {
  const PlatformCompaniesScreen({super.key});

  @override
  State<PlatformCompaniesScreen> createState() =>
      _PlatformCompaniesScreenState();
}

class _PlatformCompaniesScreenState extends State<PlatformCompaniesScreen> {
  static const navy = Color(0xFF10235E);
  static const blue = Color(0xFF1769FF);
  static const green = Color(0xFF0DBB78);
  static const orange = Color(0xFFFF9819);
  static const red = Color(0xFFF23D4F);
  static const purple = Color(0xFF8A35F5);
  static const bg = Color(0xFFF5F8FD);
  static const border = Color(0xFFE1E7F0);
  static const muted = Color(0xFF6F7D9E);

  final _service = const PlatformCompaniesService();
  final _searchController = TextEditingController();

  PlatformCompaniesPage? _page;
  PlatformCompany? _selected;

  Object? _error;

  String _status = 'all';
  String _plan = 'All';
  String _region = 'All';

  int _pageNumber = 1;

  bool _loading = true;
  bool _detailLoading = false;
  bool _statusUpdating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool keepSelection = true}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await _service.list(
        search: _searchController.text.trim(),
        status: _status,
        plan: _plan,
        region: _region,
        page: _pageNumber,
        limit: 10,
      );

      if (!mounted) return;

      PlatformCompany? nextSelected;

      if (result.items.isNotEmpty) {
        if (keepSelection && _selected != null) {
          for (final item in result.items) {
            if (item.id == _selected!.id) {
              nextSelected = item;
              break;
            }
          }
        }

        nextSelected ??= result.items.first;
      }

      setState(() {
        _page = result;
        _selected = nextSelected;
        _loading = false;
      });

      if (nextSelected != null) {
        await _loadDetail(nextSelected.id, showError: false);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  Future<void> _loadDetail(String id, {bool showError = true}) async {
    if (mounted) {
      setState(() {
        _detailLoading = true;
      });
    }

    try {
      final company = await _service.get(id);

      if (!mounted) return;

      setState(() {
        _selected = company;
        _detailLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _detailLoading = false;
      });

      if (showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _toggleCompany() async {
    final company = _selected;

    if (company == null || _statusUpdating) return;

    setState(() {
      _statusUpdating = true;
    });

    try {
      await _service.setActive(company.id, !company.isActive);

      if (!mounted) return;

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            company.isActive
                ? '${company.name} suspended'
                : '${company.name} activated',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _statusUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              _header(constraints.maxWidth),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: blue),
                      )
                    : _error != null
                    ? _errorState()
                    : _body(constraints.maxWidth),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(double width) {
    final compact = width < 900;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 26,
        18,
        compact ? 16 : 26,
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: blue,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x302569EB),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.business_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text(
                      'Platform Admin',
                      style: TextStyle(color: muted, fontSize: 11),
                    ),
                    Icon(Icons.chevron_right_rounded, color: muted, size: 15),
                    Text(
                      'Companies',
                      style: TextStyle(
                        color: navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Companies',
                  style: TextStyle(
                    color: navy,
                    fontSize: compact ? 23 : 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Manage all companies on the Loss Defender platform.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 14),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Company creation API is not available yet.'),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Company'),
              style: FilledButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _load(),
              tooltip: 'Refresh',
              style: IconButton.styleFrom(
                side: const BorderSide(color: border),
                backgroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded, color: navy),
            ),
          ],
        ],
      ),
    );
  }

  Widget _body(double width) {
    final page = _page;

    if (page == null || page.items.isEmpty) {
      return _emptyState();
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(26, 0, 26, 28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1200;

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _mainContent(page)),
                const SizedBox(width: 14),
                SizedBox(width: 330, child: _detailPanel()),
              ],
            );
          }

          return Column(
            children: [
              _mainContent(page),
              const SizedBox(height: 14),
              _detailPanel(),
            ],
          );
        },
      ),
    );
  }

  Widget _mainContent(PlatformCompaniesPage page) {
    return Column(
      children: [
        _summaryCards(page.summary),
        const SizedBox(height: 14),
        _filters(page),
        const SizedBox(height: 12),
        _table(page),
      ],
    );
  }

  Widget _summaryCards(PlatformCompaniesSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 1000
            ? (constraints.maxWidth - 36) / 4
            : constraints.maxWidth >= 650
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _metricCard(
                title: 'Total Companies',
                value: _number(summary.totalCompanies),
                subtitle:
                    '${summary.activeCompanies} active • ${summary.inactiveCompanies} inactive',
                icon: Icons.business_rounded,
                color: blue,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _metricCard(
                title: 'Total Users',
                value: _number(summary.totalUsers),
                subtitle: 'Across all onboarded companies',
                icon: Icons.groups_rounded,
                color: green,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _metricCard(
                title: 'Total Revenue',
                value: _money(summary.totalRevenuePaise),
                subtitle: 'This month',
                icon: Icons.account_balance_wallet_rounded,
                color: purple,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _metricCard(
                title: 'Scan Credits Sold',
                value: _number(summary.scanCreditsSold),
                subtitle: 'Top-up credits sold',
                icon: Icons.confirmation_number_rounded,
                color: orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B2A68),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters(PlatformCompaniesPage page) {
    return _surface(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 290,
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) {
                _pageNumber = 1;
                _load(keepSelection: false);
              },
              decoration: InputDecoration(
                hintText: 'Search company, code, email or GST...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: navy,
                ),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF9FBFE),
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: blue),
                ),
              ),
            ),
          ),
          _dropdown(
            value: _status == 'all' ? 'All Status' : _status.toUpperCase(),
            items: const ['All Status', 'ACTIVE', 'INACTIVE'],
            onChanged: (value) {
              _status = value == 'All Status' ? 'all' : value.toLowerCase();

              _pageNumber = 1;
              _load(keepSelection: false);
            },
          ),
          _dropdown(
            value: _plan,
            items: ['All', ...page.plans.where((e) => e != 'All')],
            onChanged: (value) {
              _plan = value;
              _pageNumber = 1;
              _load(keepSelection: false);
            },
          ),
          _dropdown(
            value: _region,
            items: ['All', ...page.regions.where((e) => e != 'All')],
            onChanged: (value) {
              _region = value;
              _pageNumber = 1;
              _load(keepSelection: false);
            },
          ),
          OutlinedButton.icon(
            onPressed: () => _load(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 17),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: const TextStyle(fontSize: 11)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }

  Widget _table(PlatformCompaniesPage page) {
    final start = page.total == 0 ? 0 : ((page.page - 1) * page.limit) + 1;

    final end = ((page.page - 1) * page.limit + page.items.length).clamp(
      0,
      page.total,
    );

    return _surface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 10),
            child: Row(
              children: [
                Text(
                  'Showing $start–$end of ${page.total} companies',
                  style: const TextStyle(
                    color: navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                _pager(page),
              ],
            ),
          ),
          const Divider(height: 1, color: border),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 22,
              horizontalMargin: 14,
              headingRowHeight: 42,
              dataRowMinHeight: 62,
              dataRowMaxHeight: 68,
              headingRowColor: const WidgetStatePropertyAll(Color(0xFFF9FBFE)),
              columns: const [
                DataColumn(label: Text('COMPANY NAME')),
                DataColumn(label: Text('PLAN')),
                DataColumn(label: Text('USERS')),
                DataColumn(label: Text('WAREHOUSES')),
                DataColumn(label: Text('STORAGE')),
                DataColumn(label: Text('MONTHLY ORDERS')),
                DataColumn(label: Text('REVENUE (MTD)')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('JOINED DATE')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: page.items.map(_companyRow).toList(),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _companyRow(PlatformCompany company) {
    final selected = _selected?.id == company.id;

    return DataRow(
      color: WidgetStateProperty.resolveWith(
        (_) => selected ? const Color(0xFFF1F6FF) : null,
      ),
      cells: [
        DataCell(
          InkWell(
            onTap: () => _loadDetail(company.id),
            child: SizedBox(
              width: 190,
              child: Row(
                children: [
                  _avatar(company.name),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: navy,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (company.gstin != null || company.code != null)
                          Text(
                            company.gstin ?? 'ID: ${company.code}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: muted, fontSize: 8.5),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        DataCell(_pill(company.planName ?? 'No plan', purple)),
        DataCell(
          Text(
            '${company.userCount}',
            style: const TextStyle(color: navy, fontWeight: FontWeight.w700),
          ),
        ),
        DataCell(
          Text(
            '${company.warehouseCount}',
            style: const TextStyle(color: navy, fontWeight: FontWeight.w700),
          ),
        ),
        DataCell(_storage(company)),
        DataCell(Text(_number(company.orderCountThisMonth))),
        DataCell(
          Text(
            _money(company.revenuePaise),
            style: const TextStyle(color: navy, fontWeight: FontWeight.w800),
          ),
        ),
        DataCell(
          _pill(
            company.isActive ? 'Active' : 'Inactive',
            company.isActive ? green : red,
          ),
        ),
        DataCell(Text(_date(company.createdAt))),
        DataCell(
          IconButton(
            tooltip: 'View company',
            onPressed: () => _loadDetail(company.id),
            icon: const Icon(Icons.more_horiz_rounded, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _storage(PlatformCompany company) {
    final quota = company.storageQuotaBytes;

    if (quota == null || quota <= 0) {
      return Text(
        _bytes(company.storageUsedBytes),
        style: const TextStyle(fontSize: 10),
      );
    }

    final progress = (company.storageUsedBytes / quota)
        .clamp(0.0, 1.0)
        .toDouble();

    return SizedBox(
      width: 105,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_bytes(company.storageUsedBytes)} / ${_bytes(quota)}',
            style: const TextStyle(
              color: navy,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE7EDF7),
              color: blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailPanel() {
    final company = _selected;

    if (company == null) {
      return _surface(
        child: const SizedBox(
          height: 260,
          child: Center(
            child: Text(
              'Select a company to view details.',
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ),
        ),
      );
    }

    return _surface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 17, 12, 13),
            child: Row(
              children: [
                _largeAvatar(company.name),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _pill(
                        company.isActive ? 'Active' : 'Inactive',
                        company.isActive ? green : red,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _loadDetail(company.id),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: border),
          if (_detailLoading)
            const LinearProgressIndicator(minHeight: 2, color: blue),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _info(
                  Icons.receipt_long_outlined,
                  'GST',
                  company.gstin ?? 'Not available',
                ),
                _info(
                  Icons.email_outlined,
                  'Email',
                  company.billingEmail ?? 'Not available',
                ),
                _info(
                  Icons.phone_outlined,
                  'Phone',
                  company.billingPhone ?? 'Not available',
                ),
                _info(
                  Icons.location_on_outlined,
                  'Address',
                  company.address ?? 'Not available',
                ),
                const SizedBox(height: 7),
                const Divider(color: border),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: _detailMetric(
                        'Users',
                        '${company.userCount}',
                        blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _detailMetric(
                        'Warehouses',
                        '${company.warehouseCount}',
                        green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _detailMetric(
                        'Storage',
                        _bytes(company.storageUsedBytes),
                        purple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _detailMetric(
                        'Orders MTD',
                        _number(company.orderCountThisMonth),
                        orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _detailMetric(
                        'Scan Credits',
                        _number(company.walletBalance),
                        blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _detailMetric(
                        'Revenue MTD',
                        _money(company.revenuePaise),
                        green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _accountInfo(company),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _statusUpdating ? null : _toggleCompany,
                    icon: Icon(
                      company.isActive
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                    ),
                    label: Text(
                      company.isActive ? 'Suspend Company' : 'Activate Company',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: company.isActive ? red : green,
                      side: BorderSide(color: company.isActive ? red : green),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountInfo(PlatformCompany company) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Information',
            style: TextStyle(
              color: navy,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _line('Plan', company.planName ?? 'No plan'),
          _line('Joined Date', _date(company.createdAt)),
          _line('Subscription', company.subscriptionStatus ?? 'Not available'),
          _line(
            'Plan Price',
            company.planPricePaise == null
                ? 'Not available'
                : _money(company.planPricePaise!),
          ),
          _line('Account Status', company.isActive ? 'Active' : 'Inactive'),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: blue, size: 17),
          const SizedBox(width: 9),
          SizedBox(
            width: 62,
            child: Text(
              label,
              style: const TextStyle(
                color: muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: navy,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: muted, fontSize: 10),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: navy,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: muted, fontSize: 9)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pager(PlatformCompaniesPage page) {
    final canPrev = page.page > 1;
    final canNext = page.page < page.pages;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: canPrev
              ? () {
                  _pageNumber--;
                  _load(keepSelection: false);
                }
              : null,
          icon: const Icon(Icons.chevron_left_rounded, size: 19),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: blue,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '${page.page}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: canNext
              ? () {
                  _pageNumber++;
                  _load(keepSelection: false);
                }
              : null,
          icon: const Icon(Icons.chevron_right_rounded, size: 19),
        ),
      ],
    );
  }

  Widget _errorState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _surface(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF1F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: red,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Unable to load companies',
                  style: TextStyle(
                    color: navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _error?.toString().replaceFirst('Exception: ', '') ??
                      'The live Platform Admin API returned an error.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => _load(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: _surface(
        child: Padding(
          padding: const EdgeInsets.all(35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.business_outlined, color: muted, size: 40),
              SizedBox(height: 10),
              Text(
                'No companies found',
                style: TextStyle(color: navy, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 5),
              Text(
                'Try changing the search or filters.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _surface({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B2A68),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _avatar(String name) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _avatarColor(name),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        _initial(name),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _largeAvatar(String name) {
    return Container(
      width: 45,
      height: 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _avatarColor(name),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _initial(name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _initial(String name) {
    final clean = name.trim();

    if (clean.isEmpty) return '?';

    return clean.substring(0, 1).toUpperCase();
  }

  Color _avatarColor(String name) {
    final colors = [blue, green, purple, orange, red, const Color(0xFF08A8A8)];

    return colors[name.codeUnitAt(0) % colors.length];
  }

  String _number(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _money(int paise) {
    final rupees = paise ~/ 100;

    return '₹${_number(rupees)}';
  }

  String _bytes(int bytes) {
    if (bytes <= 0) return '0 B';

    const kb = 1024;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (bytes >= gb) {
      return '${(bytes / gb).toStringAsFixed(1)} GB';
    }

    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    }

    if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(1)} KB';
    }

    return '$bytes B';
  }

  String _date(String value) {
    if (value.length < 10) {
      return value.isEmpty ? '—' : value;
    }

    final parts = value.substring(0, 10).split('-');

    if (parts.length != 3) {
      return value.substring(0, 10);
    }

    return '${parts[2]} ${_month(parts[1])}, ${parts[0]}';
  }

  String _month(String value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final index = int.tryParse(value);

    if (index == null || index < 1 || index > 12) {
      return value;
    }

    return months[index - 1];
  }
}
