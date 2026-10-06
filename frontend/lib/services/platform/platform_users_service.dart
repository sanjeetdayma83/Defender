import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class PlatformUser {
  final String id;
  final String email;
  final String? name;
  final String role;
  final String status;
  final String? companyId;
  final String? companyName;
  final String createdAt;

  const PlatformUser({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.status,
    this.companyId,
    this.companyName,
    required this.createdAt,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory PlatformUser.fromJson(Map<String, dynamic> json) {
    return PlatformUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
      role: json['role']?.toString() ?? 'OPERATOR',
      status: json['status']?.toString() ?? 'ACTIVE',
      companyId: json['companyId']?.toString(),
      companyName: json['companyName']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class PlatformUsersService {
  final ApiClient _client;
  const PlatformUsersService({ApiClient? client})
    : _client = client ?? const ApiClient();

  Future<({int total, List<PlatformUser> items})> list({
    String search = '',
    String status = 'all',
    String role = '',
  }) async {
    final qs = <String, String>{
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (status != 'all') 'status': status,
      if (role.trim().isNotEmpty) 'role': role.trim(),
      'limit': '100',
    };
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/platform/users',
    ).replace(queryParameters: qs);

    final response = await _client.get(uri);
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(msg ?? 'Unable to load users.');
    }

    if (decoded is! Map || decoded['success'] != true) {
      throw Exception('Invalid users response.');
    }

    final data = decoded['data'];
    if (data is! Map) {
      return (total: 0, items: <PlatformUser>[]);
    }

    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((e) => PlatformUser.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <PlatformUser>[];

    final total = data['total'] is num
        ? (data['total'] as num).toInt()
        : items.length;

    return (total: total, items: items);
  }

  Future<void> setActive(String id, bool isActive) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/platform/users/$id/status');
    final response = await _client.patch(uri, body: {'isActive': isActive});
    final decoded = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(msg ?? 'Unable to update user.');
    }
  }
}
