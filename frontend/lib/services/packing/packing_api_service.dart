import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class PackingSession {
  final String id;
  final String status;
  final String awb;

  const PackingSession({
    required this.id,
    required this.status,
    required this.awb,
  });

  factory PackingSession.fromJson(Map<String, dynamic> json) {
    final shipment = json['shipment'];

    return PackingSession(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      awb: shipment is Map
          ? shipment['awb']?.toString() ?? ''
          : json['awb']?.toString() ?? '',
    );
  }
}

class PackingApiService {
  final ApiClient _apiClient;

  PackingApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  Future<PackingSession> startPacking({
    required String awb,
    required String warehouseId,
  }) async {
    final cleanAwb = awb.trim();
    final cleanWarehouseId = warehouseId.trim();

    if (cleanAwb.isEmpty) {
      throw Exception('AWB is required.');
    }

    if (cleanWarehouseId.isEmpty) {
      throw Exception('Warehouse ID is required.');
    }

    final response = await _apiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/packing'),
      body: <String, dynamic>{'awb': cleanAwb, 'warehouseId': cleanWarehouseId},
    );

    final decoded = _decode(response);

    _checkSuccess(
      response.statusCode,
      decoded,
      fallback: 'Unable to start packing',
    );

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Packing session data is missing.');
    }

    final session = PackingSession.fromJson(Map<String, dynamic>.from(data));

    if (session.id.isEmpty) {
      throw Exception('Packing session ID is missing.');
    }

    return session;
  }

  Future<PackingSession> completePacking({required String sessionId}) async {
    final id = sessionId.trim();

    if (id.isEmpty) {
      throw Exception('Packing session ID is required.');
    }

    final response = await _apiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/packing/$id/complete'),
    );

    final decoded = _decode(response);

    _checkSuccess(
      response.statusCode,
      decoded,
      fallback: 'Unable to complete packing',
    );

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Completed packing session data is missing.');
    }

    return PackingSession.fromJson(Map<String, dynamic>.from(data));
  }

  Future<PackingSession> cancelPacking({required String sessionId}) async {
    final id = sessionId.trim();

    if (id.isEmpty) {
      throw Exception('Packing session ID is required.');
    }

    final response = await _apiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/packing/$id/cancel'),
    );

    final decoded = _decode(response);

    _checkSuccess(
      response.statusCode,
      decoded,
      fallback: 'Unable to cancel packing',
    );

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Cancelled packing session data is missing.');
    }

    return PackingSession.fromJson(Map<String, dynamic>.from(data));
  }

  Map<String, dynamic> _decode(dynamic response) {
    try {
      final raw = jsonDecode(response.body);

      if (raw is Map<String, dynamic>) {
        return raw;
      }
    } catch (_) {}

    return <String, dynamic>{};
  }

  void _checkSuccess(
    int statusCode,
    Map<String, dynamic> decoded, {
    required String fallback,
  }) {
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(
        decoded['message']?.toString() ?? '$fallback ($statusCode).',
      );
    }

    if (decoded['success'] != true) {
      throw Exception(decoded['message']?.toString() ?? '$fallback.');
    }
  }
}
