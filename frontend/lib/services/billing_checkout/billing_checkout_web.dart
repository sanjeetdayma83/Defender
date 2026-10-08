import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('openLossDefenderRazorpay')
external void _openLossDefenderRazorpay(
  JSString payloadJson,
  JSFunction onSuccess,
  JSFunction onFailure,
);

Future<Map<String, dynamic>?> openRazorpayCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String currency,
  required String name,
  required String description,
  required String email,
  required String phone,
}) {
  final completer = Completer<Map<String, dynamic>?>();

  final success = ((JSString value) {
    try {
      final decoded = jsonDecode(value.toDart);

      if (!completer.isCompleted) {
        completer.complete(
          decoded is Map ? Map<String, dynamic>.from(decoded) : null,
        );
      }
    } catch (error) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
  }).toJS;

  final failure = ((JSString value) {
    if (!completer.isCompleted) {
      completer.completeError(Exception(value.toDart));
    }
  }).toJS;

  _openLossDefenderRazorpay(
    jsonEncode({
      'keyId': keyId,
      'orderId': orderId,
      'amountPaise': amountPaise,
      'currency': currency,
      'name': name,
      'description': description,
      'email': email,
      'phone': phone,
    }).toJS,
    success,
    failure,
  );

  return completer.future;
}

Future<void> openExternalUrl(String url) async {
  web.window.open(url, '_blank');
}
