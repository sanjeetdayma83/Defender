import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class CompanyBillingService {
  final ApiClient _api;

  CompanyBillingService({ApiClient? apiClient})
    : _api = apiClient ?? const ApiClient();

  Future<Map<String, dynamic>> wallet() async {
    final response = await _api.get(Uri.parse('${ApiConfig.baseUrl}/wallet'));

    return _decode(response, 'Unable to load scan wallet.');
  }

  Future<Map<String, dynamic>> walletTransactions() async {
    final response = await _api.get(
      Uri.parse('${ApiConfig.baseUrl}/wallet/transactions?limit=100'),
    );

    return _decode(response, 'Unable to load wallet transactions.');
  }

  Future<List<Map<String, dynamic>>> plans() async {
    final response = await _api.get(
      Uri.parse('${ApiConfig.baseUrl}/plans'),
    );

    final decoded = _decode(response, 'Unable to load plans.');
    final raw = decoded['data'] ?? decoded;

    final result = <Map<String, dynamic>>[];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          result.add(Map<String, dynamic>.from(item));
        }
      }
    } else if (raw is Map && raw['items'] is List) {
      final items = raw['items'] as List;

      for (final item in items) {
        if (item is Map) {
          result.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return result;
  }

  Future<Map<String, dynamic>?> subscription() async {
    final response = await _api.get(
      Uri.parse('${ApiConfig.baseUrl}/plans/subscription'),
    );

    final decoded = _decode(response, 'Unable to load current subscription.');

    final data = decoded['data'];

    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<Map<String, dynamic>> createPlanOrder({
    required String planCode,
    required String billingInterval,
  }) async {
    final response = await _api.post(
      Uri.parse('${ApiConfig.baseUrl}/billing/razorpay/order'),
      body: jsonEncode({
        'planCode': planCode,
        'billingInterval': billingInterval,
      }),
    );

    return _decode(response, 'Unable to create payment order.');
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String paymentId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final response = await _api.post(
      Uri.parse('${ApiConfig.baseUrl}/billing/razorpay/verify'),
      body: jsonEncode({
        'paymentId': paymentId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpayOrderId': razorpayOrderId,
        'razorpaySignature': razorpaySignature,
      }),
    );

    return _decode(response, 'Unable to verify payment.');
  }

  Future<Map<String, dynamic>> invoices() async {
    final response = await _api.get(
      Uri.parse('${ApiConfig.baseUrl}/billing/invoices?limit=100'),
    );

    return _decode(response, 'Unable to load invoices.');
  }

  Future<Map<String, dynamic>> invoicePdf(String invoiceId) async {
    final response = await _api.get(
      Uri.parse('${ApiConfig.baseUrl}/billing/invoices/$invoiceId/pdf'),
    );

    return _decode(response, 'Unable to generate invoice PDF.');
  }

  Map<String, dynamic> _decode(dynamic response, String fallback) {
    Map<String, dynamic> decoded = {};

    try {
      final value = jsonDecode(response.body as String);
      if (value is Map<String, dynamic>) {
        decoded = value;
      }
    } catch (_) {}

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['message']?.toString() ?? fallback);
    }

    if (decoded['success'] != true) {
      throw Exception(decoded['message']?.toString() ?? fallback);
    }

    return decoded;
  }

  int money(dynamic paise) {
    if (paise is num) {
      return paise.toInt();
    }

    return int.tryParse(paise?.toString() ?? '') ?? 0;
  }
}
