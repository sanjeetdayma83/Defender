import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class PlatformTopUp {
  final String id;
  final String code;
  final String name;
  final String? description;
  final int credits;
  final int pricePaise;
  final String currency;
  final bool isActive;

  const PlatformTopUp({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.credits,
    required this.pricePaise,
    required this.currency,
    required this.isActive,
  });

  factory PlatformTopUp.fromJson(Map<String, dynamic> json) {
    int n(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    return PlatformTopUp(
      id: '${json['id'] ?? ''}',
      code: '${json['code'] ?? ''}',
      name: '${json['name'] ?? '—'}',
      description: json['description']?.toString(),
      credits: n(json['credits'] ?? json['scanCredits']),
      pricePaise: n(json['pricePaise'] ?? json['price']),
      currency: '${json['currency'] ?? 'INR'}',
      isActive:
          json['isActive'] == true ||
          '${json['status']}'.toLowerCase() == 'active',
    );
  }

  String get priceLabel {
    final rupees = pricePaise / 100.0;
    final amount = rupees.truncateToDouble() == rupees
        ? rupees.toStringAsFixed(0)
        : rupees.toStringAsFixed(2);

    return '₹$amount';
  }
}

class PlatformTopupsService {
  final ApiClient _client;

  const PlatformTopupsService({ApiClient? client})
    : _client = client ?? const ApiClient();

  dynamic _items(dynamic body) {
    dynamic data = body;

    if (body is Map) {
      data = body['data'] ?? body['items'] ?? body['packs'];

      if (data is Map) {
        data = data['items'] ?? data['packs'] ?? data['data'];
      }
    }

    return data;
  }

  Future<List<PlatformTopUp>> list() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/platform/topups'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body is Map
            ? (body['message'] ?? 'Top-up packs load failed')
            : 'Top-up packs load failed',
      );
    }

    final data = _items(body);

    if (data is! List) {
      return const <PlatformTopUp>[];
    }

    return data
        .whereType<Map>()
        .map(
          (entry) => PlatformTopUp.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList();
  }

  Future<void> create({
    required String name,
    required String code,
    required int credits,
    required int pricePaise,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/platform/topups'),
      body: jsonEncode({
        'name': name.trim(),
        'code': code.trim(),
        'credits': credits,
        'pricePaise': pricePaise,
        'currency': 'INR',
      }),
    );

    _ensureSuccess(response, 'Create top-up failed');
  }

  Future<void> update(
    String id, {
    required String name,
    required String code,
    required int credits,
    required int pricePaise,
    required bool isActive,
  }) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/platform/topups/$id'),
      body: jsonEncode({
        'name': name.trim(),
        'code': code.trim(),
        'credits': credits,
        'pricePaise': pricePaise,
        'isActive': isActive,
      }),
    );

    _ensureSuccess(response, 'Update top-up failed');
  }

  Future<void> setActive(String id, bool isActive) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/platform/topups/$id/status'),
      body: jsonEncode({'isActive': isActive}),
    );

    _ensureSuccess(response, 'Update top-up status failed');
  }

  Future<void> delete(String id) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/platform/topups/$id'),
    );

    _ensureSuccess(response, 'Delete top-up failed');
  }

  void _ensureSuccess(dynamic response, String fallback) {
    final body = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body is Map ? (body['message'] ?? fallback) : fallback);
    }
  }
}
