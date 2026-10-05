import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_config.dart';

class PlatformDashboardMetrics {
  final int totalRevenuePaise;
  final int activeSubscriptions;
  final int totalUsers;
  final int totalCompanies;
  final int totalStorageUsedBytes;
  final int totalStorageQuotaBytes;
  final int totalWarehouses;
  final int totalOrders;
  final int totalRecordings;
  final int totalEvidence;

  const PlatformDashboardMetrics({
    required this.totalRevenuePaise,
    required this.activeSubscriptions,
    required this.totalUsers,
    required this.totalCompanies,
    required this.totalStorageUsedBytes,
    required this.totalStorageQuotaBytes,
    required this.totalWarehouses,
    required this.totalOrders,
    required this.totalRecordings,
    required this.totalEvidence,
  });

  factory PlatformDashboardMetrics.fromJson(Map<String, dynamic> json) {
    int n(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    return PlatformDashboardMetrics(
      totalRevenuePaise: n(json['totalRevenuePaise']),
      activeSubscriptions: n(json['activeSubscriptions']),
      totalUsers: n(json['totalUsers']),
      totalCompanies: n(json['totalCompanies']),
      totalStorageUsedBytes: n(json['totalStorageUsedBytes']),
      totalStorageQuotaBytes: n(json['totalStorageQuotaBytes']),
      totalWarehouses: n(json['totalWarehouses']),
      totalOrders: n(json['totalOrders']),
      totalRecordings: n(json['totalRecordings']),
      totalEvidence: n(json['totalEvidence']),
    );
  }

  static const empty = PlatformDashboardMetrics(
    totalRevenuePaise: 0,
    activeSubscriptions: 0,
    totalUsers: 0,
    totalCompanies: 0,
    totalStorageUsedBytes: 0,
    totalStorageQuotaBytes: 0,
    totalWarehouses: 0,
    totalOrders: 0,
    totalRecordings: 0,
    totalEvidence: 0,
  );
}

class PlatformRevenuePoint {
  final String month;
  final int revenuePaise;
  final int paymentCount;

  const PlatformRevenuePoint({
    required this.month,
    required this.revenuePaise,
    required this.paymentCount,
  });

  factory PlatformRevenuePoint.fromJson(Map<String, dynamic> json) {
    int n(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    return PlatformRevenuePoint(
      month: json['month']?.toString() ?? '',
      revenuePaise: n(json['revenuePaise']),
      paymentCount: n(json['paymentCount']),
    );
  }
}

class PlatformGrowthPoint {
  final String month;
  final int value;

  const PlatformGrowthPoint({required this.month, required this.value});

  factory PlatformGrowthPoint.fromJson(
    Map<String, dynamic> json, {
    required String field,
  }) {
    int n(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    return PlatformGrowthPoint(
      month: json['month']?.toString() ?? '',
      value: n(json[field]),
    );
  }
}

class PlatformStatusItem {
  final String status;
  final int count;

  const PlatformStatusItem({required this.status, required this.count});

  factory PlatformStatusItem.fromJson(Map<String, dynamic> json) {
    int n(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    return PlatformStatusItem(
      status: json['status']?.toString() ?? 'unknown',
      count: n(json['count']),
    );
  }
}

class PlatformRecentUser {
  final String id;
  final String name;
  final String email;
  final String companyName;
  final String role;
  final String status;
  final String createdAt;
  final String lastLoginAt;

  const PlatformRecentUser({
    required this.id,
    required this.name,
    required this.email,
    required this.companyName,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory PlatformRecentUser.fromJson(Map<String, dynamic> json) {
    return PlatformRecentUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? 'Platform',
      role: json['role']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      lastLoginAt: json['lastLoginAt']?.toString() ?? '',
    );
  }
}

class PlatformRecentTopup {
  final String id;
  final String companyName;
  final String type;
  final int credits;
  final String createdAt;

  const PlatformRecentTopup({
    required this.id,
    required this.companyName,
    required this.type,
    required this.credits,
    required this.createdAt,
  });

  factory PlatformRecentTopup.fromJson(Map<String, dynamic> json) {
    int n(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    return PlatformRecentTopup(
      id: json['id']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? 'Company',
      type: json['type']?.toString() ?? '',
      credits: n(json['credits']),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class PlatformRecentPayment {
  final String id;
  final String companyName;
  final String status;
  final String plan;
  final int totalPaise;
  final String currency;
  final String createdAt;

  const PlatformRecentPayment({
    required this.id,
    required this.companyName,
    required this.status,
    required this.plan,
    required this.totalPaise,
    required this.currency,
    required this.createdAt,
  });

  factory PlatformRecentPayment.fromJson(Map<String, dynamic> json) {
    int n(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    return PlatformRecentPayment(
      id: json['id']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? 'Company',
      status: json['status']?.toString() ?? '',
      plan: json['plan']?.toString() ?? '',
      totalPaise: n(json['totalPaise']),
      currency: json['currency']?.toString() ?? 'INR',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class PlatformDashboardData {
  final String adminName;
  final String adminEmail;
  final String role;
  final PlatformDashboardMetrics metrics;

  final int revenuePaidPaymentCount;
  final int revenueSubtotalPaise;
  final int revenueGstPaise;
  final int revenueTotalPaise;
  final List<PlatformRevenuePoint> revenueMonthly;

  final List<PlatformGrowthPoint> monthlyUsers;
  final List<PlatformGrowthPoint> monthlySubscriptions;

  final int storageUsedBytes;
  final int storageQuotaBytes;
  final int storageAvailableBytes;

  final int activeSubscriptions;
  final List<PlatformStatusItem> subscriptionStatus;

  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int platformAdmins;
  final int companyAdmins;
  final int operators;

  final int totalCompanies;
  final int activeCompanies;
  final int inactiveCompanies;
  final int newCompaniesThisMonth;

  final int walletBalance;
  final int walletAllocated;
  final int walletConsumed;

  final List<PlatformRecentTopup> recentTopups;
  final List<PlatformRecentUser> recentUsers;
  final List<PlatformRecentPayment> recentPayments;

  final List<PlatformStatusItem> recordingStatus;
  final List<PlatformStatusItem> evidenceStatus;

  const PlatformDashboardData({
    required this.adminName,
    required this.adminEmail,
    required this.role,
    required this.metrics,
    required this.revenuePaidPaymentCount,
    required this.revenueSubtotalPaise,
    required this.revenueGstPaise,
    required this.revenueTotalPaise,
    required this.revenueMonthly,
    required this.monthlyUsers,
    required this.monthlySubscriptions,
    required this.storageUsedBytes,
    required this.storageQuotaBytes,
    required this.storageAvailableBytes,
    required this.activeSubscriptions,
    required this.subscriptionStatus,
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.platformAdmins,
    required this.companyAdmins,
    required this.operators,
    required this.totalCompanies,
    required this.activeCompanies,
    required this.inactiveCompanies,
    required this.newCompaniesThisMonth,
    required this.walletBalance,
    required this.walletAllocated,
    required this.walletConsumed,
    required this.recentTopups,
    required this.recentUsers,
    required this.recentPayments,
    required this.recordingStatus,
    required this.evidenceStatus,
  });

  factory PlatformDashboardData.empty() {
    return const PlatformDashboardData(
      adminName: 'Platform Admin',
      adminEmail: '',
      role: 'PLATFORM_ADMIN',
      metrics: PlatformDashboardMetrics.empty,
      revenuePaidPaymentCount: 0,
      revenueSubtotalPaise: 0,
      revenueGstPaise: 0,
      revenueTotalPaise: 0,
      revenueMonthly: [],
      monthlyUsers: [],
      monthlySubscriptions: [],
      storageUsedBytes: 0,
      storageQuotaBytes: 0,
      storageAvailableBytes: 0,
      activeSubscriptions: 0,
      subscriptionStatus: [],
      totalUsers: 0,
      activeUsers: 0,
      inactiveUsers: 0,
      platformAdmins: 0,
      companyAdmins: 0,
      operators: 0,
      totalCompanies: 0,
      activeCompanies: 0,
      inactiveCompanies: 0,
      newCompaniesThisMonth: 0,
      walletBalance: 0,
      walletAllocated: 0,
      walletConsumed: 0,
      recentTopups: [],
      recentUsers: [],
      recentPayments: [],
      recordingStatus: [],
      evidenceStatus: [],
    );
  }

  factory PlatformDashboardData.fromJson(Map<String, dynamic> root) {
    final user = _map(root['user']);
    final metrics = _map(root['metrics']);
    final revenue = _map(metrics['revenue']);
    final storage = _map(metrics['storage']);
    final subscriptions = _map(metrics['subscriptions']);
    final users = _map(metrics['users']);
    final companies = _map(metrics['companies']);
    final wallet = _map(metrics['wallet']);
    final growth = _map(metrics['growth']);
    final operations = _map(metrics['operations']);

    final kpis = _map(metrics['kpis']);

    int n(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    List<dynamic> list(dynamic value) {
      return value is List ? value : const [];
    }

    return PlatformDashboardData(
      adminName: user['name']?.toString() ?? 'Platform Admin',
      adminEmail: user['email']?.toString() ?? '',
      role: user['role']?.toString() ?? 'PLATFORM_ADMIN',

      metrics: PlatformDashboardMetrics.fromJson(kpis),

      revenuePaidPaymentCount: n(revenue['paidPaymentCount']),
      revenueSubtotalPaise: n(revenue['subtotalPaise']),
      revenueGstPaise: n(revenue['gstPaise']),
      revenueTotalPaise: n(revenue['totalPaise']),

      revenueMonthly: list(revenue['monthly'])
          .whereType<Map>()
          .map(
            (e) => PlatformRevenuePoint.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),

      monthlyUsers: list(growth['monthlyUsers'])
          .whereType<Map>()
          .map(
            (e) => PlatformGrowthPoint.fromJson(
              Map<String, dynamic>.from(e),
              field: 'users',
            ),
          )
          .toList(),

      monthlySubscriptions: list(growth['monthlySubscriptions'])
          .whereType<Map>()
          .map(
            (e) => PlatformGrowthPoint.fromJson(
              Map<String, dynamic>.from(e),
              field: 'subscriptions',
            ),
          )
          .toList(),

      storageUsedBytes: n(storage['usedBytes']),
      storageQuotaBytes: n(storage['quotaBytes']),
      storageAvailableBytes: n(storage['availableBytes']),

      activeSubscriptions: n(subscriptions['active']),
      subscriptionStatus: list(subscriptions['status'])
          .whereType<Map>()
          .map((e) => PlatformStatusItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),

      totalUsers: n(users['total']),
      activeUsers: n(users['active']),
      inactiveUsers: n(users['inactive']),
      platformAdmins: n(users['platformAdmins']),
      companyAdmins: n(users['companyAdmins']),
      operators: n(users['operators']),

      totalCompanies: n(companies['total']),
      activeCompanies: n(companies['active']),
      inactiveCompanies: n(companies['inactive']),
      newCompaniesThisMonth: n(companies['newThisMonth']),

      walletBalance: n(wallet['balance']),
      walletAllocated: n(wallet['lifetimeAllocated']),
      walletConsumed: n(wallet['lifetimeConsumed']),

      recentTopups: list(metrics['recentTopups'])
          .whereType<Map>()
          .map(
            (e) => PlatformRecentTopup.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),

      recentUsers: list(metrics['recentUsers'])
          .whereType<Map>()
          .map((e) => PlatformRecentUser.fromJson(Map<String, dynamic>.from(e)))
          .toList(),

      recentPayments: list(metrics['recentPayments'])
          .whereType<Map>()
          .map(
            (e) => PlatformRecentPayment.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),

      recordingStatus: list(operations['recordingStatus'])
          .whereType<Map>()
          .map((e) => PlatformStatusItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),

      evidenceStatus: list(operations['evidenceStatus'])
          .whereType<Map>()
          .map((e) => PlatformStatusItem.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }
}

class PlatformDashboardService {
  final ApiClient _client;

  const PlatformDashboardService({ApiClient? client})
    : _client = client ?? const ApiClient();

  Future<PlatformDashboardData> fetch() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/dashboard/platform'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Platform dashboard request failed (${response.statusCode})',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map ||
        decoded['success'] != true ||
        decoded['data'] is! Map) {
      throw Exception('Invalid platform dashboard response');
    }

    return PlatformDashboardData.fromJson(
      Map<String, dynamic>.from(decoded['data'] as Map),
    );
  }
}
