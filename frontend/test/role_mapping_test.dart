import 'package:flutter_test/flutter_test.dart';

enum CanonicalRole {
  superAdmin,
  support,
  sales,
  techAdmin,
  sellerAdmin,
  warehouseManager,
  claimExecutive,
  packer,
  viewer,
}

CanonicalRole? mapCanonicalRole(String? raw) {
  final role = (raw ?? '')
      .trim()
      .toUpperCase()
      .replaceAll('-', '_');

  switch (role) {
    case 'SUPER_ADMIN':
    case 'PLATFORM_ADMIN':
    case 'PLATFORM':
      return CanonicalRole.superAdmin;

    case 'SUPPORT':
      return CanonicalRole.support;

    case 'SALES':
      return CanonicalRole.sales;

    case 'TECH_ADMIN':
      return CanonicalRole.techAdmin;

    case 'SELLER_ADMIN':
    case 'COMPANY_ADMIN':
    case 'OWNER':
    case 'ADMIN':
      return CanonicalRole.sellerAdmin;

    case 'WAREHOUSE_MANAGER':
    case 'MANAGER':
      return CanonicalRole.warehouseManager;

    case 'CLAIM_EXECUTIVE':
    case 'CLAIMS_EXECUTIVE':
      return CanonicalRole.claimExecutive;

    case 'PACKER':
    case 'PACKING_OPERATOR':
    case 'OPERATOR':
      return CanonicalRole.packer;

    case 'VIEWER':
      return CanonicalRole.viewer;
  }

  return null;
}

void main() {
  group('Canonical Loss Defender role mapping', () {
    final cases = <String, CanonicalRole>{
      'SUPER_ADMIN': CanonicalRole.superAdmin,
      'PLATFORM_ADMIN': CanonicalRole.superAdmin,
      'SUPPORT': CanonicalRole.support,
      'SALES': CanonicalRole.sales,
      'TECH_ADMIN': CanonicalRole.techAdmin,
      'SELLER_ADMIN': CanonicalRole.sellerAdmin,
      'WAREHOUSE_MANAGER': CanonicalRole.warehouseManager,
      'CLAIM_EXECUTIVE': CanonicalRole.claimExecutive,
      'PACKER': CanonicalRole.packer,
      'VIEWER': CanonicalRole.viewer,
    };

    for (final entry in cases.entries) {
      test('${entry.key} maps correctly', () {
        expect(mapCanonicalRole(entry.key), entry.value);
      });
    }

    test('legacy operator aliases map to packer', () {
      expect(
        mapCanonicalRole('OPERATOR'),
        CanonicalRole.packer,
      );

      expect(
        mapCanonicalRole('PACKING_OPERATOR'),
        CanonicalRole.packer,
      );
    });

    test('legacy owner/admin aliases map to seller admin', () {
      expect(
        mapCanonicalRole('OWNER'),
        CanonicalRole.sellerAdmin,
      );

      expect(
        mapCanonicalRole('ADMIN'),
        CanonicalRole.sellerAdmin,
      );
    });

    test('unknown role is rejected', () {
      expect(mapCanonicalRole('UNKNOWN_ROLE'), isNull);
      expect(mapCanonicalRole(null), isNull);
    });

    test('hyphenated role is normalized', () {
      expect(
        mapCanonicalRole('warehouse-manager'),
        CanonicalRole.warehouseManager,
      );
    });
  });
}
