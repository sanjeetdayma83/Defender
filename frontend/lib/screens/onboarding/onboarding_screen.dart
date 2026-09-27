import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../../services/onboarding/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _companyCode = TextEditingController();
  final _warehouse = TextEditingController();
  final _warehouseCode = TextEditingController();

  final OnboardingService _service = OnboardingService();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getStatus();

      final user = data['user'];
      final company = data['company'];
      final warehouses = data['warehouses'];

      if (user is Map) {
        _name.text = user['name']?.toString() ?? '';
      }

      if (company is Map) {
        _company.text = company['name']?.toString() ?? '';
        _companyCode.text = company['code']?.toString() ?? '';
      }

      if (warehouses is List && warehouses.isNotEmpty && warehouses.first is Map) {
        final first = Map<String, dynamic>.from(warehouses.first as Map);
        _warehouse.text = first['name']?.toString() ?? '';
        _warehouseCode.text = first['code']?.toString() ?? '';
      }
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _complete() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await _service.updateProfile(_name.text.trim());

      await _service.updateCompany(
        name: _company.text.trim(),
        code: _companyCode.text.trim(),
      );

      if (_warehouse.text.trim().isNotEmpty) {
        await _service.createWarehouse(
          name: _warehouse.text.trim(),
          code: _warehouseCode.text.trim(),
        );
      }

      await _service.complete();

      if (!mounted) return;
      await context.read<SessionProvider>().refresh();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _companyCode.dispose();
    _warehouse.dispose();
    _warehouseCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete your workspace',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Set up your profile, company and primary warehouse.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 18),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Your name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Name is required.'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _company,
                          decoration: const InputDecoration(
                            labelText: 'Company name',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Company name is required.'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _companyCode,
                          decoration: const InputDecoration(
                            labelText: 'Company code',
                            prefixIcon: Icon(Icons.tag_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _warehouse,
                          decoration: const InputDecoration(
                            labelText: 'Primary warehouse',
                            prefixIcon: Icon(Icons.warehouse_outlined),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Warehouse name is required.'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _warehouseCode,
                          decoration: const InputDecoration(
                            labelText: 'Warehouse code',
                            prefixIcon: Icon(Icons.qr_code_2_outlined),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: _saving ? null : _complete,
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Complete Setup'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
