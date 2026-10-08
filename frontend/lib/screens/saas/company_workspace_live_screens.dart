import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../../services/billing_checkout/billing_checkout.dart';
import '../../services/company/company_billing_service.dart';
import '../dashboard/dashboard_screen.dart';

class CompanyWorkspaceDashboardScreen extends StatelessWidget {
  const CompanyWorkspaceDashboardScreen({required this.onScanPack, super.key});

  final VoidCallback onScanPack;

  @override
  Widget build(BuildContext context) {
    return DashboardScreen(onScanPack: onScanPack);
  }
}

class CompanyWalletScreen extends StatefulWidget {
  const CompanyWalletScreen({super.key});

  @override
  State<CompanyWalletScreen> createState() => _CompanyWalletScreenState();
}

class _CompanyWalletScreenState extends State<CompanyWalletScreen> {
  final _service = CompanyBillingService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _wallet;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        _service.wallet(),
        _service.walletTransactions(),
      ]);

      final walletBody = results[0] as Map<String, dynamic>;
      final txBody = results[1] as Map<String, dynamic>;

      final wallet = walletBody['data'];
      final txData = txBody['data'];

      setState(() {
        _wallet = wallet is Map ? Map<String, dynamic>.from(wallet) : null;

        final items = txData is Map && txData['items'] is List
            ? txData['items'] as List
            : <dynamic>[];

        _transactions = items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int _n(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final balance = _n(_wallet?['balance']);
    final allocated = _n(_wallet?['lifetimeAllocated']);
    final consumed = _n(_wallet?['lifetimeConsumed']);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Scan Wallet',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF071A46),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Live scan-credit balance and wallet ledger.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          if (_error != null) _Message(message: _error!, onRetry: _load),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _Card(
                title: 'Available',
                value: _loading ? '—' : '$balance',
                icon: Icons.account_balance_wallet_outlined,
              ),
              _Card(
                title: 'Allocated',
                value: _loading ? '—' : '$allocated',
                icon: Icons.add_circle_outline,
              ),
              _Card(
                title: 'Consumed',
                value: _loading ? '—' : '$consumed',
                icon: Icons.remove_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _Panel(
            title: 'Wallet Ledger',
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _transactions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No wallet transactions yet.',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  )
                : Column(
                    children: _transactions
                        .map(
                          (row) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFEFF6FF),
                              child: Icon(
                                row['type']?.toString().toUpperCase() ==
                                        'CONSUMPTION'
                                    ? Icons.remove
                                    : Icons.add,
                                color: const Color(0xFF0061FC),
                              ),
                            ),
                            title: Text(
                              row['description']?.toString() ??
                                  row['type']?.toString() ??
                                  'Transaction',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(row['createdAt']?.toString() ?? ''),
                            trailing: Text(
                              '${_n(row['credits'])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class CompanySubscriptionScreen extends StatefulWidget {
  const CompanySubscriptionScreen({super.key});

  @override
  State<CompanySubscriptionScreen> createState() =>
      _CompanySubscriptionScreenState();
}

class _CompanySubscriptionScreenState extends State<CompanySubscriptionScreen> {
  final _service = CompanyBillingService();

  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final plans = await _service.plans();
      final subscription = await _service.subscription();

      if (!mounted) return;

      setState(() {
        _plans = plans;
        _subscription = subscription;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int _n(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic paise) {
    final value = _n(paise);
    return '₹${(value / 100).toStringAsFixed(0)}';
  }

  Future<void> _purchase(Map<String, dynamic> plan) async {
    if (_purchasing) return;

    final currentUser = context.read<SessionProvider>().user;

    final code = plan['code']?.toString().trim().toLowerCase() ?? '';

    if (code.isEmpty) return;

    final interval =
        plan['billingInterval']?.toString().toUpperCase() == 'YEARLY'
        ? 'YEARLY'
        : 'MONTHLY';

    setState(() {
      _purchasing = true;
      _error = null;
    });

    try {
      final body = await _service.createPlanOrder(
        planCode: code,
        billingInterval: interval,
      );

      final data = body['data'];

      if (data is! Map) {
        throw Exception('Payment order response is invalid.');
      }

      final result = Map<String, dynamic>.from(data);

      final razorpay = result['razorpay'];

      final payment = result['payment'];

      if (razorpay is! Map || payment is! Map) {
        throw Exception('Payment gateway data is incomplete.');
      }

      final response = await openRazorpayCheckout(
        keyId: razorpay['keyId']?.toString() ?? '',
        orderId: razorpay['orderId']?.toString() ?? '',
        amountPaise: _n(razorpay['amount']),
        currency: razorpay['currency']?.toString() ?? 'INR',
        name: currentUser?.name.trim().isNotEmpty == true
            ? currentUser!.name
            : 'Loss Defender Customer',
        description: '${plan['name'] ?? code} Plan',
        email: currentUser?.email ?? '',
        phone: '',
      );

      if (response == null) {
        throw Exception(
          'Payment was cancelled or no payment response was received.',
        );
      }

      final verified = await _service.verifyPayment(
        paymentId: payment['id']?.toString() ?? '',
        razorpayPaymentId: response['razorpay_payment_id']?.toString() ?? '',
        razorpayOrderId: response['razorpay_order_id']?.toString() ?? '',
        razorpaySignature: response['razorpay_signature']?.toString() ?? '',
      );

      if (!mounted) return;

      await _load();

      final verifiedData = verified['data'];

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            verifiedData != null
                ? 'Payment successful. Subscription updated.'
                : 'Payment successful.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _purchasing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentName =
        _subscription?['planName']?.toString() ??
        _subscription?['plan']?.toString() ??
        'Free';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Subscription',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF071A46),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'View your live plan and purchase available plans.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          _Panel(
            title: 'Current Plan',
            child: Row(
              children: [
                const Icon(
                  Icons.credit_card_outlined,
                  size: 32,
                  color: Color(0xFF0061FC),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    currentName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  _subscription?['status']?.toString().toUpperCase() ??
                      'ACTIVE / FREE',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_error != null) _Message(message: _error!, onRetry: _load),
          const Text(
            'Available Plans',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_plans.isEmpty)
            const _Panel(
              title: 'No plans available',
              child: Text(
                'No active commercial plans were returned by the billing API.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            )
          else
            ..._plans.map(
              (plan) => _PlanCard(
                plan: plan,
                money: _money,
                purchasing: _purchasing,
                onPurchase: () => _purchase(plan),
              ),
            ),
        ],
      ),
    );
  }
}

class CompanyBillingScreen extends StatefulWidget {
  const CompanyBillingScreen({super.key});

  @override
  State<CompanyBillingScreen> createState() => _CompanyBillingScreenState();
}

class _CompanyBillingScreenState extends State<CompanyBillingScreen> {
  final _service = CompanyBillingService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _invoices = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final body = await _service.invoices();
      final data = body['data'];

      final items = data is Map && data['items'] is List
          ? data['items'] as List
          : <dynamic>[];

      if (!mounted) return;

      setState(() {
        _invoices = items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int _n(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _money(dynamic paise) {
    return '₹${(_n(paise) / 100).toStringAsFixed(2)}';
  }

  Future<void> _openPdf(String invoiceId) async {
    try {
      final data = await _service.invoicePdf(invoiceId);

      final payload = data['data'];

      if (payload is Map) {
        final url = payload['signedUrl']?.toString() ?? '';

        if (url.isNotEmpty) {
          await openExternalUrl(url);
          return;
        }
      }

      throw Exception('Invoice PDF URL was not returned.');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Billing',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF071A46),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Live invoices and billing records for your company.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          if (_error != null) _Message(message: _error!, onRetry: _load),
          _Panel(
            title: 'Invoices',
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _invoices.isEmpty
                ? const Text(
                    'No invoices have been generated yet.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  )
                : Column(
                    children: _invoices
                        .map(
                          (invoice) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.receipt_long_outlined,
                              color: Color(0xFF0061FC),
                            ),
                            title: Text(
                              invoice['invoiceNumber']?.toString() ?? 'Invoice',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              [
                                invoice['issuedAt']?.toString() ?? '',
                                invoice['status']?.toString().toUpperCase() ??
                                    '',
                              ].where((x) => x.isNotEmpty).join(' • '),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _money(invoice['totalPaise']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Open invoice PDF',
                                  onPressed: () =>
                                      _openPdf(invoice['id']?.toString() ?? ''),
                                  icon: const Icon(
                                    Icons.picture_as_pdf_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.money,
    required this.purchasing,
    required this.onPurchase,
  });

  final Map<String, dynamic> plan;
  final String Function(dynamic) money;
  final bool purchasing;
  final VoidCallback onPurchase;

  @override
  Widget build(BuildContext context) {
    final scans = plan['includedScans']?.toString() ?? '0';
    final retention = plan['retentionDays']?.toString() ?? '0';
    final warehouses = plan['maxWarehouses']?.toString() ?? '—';
    final operators = plan['maxOperators']?.toString() ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6F3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            color: Color(0xFF0061FC),
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan['name']?.toString() ??
                      plan['code']?.toString() ??
                      'Plan',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  plan['description']?.toString() ??
                      'Loss Defender workspace plan',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    Text('Scans: $scans'),
                    Text('Retention: ${retention}d'),
                    Text('Warehouses: $warehouses'),
                    Text('Operators: $operators'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(plan['pricePaise']),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF071A46),
                ),
              ),
              Text(
                plan['billingInterval']?.toString().toUpperCase() == 'YEARLY'
                    ? 'yearly'
                    : 'monthly',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: purchasing ? null : onPurchase,
                child: purchasing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Purchase'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 235,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCE6F3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF0061FC)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF071A46),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFC2410C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF9A3412)),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
