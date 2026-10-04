import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class PlatformSubscription {
  final String id;
  final String companyId;
  final String? companyName;
  final String? planCode;
  final String? planName;
  final String status;
  final String? razorpaySubId;
  final int? pricePaise;
  final String? currency;
  final String? billingInterval;
  final int? includedScans;
  final String? currentPeriodStart;
  final String? currentPeriodEnd;
  final String createdAt;

  const PlatformSubscription({
    required this.id,
    required this.companyId,
    this.companyName,
    this.planCode,
    this.planName,
    required this.status,
    this.razorpaySubId,
    this.pricePaise,
    this.currency,
    this.billingInterval,
    this.includedScans,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    required this.createdAt,
  });

  String get priceLabel {
    if (pricePaise == null) return '—';
    final inr = pricePaise! / 100.0;
    return '₹${inr.toStringAsFixed(0)}';
  }

  factory PlatformSubscription.fromJson(Map<String, dynamic> json) {
    int? ni(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse('$v');
    }

    return PlatformSubscription(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      companyName: json['companyName']?.toString(),
      planCode: json['planCode']?.toString(),
      planName: json['planName']?.toString(),
      status: json['status']?.toString() ?? 'UNKNOWN',
      razorpaySubId: json['razorpaySubId']?.toString(),
      pricePaise: ni(json['pricePaise']),
      currency: json['currency']?.toString(),
      billingInterval: json['billingInterval']?.toString(),
      includedScans: ni(json['includedScans']),
      currentPeriodStart: json['currentPeriodStart']?.toString(),
      currentPeriodEnd: json['currentPeriodEnd']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class PlatformSubscriptionsService {
  final ApiClient _client;
  const PlatformSubscriptionsService({ApiClient? client})
      : _client = client ?? const ApiClient();

  Future<({int total, List<PlatformSubscription> items})> list({
    String search = '',
    String status = 'all',
  }) async {
    final qs = <String, String>{
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (status != 'all') 'status': status,
      'limit': '100',
    };
    final uri = Uri.parse('${ApiConfig.baseUrl}/platform/subscriptions')
        .replace(queryParameters: qs);

    final response = await _client.get(uri);
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(msg ?? 'Unable to load subscriptions.');
    }

    final data = decoded is Map ? decoded['data'] : null;
    if (data is! Map) {
      return (total: 0, items: <PlatformSubscription>[]);
    }

    final raw = data['items'];
    final items = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (e) => PlatformSubscription.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : <PlatformSubscription>[];

    final total =
        data['total'] is num ? (data['total'] as num).toInt() : items.length;
    return (total: total, items: items);
  }
}
