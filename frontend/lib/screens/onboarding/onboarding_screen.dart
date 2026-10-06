import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../services/onboarding/onboarding_service.dart';
import '../../services/warehouse/warehouse_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _service = OnboardingService();
  final _warehouseService = WarehouseService();
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _companyCode = TextEditingController();
  final _warehouse = TextEditingController();
  final _warehouseCode = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pin = TextEditingController();
  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _warehouseId;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getStatus();
      final u = data['user'];
      final c = data['company'];
      final w = data['warehouses'];
      if (u is Map) _name.text = u['name']?.toString() ?? '';
      if (c is Map) {
        _company.text = c['name']?.toString() ?? '';
        _companyCode.text = c['code']?.toString() ?? '';
      }
      if (w is List && w.isNotEmpty && w.first is Map) {
        final x = Map<String, dynamic>.from(w.first as Map);
        _warehouseId = x['id']?.toString();
        _warehouse.text = x['name']?.toString() ?? '';
        _warehouseCode.text = x['code']?.toString() ?? '';
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _company,
      _companyCode,
      _warehouse,
      _warehouseCode,
      _address,
      _city,
      _state,
      _pin,
    ])
      c.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 4) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _complete() async {
    setState(() => _saving = true);
    try {
      await _service.updateProfile(_name.text.trim());
      await _service.updateCompany(
        name: _company.text.trim(),
        code: _companyCode.text.trim(),
      );
      if (_warehouseId == null) {
        final created = await _service.createWarehouse(
          name: _warehouse.text.trim(),
          code: _warehouseCode.text.trim(),
        );
        _warehouseId = created['id']?.toString();
      } else {
        await _warehouseService.updateWarehouse(
          warehouseId: _warehouseId!,
          name: _warehouse.text.trim(),
          code: _warehouseCode.text.trim(),
        );
      }
      await _service.complete();
      if (mounted) await context.read<SessionProvider>().refresh();
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FE),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final mobile = c.maxWidth < 850;
            return mobile
                ? _mobile()
                : Row(
                    children: [
                      SizedBox(width: 330, child: _hero()),
                      Expanded(child: _content()),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _hero() => Container(
    color: const Color(0xFF021F4F),
    padding: const EdgeInsets.all(34),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LOSS DEFENDER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 80),
        Text(
          'Let’s Set Up\nYour Company',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 35,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'A few quick steps to set up your workspace and start using Loss Defender Pro.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 38),
        ...List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: i <= _step
                      ? const Color(0xFF0061FC)
                      : Colors.white12,
                  child: Text(
                    i < _step ? '✓' : '${i + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labels[i],
                        style: TextStyle(
                          color: i <= _step ? Colors.white : Colors.white54,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _descriptions[i],
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  static const _labels = [
    'Company Details',
    'Business Details',
    'Add Warehouse',
    'Choose Plan',
    'Complete',
  ];
  static const _descriptions = [
    'Basic information about your company',
    'Business identity and address',
    'Set up your first warehouse',
    'Select a plan or trial',
    'Finish workspace setup',
  ];
  Widget _content() => Container(
    color: Colors.white,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(42, 30, 42, 34),
          child: Column(
            children: [
              _progress(),
              const SizedBox(height: 26),
              Expanded(child: SingleChildScrollView(child: _stepBody())),
              const SizedBox(height: 18),
              _actions(),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _mobile() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        _mobileHeader(),
        const SizedBox(height: 14),
        _progress(),
        const SizedBox(height: 18),
        _stepBody(),
        const SizedBox(height: 18),
        _actions(),
      ],
    ),
  );
  Widget _mobileHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF021F4F),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Text(
      'LOSS DEFENDER',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        fontSize: 21,
      ),
    ),
  );
  Widget _progress() => Row(
    children: List.generate(5, (i) {
      final active = i <= _step;
      return Expanded(
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF0061FC)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            if (i < 4)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: active
                      ? const Color(0xFF0061FC)
                      : const Color(0xFFE2E8F0),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      color: active ? Colors.white : const Color(0xFF64748B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }),
  );
  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _form(
          title: 'Company Details',
          subtitle:
              'Tell us about your company. This information will be used across your account.',
          fields: [
            _field(_company, 'Company Name', Icons.business_outlined, true),
            _field(_companyCode, 'Company Code', Icons.tag_outlined, false),
            _field(_name, 'Your Name', Icons.person_outline, true),
          ],
        );
      case 1:
        return _form(
          title: 'Business Details',
          subtitle:
              'Add the business identity you want associated with the workspace.',
          fields: [
            _field(
              _address,
              'Company Address',
              Icons.location_on_outlined,
              true,
              max: 300,
            ),
            _field(_city, 'City', Icons.location_city_outlined, true),
            _field(_state, 'State', Icons.map_outlined, true),
            _field(_pin, 'PIN Code', Icons.pin_drop_outlined, true),
          ],
        );
      case 2:
        return _form(
          title: 'Add Your First Warehouse',
          subtitle:
              'Create your first warehouse location. You can add more warehouses later.',
          fields: [
            _field(
              _warehouse,
              'Warehouse Name',
              Icons.warehouse_outlined,
              true,
            ),
            _field(
              _warehouseCode,
              'Warehouse Code',
              Icons.qr_code_2_outlined,
              false,
            ),
            _field(
              _address,
              'Address',
              Icons.location_on_outlined,
              true,
              max: 300,
            ),
          ],
        );
      case 3:
        return _plan();
      default:
        return _completeView();
    }
  }

  Widget _form({
    required String title,
    required String subtitle,
    required List<Widget> fields,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 31,
          fontWeight: FontWeight.w900,
          color: Color(0xFF071A46),
        ),
      ),
      const SizedBox(height: 7),
      Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
      const SizedBox(height: 25),
      ...fields,
    ],
  );
  Widget _field(
    TextEditingController c,
    String label,
    IconData icon,
    bool required, {
    int max = 120,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextField(
      controller: c,
      maxLines: max > 200 ? 4 : 1,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: Icon(icon),
      ),
    ),
  );
  Widget _plan() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Choose Your Plan',
        style: TextStyle(
          fontSize: 31,
          fontWeight: FontWeight.w900,
          color: Color(0xFF071A46),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Plan pricing is shown only when the billing API returns it.',
        style: TextStyle(color: Color(0xFF64748B)),
      ),
      const SizedBox(height: 26),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trial / current plan',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Your account plan will be loaded from the backend. This screen does not invent price or quota values.',
              style: TextStyle(color: Color(0xFF475569), height: 1.5),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const Text(
        'Plan selection can be completed after the plans endpoint is connected.',
        style: TextStyle(color: Color(0xFF64748B)),
      ),
    ],
  );
  Widget _completeView() => Column(
    children: [
      const SizedBox(height: 30),
      Container(
        width: 84,
        height: 84,
        decoration: const BoxDecoration(
          color: Color(0xFFDCFCE7),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Color(0xFF16A34A),
          size: 48,
        ),
      ),
      const SizedBox(height: 22),
      const Text(
        'Ready to Complete',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: Color(0xFF071A46),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Review your company and warehouse details, then finish setup.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF64748B)),
      ),
      const SizedBox(height: 20),
      if (_error != null)
        Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
    ],
  );
  Widget _actions() => Row(
    children: [
      if (_step > 0)
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _saving ? null : _back,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
        ),
      if (_step > 0) const SizedBox(width: 12),
      Expanded(
        flex: _step == 0 ? 1 : 2,
        child: FilledButton.icon(
          onPressed: _saving ? null : (_step < 4 ? _next : _complete),
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.arrow_forward),
          label: Text(_step < 4 ? 'Next' : 'Complete Setup'),
        ),
      ),
    ],
  );
}
