import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class PlatformPlan {
  final String id;
  final String code;
  final String name;
  final String? description;
  final int pricePaise;
  final String currency;
  final String? billingInterval;
  final int? validityMonths;
  final int includedScans;
  final int? retentionDays;
  final int maxWarehouses;
  final int maxOperators;
  final int gstPercent;
  final bool isCommercial;
  final bool isActive;

  const PlatformPlan({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.pricePaise,
    required this.currency,
    this.billingInterval,
    this.validityMonths,
    required this.includedScans,
    this.retentionDays,
    required this.maxWarehouses,
    required this.maxOperators,
    required this.gstPercent,
    required this.isCommercial,
    required this.isActive,
  });

  double get priceInr => pricePaise / 100.0;

  factory PlatformPlan.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) =>
        v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return PlatformPlan(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      pricePaise: n(json['pricePaise']),
      currency: json['currency']?.toString() ?? 'INR',
      billingInterval: json['billingInterval']?.toString(),
      validityMonths: json['validityMonths'] == null
          ? null
          : n(json['validityMonths']),
      includedScans: n(json['includedScans']),
      retentionDays: json['retentionDays'] == null
          ? null
          : n(json['retentionDays']),
      maxWarehouses: n(json['maxWarehouses']),
      maxOperators: n(json['maxOperators']),
      gstPercent: n(json['gstPercent']),
      isCommercial: json['isCommercial'] == true,
      isActive: json['isActive'] == true,
    );
  }
}

class PlatformPlansService {
  final ApiClient _client;
  const PlatformPlansService({ApiClient? client})
      : _client = client ?? const ApiClient();

  Future<({int total, List<PlatformPlan> items})> list({
    bool activeOnly = false,
  }) async {
    final qs = <String, String>{
      if (activeOnly) 'active': 'true',
      'limit': '100',
    };
    final uri = Uri.parse('${ApiConfig.baseUrl}/platform/plans')
        .replace(queryParameters: qs);
    final response = await _client.get(uri);
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(msg ?? 'Unable to load plans.');
    }

    final data = decoded is Map ? decoded['data'] : null;
    if (data is! Map) return (total: 0, items: <PlatformPlan>[]);

    final raw = data['items'];
    final items = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => PlatformPlan.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <PlatformPlan>[];
    final total =
        data['total'] is num ? (data['total'] as num).toInt() : items.length;
    return (total: total, items: items);
  }

  Future<PlatformPlan> create(Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/platform/plans');
    final response = await _client.post(uri, body: body);
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(msg ?? 'Unable to create plan.');
    }
    final data = decoded is Map ? decoded['data'] : null;
    if (data is! Map) throw Exception('Invalid create response.');
    return PlatformPlan.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> setActive(String id, bool isActive) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/platform/plans/$id/status');
    final response = await _client.patch(uri, body: {'isActive': isActive});
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(msg ?? 'Unable to update plan.');
    }
  }

  Future<PlatformPlan> update(String id, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/platform/plans/$id');
    final response = await _client.patch(uri, body: body);
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(msg ?? 'Unable to update plan.');
    }
    final data = decoded is Map ? decoded['data'] : null;
    if (data is! Map) throw Exception('Invalid update response.');
    return PlatformPlan.fromJson(Map<String, dynamic>.from(data));
  }
}
