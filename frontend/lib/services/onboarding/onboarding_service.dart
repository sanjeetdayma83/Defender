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

  Future<Map<String, dynamic>> updateProfile(String name) async {
    final response = await _apiClient.put(
      Uri.parse('${ApiConfig.baseUrl}/onboarding/profile'),
      body: jsonEncode(<String, dynamic>{'name': name}),
    );

    return _decode(response, 'Unable to update profile.');
  }

  Future<Map<String, dynamic>> updateCompany({
    required String name,
    String? code,
  }) async {
    final response = await _apiClient.put(
      Uri.parse('${ApiConfig.baseUrl}/onboarding/company'),
      body: jsonEncode(<String, dynamic>{
        'name': name,
        if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
      }),
    );

    return _decode(response, 'Unable to update company.');
  }

  Future<Map<String, dynamic>> createWarehouse({
    required String name,
    String? code,
  }) async {
    final response = await _apiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/onboarding/warehouse'),
      body: jsonEncode(<String, dynamic>{
        'name': name,
        if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
      }),
    );

    return _decode(response, 'Unable to create warehouse.');
  }

  Future<Map<String, dynamic>> complete() async {
    final response = await _apiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/onboarding/complete'),
      body: jsonEncode(<String, dynamic>{}),
    );

    return _decode(response, 'Unable to complete onboarding.');
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
