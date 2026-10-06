import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class WalletTransaction {
  final String id;
  final String type;
  final int credits;
  final int balanceAfter;
  final String? referenceType;
  final String? referenceId;
  final String? description;
  final DateTime? createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.credits,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.description,
    this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toInt() ?? 0,
      referenceType: json['referenceType']?.toString(),
      referenceId: json['referenceId']?.toString(),
      description: json['description']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class WalletData {
  final String id;
  final String companyId;
  final int balance;
  final int lifetimeAllocated;
  final int lifetimeConsumed;
  final List<WalletTransaction> transactions;

  const WalletData({
    required this.id,
    required this.companyId,
    required this.balance,
    required this.lifetimeAllocated,
    required this.lifetimeConsumed,
    required this.transactions,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    final rawTransactions = json['transactions'];

    final transactions = rawTransactions is List
        ? rawTransactions
              .whereType<Map>()
              .map(
                (item) =>
                    WalletTransaction.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <WalletTransaction>[];

    return WalletData(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      lifetimeAllocated: (json['lifetimeAllocated'] as num?)?.toInt() ?? 0,
      lifetimeConsumed: (json['lifetimeConsumed'] as num?)?.toInt() ?? 0,
      transactions: transactions,
    );
  }
}

class WalletApiService {
  final ApiClient _apiClient;

  WalletApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? const ApiClient();

  Future<WalletData> getWallet() async {
    final response = await _apiClient.get(
      Uri.parse('${ApiConfig.baseUrl}/wallet'),
    );

    final decoded = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded?['message']?.toString();

      throw Exception(message ?? 'Unable to load scan wallet.');
    }

    if (decoded == null || decoded['success'] != true) {
      throw Exception('Invalid wallet response.');
    }

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Wallet data is missing.');
    }

    return WalletData.fromJson(Map<String, dynamic>.from(data));
  }

  Future<WalletData> consumeCredits({
    required int credits,
    required String idempotencyKey,
    String? referenceType,
    String? referenceId,
    String? description,
  }) async {
    final response = await _apiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/wallet/consume'),
      body: jsonEncode(<String, dynamic>{
        'credits': credits,
        'idempotencyKey': idempotencyKey,
        'referenceType': ?referenceType,
        'referenceId': ?referenceId,
        'description': ?description,
      }),
    );

    final decoded = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded?['message']?.toString();

      throw Exception(message ?? 'Unable to consume scan credits.');
    }

    if (decoded == null || decoded['success'] != true) {
      throw Exception('Invalid wallet consume response.');
    }

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Wallet consume data is missing.');
    }

    return WalletData.fromJson(Map<String, dynamic>.from(data));
  }

  Future<WalletData> topUp({
    required int credits,
    required String idempotencyKey,
    String? referenceType,
    String? referenceId,
    String? description,
  }) async {
    final response = await _apiClient.post(
      Uri.parse('${ApiConfig.baseUrl}/wallet/top-up'),
      body: jsonEncode(<String, dynamic>{
        'credits': credits,
        'idempotencyKey': idempotencyKey,
        'referenceType': ?referenceType,
        'referenceId': ?referenceId,
        'description': ?description,
      }),
    );

    final decoded = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded?['message']?.toString();

      throw Exception(message ?? 'Unable to top up scan credits.');
    }

    if (decoded == null || decoded['success'] != true) {
      throw Exception('Invalid wallet top-up response.');
    }

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('Wallet top-up data is missing.');
    }

    return WalletData.fromJson(Map<String, dynamic>.from(data));
  }

  Map<String, dynamic>? _decode(String body) {
    try {
      final raw = jsonDecode(body);

      if (raw is Map<String, dynamic>) {
        return raw;
      }

      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
    } catch (_) {}

    return null;
  }
}
