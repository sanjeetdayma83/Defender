Future<Map<String, dynamic>?> openRazorpayCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String currency,
  required String name,
  required String description,
  required String email,
  required String phone,
}) async {
  throw UnsupportedError('Razorpay checkout is available in the web client.');
}

Future<void> openExternalUrl(String url) async {
  throw UnsupportedError(
    'External URL opening is available in the web client.',
  );
}
