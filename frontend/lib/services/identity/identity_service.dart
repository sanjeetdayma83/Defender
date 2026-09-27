import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';

import '../../models/identity/current_user.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';

class IdentityService {
  final ApiClient _apiClient;

  IdentityService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<CurrentUser?> getMe() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    final response = await _apiClient.get(
      Uri.parse('${ApiConfig.baseUrl}/identity/me'),
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Identity request failed '
        '(${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid identity API response.');
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ?? 'Unable to load user identity.',
      );
    }

    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Identity data is missing from API response.');
    }

    return CurrentUser.fromJson(data);
  }

  Future<CurrentUser> bootstrap() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception('Firebase authentication is required.');
    }

    final response = await _apiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/identity/bootstrap'),
      body: {
        'name':
            firebaseUser.displayName ??
            firebaseUser.email?.split('@').first ??
            'User',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Bootstrap request failed '
        '(${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid bootstrap API response.');
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ??
            'Unable to create your Loss Defender profile.',
      );
    }

    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Bootstrap identity data is missing.');
    }

    return CurrentUser.fromJson(data);
  }
}
