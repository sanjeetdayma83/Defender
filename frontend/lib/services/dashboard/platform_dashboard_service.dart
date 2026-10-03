import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class PlatformDashboardMetrics {
  final int companies;
  final int users;
  final int orders;
  final int sessions;
  final int evidence;
  final int warehouses;

  const PlatformDashboardMetrics({
    required this.companies,
    required this.users,
    required this.orders,
    required this.sessions,
    required this.evidence,
    required this.warehouses,
  });

  factory PlatformDashboardMetrics.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return PlatformDashboardMetrics(
      companies: n(json['companies']),
      users: n(json['users']),
      orders: n(json['orders']),
      sessions: n(json['sessions']),
      evidence: n(json['evidence']),
      warehouses: n(json['warehouses']),
    );
  }

  static const empty = PlatformDashboardMetrics(
    companies: 0,
    users: 0,
    orders: 0,
    sessions: 0,
    evidence: 0,
    warehouses: 0,
  );
}

class PlatformDashboardData {
  final String adminName;
  final String adminEmail;
  final String role;
  final PlatformDashboardMetrics metrics;

  const PlatformDashboardData({
    required this.adminName,
    required this.adminEmail,
    required this.role,
    required this.metrics,
  });

  factory PlatformDashboardData.empty() => const PlatformDashboardData(
        adminName: 'Platform Admin',
        adminEmail: '',
        role: 'PLATFORM_ADMIN',
        metrics: PlatformDashboardMetrics.empty,
      );

  factory PlatformDashboardData.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : <String, dynamic>{};
    final metricsJson = json['metrics'] is Map
        ? Map<String, dynamic>.from(json['metrics'] as Map)
        : <String, dynamic>{};
    return PlatformDashboardData(
      adminName: user['name']?.toString() ?? 'Platform Admin',
      adminEmail: user['email']?.toString() ?? '',
      role: user['role']?.toString() ?? 'PLATFORM_ADMIN',
      metrics: PlatformDashboardMetrics.fromJson(metricsJson),
    );
  }
}

class PlatformDashboardService {
  final ApiClient _client;

  const PlatformDashboardService({ApiClient? client})
      : _client = client ?? const ApiClient();

  /// Soft-fail: 403/404/500/network → empty zeros (no red error UI).
  Future<PlatformDashboardData> fetch() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}/dashboard/platform'),
      );

      // ignore: avoid_print
      print('PLATFORM_DASHBOARD_HTTP=${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return PlatformDashboardData.empty();
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map ||
          decoded['success'] != true ||
          decoded['data'] is! Map) {
        return PlatformDashboardData.empty();
      }

      return PlatformDashboardData.fromJson(
        Map<String, dynamic>.from(decoded['data'] as Map),
      );
    } catch (e) {
      // ignore: avoid_print
      print('PLATFORM_DASHBOARD_ERROR=$e');
      return PlatformDashboardData.empty();
    }
  }
}
