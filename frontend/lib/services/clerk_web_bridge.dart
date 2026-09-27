import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('lossDefenderClerk.initialize')
external JSPromise<JSAny?> _initialize(JSString publishableKey);

@JS('lossDefenderClerk.mountSignIn')
external JSPromise<JSAny?> _mountSignIn(web.HTMLElement element);

@JS('lossDefenderClerk.mountSignUp')
external JSPromise<JSAny?> _mountSignUp(web.HTMLElement element);

@JS('lossDefenderClerk.unmount')
external JSPromise<JSAny?> _unmount(web.HTMLElement element);

@JS('lossDefenderClerk.isSignedIn')
external JSBoolean _isSignedIn();

@JS('lossDefenderClerk.getToken')
external JSPromise<JSString?> _getToken();

@JS('lossDefenderClerk.signOut')
external JSPromise<JSAny?> _signOut();

class ClerkWebBridge {
  const ClerkWebBridge._();

  static Future<void> initialize(String publishableKey) async {
    await _initialize(publishableKey.toJS).toDart;
  }

  static Future<void> mountSignIn(web.HTMLElement element) async {
    await _mountSignIn(element).toDart;
  }

  static Future<void> mountSignUp(web.HTMLElement element) async {
    await _mountSignUp(element).toDart;
  }

  static Future<void> unmount(web.HTMLElement element) async {
    await _unmount(element).toDart;
  }

  static bool get isSignedIn => _isSignedIn().toDart;

  static Future<String?> getToken() async {
    final token = await _getToken().toDart;

    if (token == null) {
      return null;
    }

    return token.toDart;
  }

  static Future<void> signOut() async {
    await _signOut().toDart;
  }
}
