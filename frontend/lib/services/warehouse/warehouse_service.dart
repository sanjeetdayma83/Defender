import 'dart:convert';

import '../../models/identity/current_user.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';

class WarehouseStats {
  final String warehouseId;
  final int activeOrders;
  final int activeSessions;
  final int totalOrders;
  final int totalSessions;
  final String status;

  const WarehouseStats({
    required this.warehouseId,
    required this.activeOrders,
    required this.activeSessions,
    required this.totalOrders,
    required this.totalSessions,
    required this.status,
  });

  factory WarehouseStats.fromJson(Map<String, dynamic> json) {
    int number(dynamic value) {
      return value is num ? value.toInt() : 0;
    }

    return WarehouseStats(
      warehouseId: json['warehouseId']?.toString() ?? '',
      activeOrders: number(json['activeOrders']),
      activeSessions: number(json['activeSessions']),
      totalOrders: number(json['totalOrders']),
      totalSessions: number(json['totalSessions']),
      status: json['status']?.toString() ?? 'INACTIVE',
    );
  }
}

class WarehouseService {
  final ApiClient _apiClient;

  WarehouseService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  Future<List<WarehouseInfo>> listWarehouses() async {
    final response = await _apiClient.get(
      Uri.parse('${ApiConfig.baseUrl}/warehouses'),
    );

    final decoded = _decode(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['message']?.toString() ??
            'Unable to load warehouses (${response.statusCode}).',
      );
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ?? 'Unable to load warehouses.',
      );
    }

    final rawData = decoded['data'];

    if (rawData is! List) {
      return const <WarehouseInfo>[];
    }

    return rawData
        .whereType<Map>()
        .map(
          (item) => WarehouseInfo.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<WarehouseInfo> getWarehouse(String warehouseId) async {
    final id = _requireId(warehouseId);

    final response = await _apiClient.get(
      Uri.parse('${ApiConfig.baseUrl}/warehouses/$id'),
    );

    final decoded = _decode(response);

    _throwIfFailed(
      response,
      decoded,
      'Unable to load warehouse.',
    );

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Warehouse data is missing.');
    }

    return WarehouseInfo.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<WarehouseStats> getStats(String warehouseId) async {
    final id = _requireId(warehouseId);

    final response = await _apiClient.get(
      Uri.parse('${ApiConfig.baseUrl}/warehouses/$id/stats'),
    );

    final decoded = _decode(response);

    _throwIfFailed(
      response,
      decoded,
      'Unable to load warehouse statistics.',
    );

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Warehouse statistics are missing.');
    }

    return WarehouseStats.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<WarehouseInfo> createWarehouse({
    required String name,
    required String code,
    String? address,
    String? city,
    String? state,
    String? country,
  }) async {
    final response = await _apiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/warehouses'),
      body: <String, dynamic>{
        'name': name,
        'code': code,
        'address': ?address,
        'city': ?city,
        'state': ?state,
        'country': ?country,
      },
    );

    final decoded = _decode(response);

    _throwIfFailed(
      response,
      decoded,
      'Unable to create warehouse.',
    );

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Created warehouse data is missing.');
    }

    return WarehouseInfo.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<WarehouseInfo> updateWarehouse({
    required String warehouseId,
    String? name,
    String? code,
    String? address,
    String? city,
    String? state,
    String? country,
  }) async {
    final id = _requireId(warehouseId);

    final response = await _apiClient.put(
      Uri.parse('${ApiConfig.baseUrl}/warehouses/$id'),
      body: <String, dynamic>{
        'name': ?name,
        'code': ?code,
        'address': ?address,
        'city': ?city,
        'state': ?state,
        'country': ?country,
      },
    );

    final decoded = _decode(response);

    _throwIfFailed(
      response,
      decoded,
      'Unable to update warehouse.',
    );

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Updated warehouse data is missing.');
    }

    return WarehouseInfo.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<WarehouseInfo> setWarehouseStatus({
    required String warehouseId,
    required bool isActive,
  }) async {
    final id = _requireId(warehouseId);

    final response = await _apiClient.patch(
      Uri.parse('${ApiConfig.baseUrl}/warehouses/$id/status'),
      body: <String, dynamic>{
        'isActive': isActive,
      },
    );

    final decoded = _decode(response);

    _throwIfFailed(
      response,
      decoded,
      'Unable to update warehouse status.',
    );

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Updated warehouse data is missing.');
    }

    return WarehouseInfo.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<void> deleteWarehouse(String warehouseId) async {
    final id = _requireId(warehouseId);

    final response = await _apiClient.delete(
      Uri.parse('${ApiConfig.baseUrl}/warehouses/$id'),
    );

    final decoded = _decode(response);

    _throwIfFailed(
      response,
      decoded,
      'Unable to delete warehouse.',
    );
  }

  Map<String, dynamic> _decode(dynamic response) {
    try {
      final raw = jsonDecode(response.body);

      if (raw is Map<String, dynamic>) {
        return raw;
      }

      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  void _throwIfFailed(
    dynamic response,
    Map<String, dynamic> decoded,
    String fallback,
  ) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        decoded['message']?.toString() ??
            '$fallback (${response.statusCode}).',
      );
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ?? fallback,
      );
    }
  }

  String _requireId(String value) {
    final id = value.trim();

    if (id.isEmpty) {
      throw Exception('Warehouse ID is required.');
    }

    return id;
  }
}
