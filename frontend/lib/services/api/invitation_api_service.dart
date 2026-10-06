import 'package:firebase_auth/firebase_auth.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class InvitationApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;

  const InvitationApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  @override
  String toString() => message;
}

class InvitationData {
  final String token;
  final String userId;
  final String email;
  final String name;
  final String role;
  final String companyId;
  final String companyName;
  final String warehouseId;
  final String warehouseName;
  final String warehouseLocation;
  final String expiresAt;

  const InvitationData({
    required this.token,
    this.userId = '',
    this.email = '',
    this.name = '',
    this.role = '',
    this.companyId = '',
    this.companyName = '',
    this.warehouseId = '',
    this.warehouseName = '',
    this.warehouseLocation = '',
    this.expiresAt = '',
  });

  factory InvitationData.fromJson(String token, Map<String, dynamic> json) {
    final invitation = (json['invitation'] is Map)
        ? Map<String, dynamic>.from(json['invitation'] as Map)
        : <String, dynamic>{};

    final company = (json['company'] is Map)
        ? Map<String, dynamic>.from(json['company'] as Map)
        : <String, dynamic>{};

    final warehouse = (json['warehouse'] is Map)
        ? Map<String, dynamic>.from(json['warehouse'] as Map)
        : <String, dynamic>{};

    String value(Map<String, dynamic> map, String key) {
      final v = map[key];
      return v == null ? '' : v.toString();
    }

    return InvitationData(
      token: token,
      userId: value(invitation, 'userId'),
      email: value(invitation, 'email').isNotEmpty
          ? value(invitation, 'email')
          : value(invitation, 'invitedEmail'),
      name: value(invitation, 'userName').isNotEmpty
          ? value(invitation, 'userName')
          : value(invitation, 'name'),
      role: value(invitation, 'role'),
      companyId: value(company, 'id').isNotEmpty
          ? value(company, 'id')
          : value(invitation, 'companyId'),
      companyName: value(company, 'companyName').isNotEmpty
          ? value(company, 'companyName')
          : value(invitation, 'companyName'),
      warehouseId: value(warehouse, 'id').isNotEmpty
          ? value(warehouse, 'id')
          : value(invitation, 'warehouseId'),
      warehouseName: value(warehouse, 'name').isNotEmpty
          ? value(warehouse, 'name')
          : value(invitation, 'warehouseName'),
      warehouseLocation: [
        value(warehouse, 'city'),
        value(warehouse, 'state'),
      ].where((e) => e.isNotEmpty).join(', '),
      expiresAt: value(invitation, 'expiresAt').isNotEmpty
          ? value(invitation, 'expiresAt')
          : value(json, 'expiresAt'),
    );
  }
}

class InvitationApiService {
  InvitationApiService._();

  static final InvitationApiService instance = InvitationApiService._();

  Future<InvitationData> getInvitation(String token) async {
    final cleanToken = token.trim();

    if (cleanToken.isEmpty) {
      throw const InvitationApiException(
        statusCode: 400,
        code: 'INVALID_INVITATION',
        message: 'This invitation link is invalid.',
      );
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/invitations/${Uri.encodeComponent(cleanToken)}',
      ),
      headers: const {'Accept': 'application/json'},
    );

    final body = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InvitationApiException(
        statusCode: response.statusCode,
        code: _errorCode(body),
        message: _errorMessage(response.statusCode, body),
      );
    }

    return InvitationData.fromJson(cleanToken, body);
  }

  Future<Map<String, dynamic>> acceptInvitation({required String token}) async {
    final response = await _authenticatedPost(
      '${ApiConfig.baseUrl}/invitations/${Uri.encodeComponent(token)}/accept',
    );

    final body = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InvitationApiException(
        statusCode: response.statusCode,
        code: _errorCode(body),
        message: _errorMessage(response.statusCode, body),
      );
    }

    return body;
  }

  Future<http.Response> _authenticatedPost(String url) async {
    final user = await _currentFirebaseUser();
    final token = await user.getIdToken();

    return http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: '{}',
    );
  }

  Future<dynamic> _currentFirebaseUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const InvitationApiException(
        statusCode: 401,
        code: 'AUTH_REQUIRED',
        message: 'Please sign in before accepting this invitation.',
      );
    }
    return user;
  }

  Map<String, dynamic> _decode(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}

    return <String, dynamic>{'message': body};
  }

  String _errorCode(Map<String, dynamic> body) {
    final error = body['error'];

    if (error is Map) {
      final value = error['code'];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    for (final key in ['code', 'errorCode', 'type']) {
      final value = body[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    return 'INVITATION_ERROR';
  }

  String _errorMessage(int statusCode, Map<String, dynamic> body) {
    final error = body['error'];

    if (error is Map) {
      final value = error['message'];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }

    for (final key in ['message', 'error']) {
      final value = body[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }

    if (statusCode == 410) {
      return 'This invitation has expired. Please request a new invitation.';
    }

    if (statusCode == 404) {
      return 'This invitation link is invalid or no longer available.';
    }

    return 'Unable to process this invitation. Please try again.';
  }
}
