import 'dart:convert';
import '../api/api_client.dart';
import '../api/api_config.dart';

class PlatformCompany {
  final String id;
  final String name;
  final String? code;
  final bool isActive;
  final int usersCount;
  final int warehousesCount;
  final int ordersCount;
  final DateTime? createdAt;

  PlatformCompany({
    required this.id,
    required this.name,
    this.code,
    required this.isActive,
    this.usersCount = 0,
    this.warehousesCount = 0,
    this.ordersCount = 0,
    this.createdAt,
  });

  factory PlatformCompany.fromJson(Map<String, dynamic> j) {
    int n(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return PlatformCompany(
      id: '${j['id'] ?? ''}',
      name: '${j['name'] ?? j['companyName'] ?? '—'}',
      code: j['code']?.toString(),
      isActive: j['isActive'] == true ||
          '${j['status']}'.toLowerCase() == 'active',
      usersCount: n(j['usersCount'] ?? j['users']),
      warehousesCount: n(j['warehousesCount'] ?? j['warehouses']),
      ordersCount: n(j['ordersCount'] ?? j['orders']),
      createdAt: DateTime.tryParse('${j['createdAt'] ?? ''}'),
    );
  }
}

class PlatformCompaniesService {
  final ApiClient _client;
  const PlatformCompaniesService({ApiClient? client})
      : _client = client ?? const ApiClient();

  Future<List<PlatformCompany>> list({String? search}) async {
    final qp = <String, String>{};
    if (search != null && search.trim().isNotEmpty) {
      qp['search'] = search.trim();
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/platform/companies')
        .replace(queryParameters: qp.isEmpty ? null : qp);
    final res = await _client.get(uri);
    final body = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(body is Map ? (body['message'] ?? body) : 'Companies failed');
    }
    final data = body is Map ? body['data'] : body;
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => PlatformCompany.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> setActive(String id, bool isActive) async {
    final res = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/platform/companies/$id/active'),
      body: jsonEncode({'isActive': isActive}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final body = jsonDecode(res.body);
      throw Exception(body is Map ? body['message'] : 'Update failed');
    }
  }
}
