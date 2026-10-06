import 'dart:convert';
import '../api/api_client.dart';
import '../api/api_config.dart';

class PlatformPlan {
  final String id;
  final String name;
  final String? code;
  final int pricePaise;
  final String period; // monthly | yearly
  final int? includedScans;
  final int? maxWarehouses;
  final int? maxOperators;
  final bool isActive;

  PlatformPlan({
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

  factory PlatformPlan.fromJson(Map<String, dynamic> j) {
    int n(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return PlatformPlan(
      id: '${j['id'] ?? ''}',
      name: '${j['name'] ?? j['planName'] ?? '—'}',
      code: j['code']?.toString() ?? j['planCode']?.toString(),
      pricePaise: n(j['pricePaise'] ?? j['price'] ?? j['amountPaise']),
      period: '${j['period'] ?? j['billingPeriod'] ?? 'monthly'}',
      includedScans: j['includedScans'] != null ? n(j['includedScans']) : null,
      maxWarehouses: j['maxWarehouses'] != null ? n(j['maxWarehouses']) : null,
      maxOperators: j['maxOperators'] != null ? n(j['maxOperators']) : null,
      isActive: j['isActive'] == true || '${j['status']}'.toLowerCase() == 'active',
    );
  }

  String get priceLabel {
    final rs = pricePaise / 100.0;
    return '₹${rs.toStringAsFixed(rs.truncateToDouble() == rs ? 0 : 2)}/${period == 'yearly' ? 'yr' : 'mo'}';
  }
}

class PlatformPlansService {
  final ApiClient _client;
  const PlatformPlansService({ApiClient? client})
      : _client = client ?? const ApiClient();

  Future<List<PlatformPlan>> list() async {
    final res = await _client.get(Uri.parse('${ApiConfig.baseUrl}/platform/plans'));
    final body = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(body is Map ? (body['message'] ?? body) : 'Plans load failed');
    }
    final data = body is Map ? (body['data'] ?? body['items'] ?? body['plans']) : body;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => PlatformPlan.fromJson(Map<String, dynamic>.from(e)))
        .toList();
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
    final res = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/platform/plans'),
      body: jsonEncode({
        'name': name,
        if (code != null && code.isNotEmpty) 'code': code,
        'pricePaise': pricePaise,
        'billingInterval': period,
        if (includedScans != null) 'includedScans': includedScans,
        if (maxWarehouses != null) 'maxWarehouses': maxWarehouses,
        if (maxOperators != null) 'maxOperators': maxOperators,
      }),
    );
    final body = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(body is Map ? (body['message'] ?? body) : 'Create plan failed');
    }
  }
}

