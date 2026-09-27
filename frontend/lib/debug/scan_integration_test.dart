import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/api/api_client.dart';
import '../services/api/api_config.dart';

class ScanIntegrationTest {
  static const ApiClient _api = ApiClient();

  static Future<void> run() async {
    debugPrint('');
    debugPrint('============================================================');
    debugPrint(' LOSS DEFENDER - REAL SCAN LOOKUP INTEGRATION TEST');
    debugPrint('============================================================');

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint('[FAIL] No Firebase user is currently signed in.');
      return;
    }

    debugPrint('[AUTH] Firebase user: ${user.email}');
    debugPrint('[AUTH] UID: ${user.uid}');

    final tests = <Map<String, String>>[
      <String, String>{'name': 'Amazon AWB', 'barcode': '368275770371'},
      <String, String>{
        'name': 'Delhivery shipping barcode',
        'barcode': '1490841263428112',
      },
      <String, String>{'name': 'Flipkart AWB', 'barcode': 'FMPP3767030215'},
      <String, String>{'name': 'Amazon SKU', 'barcode': '97-U1YR-N3GW'},
      <String, String>{'name': 'Delhivery SKU', 'barcode': 'PC-TWISTER-001'},
      <String, String>{'name': 'Flipkart SKU', 'barcode': 'DG-LT-S'},
      <String, String>{
        'name': 'Invalid barcode',
        'barcode': 'INVALID-LOSS-DEFENDER-999',
      },
    ];

    for (final test in tests) {
      await _runLookup(test['name']!, test['barcode']!);
    }

    await _runUnauthenticatedCheck();

    debugPrint('');
    debugPrint('============================================================');
    debugPrint(' SCAN LOOKUP INTEGRATION TEST COMPLETE');
    debugPrint('============================================================');
  }

  static Future<void> _runLookup(String name, String barcode) async {
    debugPrint('');
    debugPrint('------------------------------------------------------------');
    debugPrint('[TEST] $name');
    debugPrint('[INPUT] $barcode');

    try {
      final response = await _api.post(
        Uri.parse('${ApiConfig.baseUrl}/scan/lookup'),
        body: jsonEncode(<String, String>{'barcode': barcode}),
      );

      debugPrint('[HTTP] ${response.statusCode}');
      debugPrint('[BODY] ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map<String, dynamic> && decoded['success'] == true) {
          debugPrint('[PASS] Lookup succeeded.');
          _printSummary(decoded);
        } else {
          debugPrint('[FAIL] HTTP success but API success=false.');
        }
        return;
      }

      if (barcode == 'INVALID-LOSS-DEFENDER-999' &&
          response.statusCode == 404) {
        debugPrint('[PASS] Invalid barcode correctly returned 404.');
        return;
      }

      debugPrint('[FAIL] Unexpected HTTP status.');
    } catch (error) {
      debugPrint('[FAIL] Request exception: $error');
    }
  }

  static void _printSummary(Map<String, dynamic> decoded) {
    final data = decoded['data'];

    if (data is! Map<String, dynamic>) {
      debugPrint('[WARN] Response has no data object.');
      return;
    }

    final shipment = data['shipment'];
    final order = data['order'];
    final items = data['items'];

    if (shipment is Map<String, dynamic>) {
      debugPrint(
        '[SHIPMENT] '
        'AWB=${shipment['awb']} '
        'carrier=${shipment['carrier']} '
        'status=${shipment['status']}',
      );
    }

    if (order is Map<String, dynamic>) {
      debugPrint(
        '[ORDER] '
        'external=${order['externalOrderId']} '
        'marketplace=${order['marketplace']} '
        'status=${order['status']}',
      );
    }

    if (items is List) {
      debugPrint('[ITEM COUNT] ${items.length}');

      for (final item in items) {
        if (item is Map<String, dynamic>) {
          debugPrint(
            '[ITEM] '
            'SKU=${item['sku']} '
            'name=${item['productName']} '
            'qty=${item['quantity']}',
          );
        }
      }
    }
  }

  static Future<void> _runUnauthenticatedCheck() async {
    debugPrint('');
    debugPrint('------------------------------------------------------------');
    debugPrint('[TEST] Unauthenticated request');

    debugPrint(
      '[INFO] Authentication is enforced by ApiClient, '
      'so this test requires a direct unauthenticated HTTP request.',
    );

    debugPrint(
      '[INFO] Skipped here to avoid exposing or bypassing Firebase auth.',
    );
  }
}
