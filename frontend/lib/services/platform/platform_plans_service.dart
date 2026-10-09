import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class PlatformPlan {
  final String id;
  final String name;
  final String? code;
  final int pricePaise;
  final String period;
  final int? includedScans;
  final int? maxWarehouses;
  final int? maxOperators;
  final bool isActive;

  const PlatformPlan({
    required this.id,
    required this.name,
    this.code,
    required this.pricePaise,
    this.period = 'monthly',
    this.includedScans,
    this.maxWarehouses,
    this.maxOperators,
    this.isActive = true,
  });

  factory PlatformPlan.fromJson(Map<String, dynamic> json) {
    int n(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    final rawPeriod =
        '${json['billingInterval'] ?? json['period'] ?? json['billingPeriod'] ?? 'MONTHLY'}'
            .trim()
            .toLowerCase();

    return PlatformPlan(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? json['planName'] ?? '—'}',
      code: json['code']?.toString() ?? json['planCode']?.toString(),
      pricePaise: n(json['pricePaise'] ?? json['price'] ?? json['amountPaise']),
      period: rawPeriod.contains('year') ? 'yearly' : 'monthly',
      includedScans: json['includedScans'] != null
          ? n(json['includedScans'])
          : null,
      maxWarehouses: json['maxWarehouses'] != null
          ? n(json['maxWarehouses'])
          : null,
      maxOperators: json['maxOperators'] != null
          ? n(json['maxOperators'])
          : null,
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

    return '₹$amount/${period == 'yearly' ? 'yr' : 'mo'}';
  }
}

class PlatformPlansService {
  final ApiClient _client;

  const PlatformPlansService({ApiClient? client})
    : _client = client ?? const ApiClient();

  List<PlatformPlan> _parseList(dynamic body) {
    dynamic data = body;

    if (body is Map) {
      data = body['data'] ?? body['items'] ?? body['plans'];

      if (data is Map) {
        data = data['items'] ?? data['plans'] ?? data['data'];
      }
    }

    if (data is! List) {
      return const <PlatformPlan>[];
    }

    return data
        .whereType<Map>()
        .map((entry) => PlatformPlan.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  Future<List<PlatformPlan>> list() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/platform/plans'),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body is Map
            ? (body['message'] ?? 'Plans load failed')
            : 'Plans load failed',
      );
    }

    return _parseList(body);
  }

  Future<void> create({
    required String name,
    String? code,
    required int pricePaise,
    String period = 'monthly',
    int? includedScans,
    int? maxWarehouses,
    int? maxOperators,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'pricePaise': pricePaise,
      'billingInterval': period == 'yearly' ? 'YEARLY' : 'MONTHLY',
      if (code case final value? when value.isNotEmpty) 'code': value.trim(),
      'includedScans': ?includedScans,
      'maxWarehouses': ?maxWarehouses,
      'maxOperators': ?maxOperators,
    };

    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/platform/plans'),
      body: jsonEncode(payload),
    );

    _ensureSuccess(response, 'Create plan failed');
  }

  Future<void> update(
    String id, {
    required String name,
    String? code,
    required int pricePaise,
    required String period,
    int? includedScans,
    int? maxWarehouses,
    int? maxOperators,
    required bool isActive,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
      'pricePaise': pricePaise,
      'billingInterval': period == 'yearly' ? 'YEARLY' : 'MONTHLY',
      'isActive': isActive,
      if (code case final value? when value.isNotEmpty) 'code': value.trim(),
      'includedScans': ?includedScans,
      'maxWarehouses': ?maxWarehouses,
      'maxOperators': ?maxOperators,
    };

    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/platform/plans/$id'),
      body: jsonEncode(payload),
    );

    _ensureSuccess(response, 'Update plan failed');
  }

  Future<void> setActive(String id, bool isActive) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/platform/plans/$id/status'),
      body: jsonEncode({'isActive': isActive}),
    );

    _ensureSuccess(response, 'Update plan status failed');
  }

  Future<void> delete(String id) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/platform/plans/$id'),
    );

    _ensureSuccess(response, 'Delete plan failed');
  }

  void _ensureSuccess(dynamic response, String fallback) {
    final body = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(body is Map ? (body['message'] ?? fallback) : fallback);
    }
  }
}
