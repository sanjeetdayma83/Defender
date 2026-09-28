import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class DashboardMetrics {
  final int orders;
  final int products;
  final int warehouses;
  final int users;
  final int sessions;
  final int evidence;
  final int pendingOrders;
  final int packingOrders;
  final int packedOrders;
  final int activeSessions;

  const DashboardMetrics({
    required this.orders,
    required this.products,
    required this.warehouses,
    required this.users,
    required this.sessions,
    required this.evidence,
    required this.pendingOrders,
    required this.packingOrders,
    required this.packedOrders,
    required this.activeSessions,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    final counts = json['counts'] is Map
        ? Map<String, dynamic>.from(json['counts'] as Map)
        : <String, dynamic>{};

    final orderStatus = json['orderStatus'] is Map
        ? Map<String, dynamic>.from(json['orderStatus'] as Map)
        : <String, dynamic>{};

    int number(dynamic value) => value is num ? value.toInt() : 0;

    return DashboardMetrics(
      orders: number(counts['orders']),
      products: number(counts['products']),
      warehouses: number(counts['warehouses']),
      users: number(counts['users']),
      sessions: number(counts['sessions']),
      evidence: number(counts['evidence']),
      pendingOrders: number(orderStatus['pending']),
      packingOrders: number(orderStatus['packing']),
      packedOrders: number(orderStatus['packed']),
      activeSessions: number(json['activeSessions']),
    );
  }
}

class DashboardData {
  final String companyName;
  final String companyCode;
  final DashboardMetrics metrics;

  const DashboardData({
    required this.companyName,
    required this.companyCode,
    required this.metrics,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final company = json['company'] is Map
        ? Map<String, dynamic>.from(json['company'] as Map)
        : <String, dynamic>{};

    final metricsJson = json['metrics'] is Map
        ? Map<String, dynamic>.from(json['metrics'] as Map)
        : <String, dynamic>{};

    return DashboardData(
      companyName: company['name']?.toString() ?? 'Company',
      companyCode: company['code']?.toString() ?? '',
      metrics: DashboardMetrics.fromJson(metricsJson),
    );
  }
}

class DashboardApiService {
  final ApiClient _apiClient;

  DashboardApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  Future<DashboardData> getCompanyDashboard() async {
    final response = await _apiClient.get(
      Uri.parse('${ApiConfig.baseUrl}/dashboard'),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Unable to load dashboard.');
    }

    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw Exception('Invalid dashboard response.');
    }

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Dashboard data is missing.');
    }

    return DashboardData.fromJson(Map<String, dynamic>.from(data));
  }
}
