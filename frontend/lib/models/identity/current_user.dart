class CurrentUser {
  final String id;
  final String firebaseUid;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final CompanyInfo? company;
  final List<WarehouseInfo> warehouses;

  const CurrentUser({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    this.company,
    this.warehouses = const <WarehouseInfo>[],
  });

  WarehouseInfo? get primaryWarehouse =>
      warehouses.isEmpty ? null : warehouses.first;

  bool get isPlatformAdmin {
    final r = role.trim().toUpperCase().replaceAll('-', '_');
    return r == 'PLATFORM_ADMIN' || r == 'SUPER_ADMIN';
  }

  bool get isOwner => role == 'OWNER';
  bool get isAdmin => role == 'ADMIN';
  bool get isManager => role == 'MANAGER';
  bool get isOperator => role == 'OPERATOR';
  bool get isViewer => role == 'VIEWER';

  WarehouseInfo? get warehouse => primaryWarehouse;

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    final rawWarehouses = json['warehouses'];
    final warehouses = rawWarehouses is List
        ? rawWarehouses
              .whereType<Map>()
              .map(
                (item) =>
                    WarehouseInfo.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <WarehouseInfo>[];

    // Backward compatibility for an older single-warehouse response.
    if (warehouses.isEmpty && json['warehouse'] is Map) {
      warehouses.add(
        WarehouseInfo.fromJson(
          Map<String, dynamic>.from(json['warehouse'] as Map),
        ),
      );
    }

    return CurrentUser(
      id: json['id']?.toString() ?? '',
      firebaseUid: json['firebaseUid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'VIEWER',
      isActive: json['isActive'] == true,
      company: json['company'] is Map
          ? CompanyInfo.fromJson(
              Map<String, dynamic>.from(json['company'] as Map),
            )
          : null,
      warehouses: warehouses,
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
