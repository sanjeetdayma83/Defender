class ScannerDeviceInfo {
  final String name;
  final int vendorId;
  final int productId;
  final bool opened;

  const ScannerDeviceInfo({
    required this.name,
    required this.vendorId,
    required this.productId,
    required this.opened,
  });
}

class ScannerService {
  Future<bool> isWebHidAvailable() async {
    return false;
  }

  Future<List<ScannerDeviceInfo>> getAuthorizedDevices() async {
    return [];
  }

  Future<List<ScannerDeviceInfo>> requestDevice() async {
    throw UnsupportedError(
      'WebHID is available only on supported web browsers.',
    );
  }
}
