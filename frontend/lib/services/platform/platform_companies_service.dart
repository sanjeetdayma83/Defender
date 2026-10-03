import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class PlatformCompany {
  final String id;
  final String name;
  final String? code;
  final String status;
  final int userCount;
  final int warehouseCount;
  final String? planName;
  final String? subscriptionStatus;
  final String createdAt;

  const PlatformCompany({
    required this.id,
    required this.name,
    this.code,
    required this.status,
    required this.userCount,
    required this.warehouseCount,
    this.planName,
    this.subscriptionStatus,
    required this.createdAt,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory PlatformCompany.fromJson(Map<String, dynamic> json) {
    return PlatformCompany(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Company',
      code: json['code']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      userCount: (json['userCount'] is num)
          ? (json['userCount'] as num).toInt()
          : int.tryParse('${json['userCount']}') ?? 0,
      warehouseCount: (json['warehouseCount'] is num)
          ? (json['warehouseCount'] as num).toInt()
          : int.tryParse('${json['warehouseCount']}') ?? 0,
      planName: json['planName']?.toString(),
      subscriptionStatus: json['subscriptionStatus']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class PlatformCompaniesService {
  final ApiClient _client;
  const PlatformCompaniesService({ApiClient? client})
      : _client = client ?? const ApiClient();

  Future<({int total, List<PlatformCompany> items})> list({
    String search = '',
    String status = 'all',
  }) async {
    final qs = <String, String>{
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (status != 'all') 'status': status,
      'limit': '100',
    };
    final uri = Uri.parse('${ApiConfig.baseUrl}/platform/companies')
        .replace(queryParameters: qs);

    final response = await _client.get(uri);
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(msg ?? 'Unable to load companies.');
    }

    if (decoded is! Map || decoded['success'] != true) {
      throw Exception('Invalid companies response.');
    }

    final data = decoded['data'];
    if (data is! Map) {
      return (total: 0, items: <PlatformCompany>[]);
    }

    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => PlatformCompany.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <PlatformCompany>[];

    final total = data['total'] is num
        ? (data['total'] as num).toInt()
        : items.length;

    return (total: total, items: items);
  }

  Future<void> setActive(String id, bool isActive) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/platform/companies/$id/status');
    final response = await _client.patch(uri, body: {'isActive': isActive});
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(msg ?? 'Unable to update company.');
    }
  }
}
