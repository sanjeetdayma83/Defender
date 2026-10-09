class CameraDeviceInfo {
  final String deviceId;
  final String label;
  final String groupId;

  const CameraDeviceInfo({
    required this.deviceId,
    required this.label,
    required this.groupId,
  });

  String get displayName {
    if (label.trim().isEmpty) {
      if (deviceId.isEmpty) return 'Camera';
      final shortId = deviceId.length > 8 ? deviceId.substring(0, 8) : deviceId;
      return 'Camera $shortId';
    }
    return label;
  }

  @override
  String toString() => 'CameraDeviceInfo(deviceId: $deviceId, label: $label)';
}

class RecordingResult {
  final String filename;
  final String mimeType;
  final int sizeBytes;
  final int durationMs;
  final String objectUrl;

  const RecordingResult({
    required this.filename,
    required this.mimeType,
    required this.sizeBytes,
    required this.durationMs,
    required this.objectUrl,
  });
}

/// Non-web implementation.
///
/// Browser MediaRecorder APIs are isolated in the web implementation so
/// Flutter VM/test targets never load dart:js_interop.
class CameraRecordingService {
  bool get isRecording => false;

  Future<bool> isSupported() async => false;

  Future<List<CameraDeviceInfo>> getCameras() async => const [];

  Future<Object> openCamera({
    String? deviceId,
    int width = 1280,
    int height = 720,
  }) {
    throw UnsupportedError(
      'Camera recording is only supported on Flutter Web.',
    );
  }

  dynamic get stream => null;

  Future<void> stopPreview() async {}

  Future<bool> startRecording() async => false;

  Future<RecordingResult?> stopRecording({required String identifier}) async =>
      null;

  void downloadRecording(RecordingResult recording) {
    throw UnsupportedError(
      'Camera downloads are only supported on Flutter Web.',
    );
  }

  void releaseRecordingUrl(RecordingResult recording) {}

  Future<void> dispose() async {}
}
