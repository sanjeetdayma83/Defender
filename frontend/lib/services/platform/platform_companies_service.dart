import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class PlatformCompany {
  final String id;
  final String name;
  final String? code;
  final String? planName;
  final String status;
  final bool isActive;
  final int usersCount;
  final int warehousesCount;
  final int ordersCount;
  final DateTime? createdAt;

  const PlatformCompany({
    required this.id,
    required this.name,
    this.code,
    this.planName,
    required this.status,
    required this.isActive,
    this.usersCount = 0,
    this.warehousesCount = 0,
    this.ordersCount = 0,
    this.createdAt,
  });

  factory PlatformCompany.fromJson(Map<String, dynamic> json) {
    int n(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    final status =
        '${json['status'] ?? (json['isActive'] == true ? 'ACTIVE' : 'INACTIVE')}'
            .toUpperCase();

    return PlatformCompany(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? json['companyName'] ?? '—'}',
      code: json['code']?.toString(),
      planName: json['planName']?.toString() ?? json['plan']?.toString(),
      status: status,
      isActive: json['isActive'] == true || status == 'ACTIVE',
      usersCount: n(json['userCount'] ?? json['usersCount'] ?? json['users']),
      warehousesCount: n(
        json['warehouseCount'] ?? json['warehousesCount'] ?? json['warehouses'],
      ),
      ordersCount: n(
        json['orderCountThisMonth'] ??
            json['orderCount'] ??
            json['ordersCount'],
      ),
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
    );
  }
}

class PlatformCompaniesService {
  final ApiClient _client;

  const PlatformCompaniesService({ApiClient? client})
    : _client = client ?? const ApiClient();

  Future<List<PlatformCompany>> list({String? search}) async {
    final query = <String, String>{};

    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/platform/companies',
    ).replace(queryParameters: query.isEmpty ? null : query);

    final response = await _client.get(uri);
    final body = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body is Map
            ? (body['message'] ?? 'Companies load failed')
            : 'Companies load failed',
      );
    }

    dynamic data = body;

    if (body is Map) {
      data = body['data'] ?? body['items'] ?? body['companies'];

      if (data is Map) {
        data = data['items'] ?? data['companies'] ?? data['data'];
      }
    }

    if (data is! List) {
      return const <PlatformCompany>[];
    }

    return data
        .whereType<Map>()
        .map(
          (entry) => PlatformCompany.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList();
  }

  Future<void> setActive(String id, bool isActive) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/platform/companies/$id/status'),
      body: jsonEncode({'isActive': isActive}),
    );

    final body = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body is Map ? (body['message'] ?? 'Update failed') : 'Update failed',
      );
    }
  }
}
