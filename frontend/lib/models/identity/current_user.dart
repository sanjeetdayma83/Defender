class CurrentUser {
  final String id;
  final String firebaseUid;
  final String email;
  final String name;
  final String role;
  final bool isActive;

  final CompanyInfo? company;
  final WarehouseInfo? warehouse;

  const CurrentUser({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    this.company,
    this.warehouse,
  });

  bool get isPlatformAdmin => role == 'PLATFORM_ADMIN';
  bool get isOwner => role == 'OWNER';
  bool get isAdmin => role == 'ADMIN';
  bool get isManager => role == 'MANAGER';
  bool get isOperator => role == 'OPERATOR';
  bool get isViewer => role == 'VIEWER';

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['id']?.toString() ?? '',
      firebaseUid: json['firebaseUid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'VIEWER',
      isActive: json['isActive'] == true,
      company: json['company'] is Map<String, dynamic>
          ? CompanyInfo.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      warehouse: json['warehouse'] is Map<String, dynamic>
          ? WarehouseInfo.fromJson(json['warehouse'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CompanyInfo {
  final String id;
  final String name;
  final String code;

  const CompanyInfo({required this.id, required this.name, required this.code});

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}

class WarehouseInfo {
  final String id;
  final String name;
  final String code;
  final bool isActive;

  const WarehouseInfo({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
  });

  factory WarehouseInfo.fromJson(Map<String, dynamic> json) {
    return WarehouseInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      isActive: json['isActive'] == true,
    );
  }
}
