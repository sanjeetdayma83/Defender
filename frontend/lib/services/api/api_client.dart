import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  const ApiClient();

  Future<String> _getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('User is not authenticated.');
    }

    final token = await user.getIdToken();

    if (token == null || token.isEmpty) {
      throw Exception('Unable to obtain Firebase authentication token.');
    }

    return token;
  }

  Future<Map<String, String>> _headers({
    Map<String, String>? additional,
  }) async {
    final token = await _getIdToken();

    return <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      ...?additional,
    };
  }

  Object? _encodeBody(Object? body) {
    if (body == null) {
      return null;
    }

    if (body is String) {
      return body;
    }

    return jsonEncode(body);
  }

  Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    return http.get(
      uri,
      headers: await _headers(additional: headers),
    );
  }

  Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http.post(
      uri,
      headers: await _headers(
        additional: <String, String>{
          'Content-Type': 'application/json',
          ...?headers,
        },
      ),
      body: _encodeBody(body),
    );
  }

  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http.put(
      uri,
      headers: await _headers(
        additional: <String, String>{
          'Content-Type': 'application/json',
          ...?headers,
        },
      ),
      body: _encodeBody(body),
    );
  }

  Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    return http.delete(
      uri,
      headers: await _headers(additional: headers),
    );
  }

  Future<http.StreamedResponse> sendMultipart(
    http.MultipartRequest request,
  ) async {
    final token = await _getIdToken();

    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';

    return request.send();
  }

  Future<Uint8List> getBytes(Uri uri) async {
    final response = await get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Request failed (${response.statusCode}): ${response.body}',
      );
    }

    return response.bodyBytes;
  }

  Future<Map<String, dynamic>> getJson(Uri uri) async {
    final response = await get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Request failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid JSON response.');
    }

    return decoded;
  }
}
