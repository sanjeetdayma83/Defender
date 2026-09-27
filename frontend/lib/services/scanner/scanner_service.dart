import 'package:web_hid/web_hid.dart';

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
    try {
      return canUseHid();
    } catch (_) {
      return false;
    }
  }

  Future<List<ScannerDeviceInfo>> getAuthorizedDevices() async {
    final available = await isWebHidAvailable();

    if (!available) {
      return [];
    }

    try {
      final devices = await hid.getDevices();

      return devices.map((device) {
        final name = device.getProperty<String>('productName');
        final vendorId = device.getProperty<int>('vendorId');
        final productId = device.getProperty<int>('productId');

        return ScannerDeviceInfo(
          name: name.isEmpty ? 'Unknown HID Device' : name,
          vendorId: vendorId,
          productId: productId,
          opened: device.opened,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<ScannerDeviceInfo>> requestDevice() async {
    final available = await isWebHidAvailable();

    if (!available) {
      throw Exception('WebHID is not available in this browser/context.');
    }

    final devices = await hid.requestDevice(RequestOptions(filters: const []));

    return devices.map((device) {
      final name = device.getProperty<String>('productName');
      final vendorId = device.getProperty<int>('vendorId');
      final productId = device.getProperty<int>('productId');

      return ScannerDeviceInfo(
        name: name.isEmpty ? 'Unknown HID Device' : name,
        vendorId: vendorId,
        productId: productId,
        opened: device.opened,
      );
    }).toList();
  }
}
