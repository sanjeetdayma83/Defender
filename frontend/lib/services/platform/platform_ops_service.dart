import 'dart:convert';
import '../api/api_client.dart';
import '../api/api_config.dart';

class PlatformOpsService {
  final ApiClient _c;
  const PlatformOpsService({ApiClient? client})
    : _c = client ?? const ApiClient();

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? q,
  ]) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}$path',
    ).replace(queryParameters: q);
    final res = await _c.get(uri);
    final decoded = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = decoded is Map ? decoded['message'] : null;
      throw Exception(msg ?? 'Request failed (${res.statusCode})');
    }
    if (decoded is! Map || decoded['success'] != true) {
      throw Exception('Invalid response');
    }
    final data = decoded['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, [
    Object? body,
  ]) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final res = method == 'POST'
        ? await _c.post(uri, body: body)
        : await _c.patch(uri, body: body);
    final decoded = jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = decoded is Map ? decoded['message'] : null;
      throw Exception(msg ?? 'Request failed (${res.statusCode})');
    }
    final data = decoded is Map ? decoded['data'] : null;
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> topups() => _get('/platform/topups');
  Future<Map<String, dynamic>> createTopup(Map<String, dynamic> b) =>
      _send('POST', '/platform/topups', b);
  Future<void> setTopupActive(String id, bool active) async {
    await _send('PATCH', '/platform/topups/$id/status', {'isActive': active});
  }

  Future<Map<String, dynamic>> storage() => _get('/platform/storage');
  Future<Map<String, dynamic>> analytics() =>
      _get('/platform/analytics/summary');
  Future<Map<String, dynamic>> auditLogs() => _get('/platform/audit-logs');
  Future<Map<String, dynamic>> settings() => _get('/platform/settings');
  Future<Map<String, dynamic>> saveSettings(Map<String, dynamic> b) =>
      _send('PATCH', '/platform/settings', b);
}
