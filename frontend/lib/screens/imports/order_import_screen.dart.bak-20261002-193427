import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api/api_client.dart';
import '../../services/api/api_config.dart';
import '../../services/onboarding/onboarding_service.dart';
import '../screen_ui.dart';

class OrderImportScreen extends StatefulWidget {
  const OrderImportScreen({super.key});

  @override
  State<OrderImportScreen> createState() => _OrderImportScreenState();
}

class _OrderImportScreenState extends State<OrderImportScreen> {
  final ApiClient _api = const ApiClient();
  final OnboardingService _onboarding = OnboardingService();

  PlatformFile? _file;
  Map<String, dynamic>? _preview;
  List<Map<String, dynamic>> _warehouses = <Map<String, dynamic>>[];
  String? _warehouseId;

  bool _loading = false;
  bool _importing = false;
  String? _error;
  String? _result;

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
      _result = null;
      _preview = null;
    });

    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
    );

    if (picked == null) return;

    setState(() => _file = picked);

    await _loadWarehouses();
    await _previewFile();
  }

  Future<void> _loadWarehouses() async {
    try {
      final status = await _onboarding.getStatus();
      final items = status['warehouses'];

      if (items is List) {
        final warehouses = items
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        if (!mounted) return;

        setState(() {
          _warehouses = warehouses;
          _warehouseId = warehouses.isEmpty
              ? null
              : warehouses.first['id']?.toString();
        });
      }
    } catch (_) {}
  }

  Future<http.StreamedResponse> _send(
    String endpoint,
    PlatformFile file, {
    Map<String, String>? fields,
  }) async {
    final bytes = await file.readAsBytes();

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
    );

    request.fields.addAll(fields ?? <String, String>{});

    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: file.name),
    );

    return _api.sendMultipart(request);
  }

  Future<void> _previewFile() async {
    final file = _file;
    if (file == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final streamed = await _send('/imports/preview', file);
      final response = await http.Response.fromStream(streamed);
      final decoded = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          decoded is Map
              ? decoded['message']?.toString() ?? 'Preview failed.'
              : 'Preview failed.',
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid preview response.');
      }

      setState(() {
        _preview = decoded['data'] is Map
            ? Map<String, dynamic>.from(decoded['data'] as Map)
            : <String, dynamic>{};
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _import() async {
    final file = _file;
    final warehouseId = _warehouseId;

    if (file == null || warehouseId == null) {
      setState(() => _error = 'Select a file and warehouse first.');
      return;
    }

    setState(() {
      _importing = true;
      _error = null;
      _result = null;
    });

    try {
      final streamed = await _send(
        '/imports/orders',
        file,
        fields: <String, String>{'warehouseId': warehouseId},
      );

      final response = await http.Response.fromStream(streamed);
      final decoded = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          decoded is Map
              ? decoded['message']?.toString() ?? 'Import failed.'
              : 'Import failed.',
        );
      }

      final data = decoded is Map ? decoded['data'] : null;

      if (!mounted) return;

      setState(() {
        _importing = false;
        _result = data is Map
            ? 'Imported rows: ${data['importedRows'] ?? 0} | '
                  'Orders: ${data['createdOrders'] ?? 0} | '
                  'Shipments: ${data['createdShipments'] ?? 0}'
            : 'Import completed successfully.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _importing = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview ?? <String, dynamic>{};
    final headers = preview['headers'] is List
        ? List<String>.from(
            (preview['headers'] as List).map((e) => e.toString()),
          )
        : <String>[];
    final rows = preview['rows'] is List
        ? preview['rows'] as List
        : <dynamic>[];
    final duplicates = preview['duplicates'] is List
        ? preview['duplicates'] as List
        : <dynamic>[];
    final valid = preview['valid'] == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Import Orders')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CSV / XLSX Order Import',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload, preview, validate duplicates and import into the selected warehouse.',
            ),
            const SizedBox(height: 22),
            LDCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FilledButton.icon(
                    onPressed: _loading || _importing ? null : _pickFile,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(
                      _file == null ? 'Choose CSV / XLSX' : _file!.name,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_warehouses.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: _warehouseId,
                      decoration: const InputDecoration(labelText: 'Warehouse'),
                      items: _warehouses
                          .map(
                            (w) => DropdownMenuItem<String>(
                              value: w['id']?.toString(),
                              child: Text(
                                '${w['name'] ?? 'Warehouse'}'
                                '${w['code'] != null ? ' • ${w['code']}' : ''}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _importing
                          ? null
                          : (value) => setState(() => _warehouseId = value),
                    )
                  else
                    const Text(
                      'No warehouse found. Complete onboarding first.',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              LDCard(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ],
            if (_loading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_preview != null && !_loading) ...[
              const SizedBox(height: 16),
              LDCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      valid ? 'Validation Passed' : 'Validation Failed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: valid ? ldGreen : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Headers: ${headers.length}'),
                    Text('Rows: ${rows.length}'),
                    Text('Duplicates: ${duplicates.length}'),
                    const SizedBox(height: 12),
                    if (headers.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: headers
                            .map((h) => Chip(label: Text(h)))
                            .toList(),
                      ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: valid && !_importing && _warehouseId != null
                          ? _import
                          : null,
                      icon: _importing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _importing ? 'Importing...' : 'Import Orders',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              LDCard(
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_result!)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

