import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class PlatformCompany {
  final String id;
  final String name;
  final String? code;
  final String status;
  final int userCount;
  final int activeUserCount;
  final int warehouseCount;
  final String? planName;
  final String? planCode;
  final String? subscriptionStatus;
  final String createdAt;
  final String? gstin;
  final String? billingEmail;
  final String? billingPhone;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final int storageUsedBytes;
  final int? storageQuotaBytes;
  final int orderCountThisMonth;
  final int revenuePaise;
  final int planRevenuePaise;
  final int topupRevenuePaise;
  final int? planPricePaise;
  final int? includedScans;
  final int? maxWarehouses;
  final int? maxOperators;
  final int walletBalance;
  final int walletAllocated;
  final int walletConsumed;
  final List<PlatformCompanyActivity> recentActivity;

  const PlatformCompany({
    required this.id,
    required this.name,
    this.code,
    required this.status,
    required this.userCount,
    required this.activeUserCount,
    required this.warehouseCount,
    this.planName,
    this.planCode,
    this.subscriptionStatus,
    required this.createdAt,
    this.gstin,
    this.billingEmail,
    this.billingPhone,
    this.address,
    this.city,
    this.state,
    this.country,
    required this.storageUsedBytes,
    this.storageQuotaBytes,
    required this.orderCountThisMonth,
    required this.revenuePaise,
    required this.planRevenuePaise,
    required this.topupRevenuePaise,
    this.planPricePaise,
    this.includedScans,
    this.maxWarehouses,
    this.maxOperators,
    required this.walletBalance,
    required this.walletAllocated,
    required this.walletConsumed,
    required this.recentActivity,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  String get region => state?.trim().isNotEmpty == true ? state! : 'All';

  factory PlatformCompany.fromJson(Map<String, dynamic> json) {
    int n(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    int? nullableInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse('$value');
    }

    final rawActivity = json['recentActivity'];

    return PlatformCompany(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Company',
      code: json['code']?.toString(),
      status: json['status']?.toString() ?? 'INACTIVE',
      userCount: n(json['userCount']),
      activeUserCount: n(json['activeUserCount']),
      warehouseCount: n(json['warehouseCount']),
      planName: json['planName']?.toString(),
      planCode: json['planCode']?.toString(),
      subscriptionStatus: json['subscriptionStatus']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      gstin: json['gstin']?.toString(),
      billingEmail: json['billingEmail']?.toString(),
      billingPhone: json['billingPhone']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      storageUsedBytes: n(json['storageUsedBytes']),
      storageQuotaBytes: nullableInt(json['storageQuotaBytes']),
      orderCountThisMonth: n(json['orderCountThisMonth']),
      revenuePaise: n(json['revenuePaise']),
      planRevenuePaise: n(json['planRevenuePaise']),
      topupRevenuePaise: n(json['topupRevenuePaise']),
      planPricePaise: nullableInt(json['planPricePaise']),
      includedScans: nullableInt(json['includedScans']),
      maxWarehouses: nullableInt(json['maxWarehouses']),
      maxOperators: nullableInt(json['maxOperators']),
      walletBalance: n(json['walletBalance']),
      walletAllocated: n(json['walletAllocated']),
      walletConsumed: n(json['walletConsumed']),
      recentActivity: rawActivity is List
          ? rawActivity
              .whereType<Map>()
              .map(
                (e) => PlatformCompanyActivity.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class PlatformCompanyActivity {
  final String id;
  final String action;
  final String? description;
  final String? userName;
  final String createdAt;

  const PlatformCompanyActivity({
    required this.id,
    required this.action,
    this.description,
    this.userName,
    required this.createdAt,
  });

  factory PlatformCompanyActivity.fromJson(Map<String, dynamic> json) {
    return PlatformCompanyActivity(
      id: json['id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      description: json['description']?.toString(),
      userName: json['userName']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class PlatformCompaniesSummary {
  final int totalCompanies;
  final int activeCompanies;
  final int inactiveCompanies;
  final int trialCompanies;
  final int totalRevenuePaise;

  const PlatformCompaniesSummary({
    required this.totalCompanies,
    required this.activeCompanies,
    required this.inactiveCompanies,
    required this.trialCompanies,
    required this.totalRevenuePaise,
  });

  factory PlatformCompaniesSummary.fromJson(Map<String, dynamic> json) {
    int n(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    return PlatformCompaniesSummary(
      totalCompanies: n(json['totalCompanies']),
      activeCompanies: n(json['activeCompanies']),
      inactiveCompanies: n(json['inactiveCompanies']),
      trialCompanies: n(json['trialCompanies']),
      totalRevenuePaise: n(json['totalRevenuePaise']),
    );
  }
}

class PlatformCompaniesPage {
  final int page;
  final int limit;
  final int total;
  final int pages;
  final PlatformCompaniesSummary summary;
  final List<String> plans;
  final List<String> regions;
  final List<PlatformCompany> items;

  const PlatformCompaniesPage({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
    required this.summary,
    required this.plans,
    required this.regions,
    required this.items,
  });

  factory PlatformCompaniesPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final rawSummary = json['summary'];

    return PlatformCompaniesPage(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
      pages: (json['pages'] as num?)?.toInt() ?? 1,
      summary: PlatformCompaniesSummary.fromJson(
        rawSummary is Map
            ? Map<String, dynamic>.from(rawSummary)
            : const <String, dynamic>{},
      ),
      plans: (json['filterOptions'] is Map &&
              (json['filterOptions'] as Map)['plans'] is List)
          ? ((json['filterOptions'] as Map)['plans'] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
          : const [],
      regions: (json['filterOptions'] is Map &&
              (json['filterOptions'] as Map)['regions'] is List)
          ? ((json['filterOptions'] as Map)['regions'] as List)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList()
          : const [],
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (e) => PlatformCompany.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class PlatformCompaniesService {
  final ApiClient _client;

  const PlatformCompaniesService({ApiClient? client})
      : _client = client ?? const ApiClient();

  Future<PlatformCompaniesPage> list({
    String search = '',
    String status = 'all',
    String plan = '',
    String region = '',
    int page = 1,
    int limit = 10,
  }) async {
    final qs = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (search.trim().isNotEmpty) 'search': search.trim(),
      if (status != 'all') 'status': status,
      if (plan.trim().isNotEmpty && plan != 'All') 'plan': plan.trim(),
      if (region.trim().isNotEmpty && region != 'All') 'region': region.trim(),
    };

    final uri = Uri.parse('${ApiConfig.baseUrl}/platform/companies')
        .replace(queryParameters: qs);

    final response = await _client.get(uri);
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Unable to load companies.');
    }

    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['data'] is! Map) {
      throw Exception('Invalid companies response.');
    }

    return PlatformCompaniesPage.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<PlatformCompany> get(String id) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/platform/companies/$id'),
    );
    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Unable to load company.');
    }

    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['data'] is! Map) {
      throw Exception('Invalid company response.');
    }

    return PlatformCompany.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }

  Future<void> setActive(String id, bool isActive) async {
    final response = await _client.patch(
      Uri.parse('${ApiConfig.baseUrl}/platform/companies/$id/status'),
      body: {'isActive': isActive},
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'Unable to update company.');
    }
  }
}