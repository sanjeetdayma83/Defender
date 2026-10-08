import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class OnboardingService {
  final ApiClient _apiClient;

  OnboardingService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  Future<Map<String, dynamic>> getStatus() async {
    final response = await _apiClient.get(
      Uri.parse('${ApiConfig.baseUrl}/onboarding'),
    );

    return _decode(response, 'Unable to load onboarding status.');
  }

  Future<Map<String, dynamic>> complete({
    required String name,
    required String phone,
    required String companyName,
    required String address,
    required String city,
    required String state,
    required String pin,
    required String warehouseName,
    required String warehouseCode,
  }) async {
    final response = await _apiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/onboarding/complete'),
      body: jsonEncode(<String, dynamic>{
        'name': name,
        'phone': phone,
        'companyName': companyName,
        'address': address,
        'city': city,
        'state': state,
        'pin': pin,
        'warehouseName': warehouseName,
        'warehouseCode': warehouseCode,
      }),
    );

    return _decode(response, 'Unable to complete company setup.');
  }

  Map<String, dynamic> _decode(dynamic response, String fallback) {
    Map<String, dynamic> decoded = <String, dynamic>{};

    try {
      final raw = jsonDecode(response.body as String);
      if (raw is Map<String, dynamic>) {
        decoded = raw;
      }
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['message']?.toString() ?? fallback);
    }

    if (decoded['success'] != true) {
      throw Exception(decoded['message']?.toString() ?? fallback);
    }

    final data = decoded['data'];

    return data is Map<String, dynamic> ? data : decoded;
  }
}
