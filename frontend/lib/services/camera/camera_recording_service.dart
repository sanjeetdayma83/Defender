import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

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
      if (deviceId.isEmpty) {
        return 'Camera';
      }

      final shortId = deviceId.length > 8 ? deviceId.substring(0, 8) : deviceId;

      return 'Camera $shortId';
    }

    return label;
  }

  @override
  String toString() {
    return 'CameraDeviceInfo('
        'deviceId: $deviceId, '
        'label: $label'
        ')';
  }
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

class CameraRecordingService {
  web.MediaStream? _stream;
  web.MediaRecorder? _recorder;

  final List<web.Blob> _chunks = <web.Blob>[];

  DateTime? _recordingStartedAt;

  web.MediaStream? get stream => _stream;

  bool get isRecording {
    final recorder = _recorder;

    return recorder != null && recorder.state == 'recording';
  }

  Future<bool> isSupported() async {
    try {
      web.window.navigator.mediaDevices;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<CameraDeviceInfo>> getCameras() async {
    final mediaDevices = web.window.navigator.mediaDevices;

    final deviceList = await mediaDevices.enumerateDevices().toDart;

    final cameras = <CameraDeviceInfo>[];

    for (final device in deviceList.toDart) {
      if (device.kind == 'videoinput') {
        cameras.add(
          CameraDeviceInfo(
            deviceId: device.deviceId,
            label: device.label,
            groupId: device.groupId,
          ),
        );
      }
    }

    return cameras;
  }

  Future<web.MediaStream> openCamera({
    String? deviceId,
    int width = 1280,
    int height = 720,
  }) async {
    await stopPreview();

    final videoConstraints = <String, dynamic>{
      'width': <String, dynamic>{'ideal': width},
      'height': <String, dynamic>{'ideal': height},
    };

    if (deviceId != null && deviceId.isNotEmpty) {
      videoConstraints['deviceId'] = <String, dynamic>{'exact': deviceId};
    }

    final constraints = web.MediaStreamConstraints(
      audio: false.toJS,
      video: videoConstraints.jsify()!,
    );

    final stream = await web.window.navigator.mediaDevices
        .getUserMedia(constraints)
        .toDart;

    _stream = stream;

    return stream;
  }

  Future<void> stopPreview() async {
    final stream = _stream;

    if (stream != null) {
      for (final track in stream.getTracks().toDart) {
        track.stop();
      }
    }

    _stream = null;
  }

  Future<bool> startRecording() async {
    final stream = _stream;

    if (stream == null || isRecording) {
      return false;
    }

    _chunks.clear();

    final mimeType = _getSupportedMimeType();

    final recorder = web.MediaRecorder(
      stream,
      web.MediaRecorderOptions(mimeType: mimeType),
    );

    recorder.ondataavailable = ((web.BlobEvent event) {
      final data = event.data;

      if (data.size > 0) {
        _chunks.add(data);
      }
    }).toJS;

    _recorder = recorder;
    _recordingStartedAt = DateTime.now();

    recorder.start();

    return true;
  }

  Future<RecordingResult?> stopRecording({required String identifier}) async {
    final recorder = _recorder;

    if (recorder == null) {
      return null;
    }

    final startedAt = _recordingStartedAt ?? DateTime.now();

    final completer = Completer<void>();

    recorder.onstop = (() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }).toJS;

    if (recorder.state != 'inactive') {
      recorder.stop();
    } else if (!completer.isCompleted) {
      completer.complete();
    }

    await completer.future;

    final durationMs = DateTime.now().difference(startedAt).inMilliseconds;

    final mimeType = recorder.mimeType.isNotEmpty
        ? recorder.mimeType
        : _getSupportedMimeType();

    final blob = web.Blob(_chunks.toJS, web.BlobPropertyBag(type: mimeType));

    final objectUrl = web.URL.createObjectURL(blob);

    final safeIdentifier = _sanitizeFilename(identifier);

    final filename = '$safeIdentifier.webm';

    final result = RecordingResult(
      filename: filename,
      mimeType: mimeType,
      sizeBytes: blob.size,
      durationMs: durationMs,
      objectUrl: objectUrl,
    );

    _recorder = null;
    _recordingStartedAt = null;
    _chunks.clear();

    return result;
  }

  void downloadRecording(RecordingResult recording) {
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;

    anchor.href = recording.objectUrl;
    anchor.download = recording.filename;
    anchor.style.display = 'none';

    web.document.body?.appendChild(anchor);

    anchor.click();

    anchor.remove();
  }

  void releaseRecordingUrl(RecordingResult recording) {
    web.URL.revokeObjectURL(recording.objectUrl);
  }

  String _getSupportedMimeType() {
    const candidates = <String>[
      'video/webm;codecs=vp9',
      'video/webm;codecs=vp8',
      'video/webm',
    ];

    for (final mimeType in candidates) {
      if (web.MediaRecorder.isTypeSupported(mimeType)) {
        return mimeType;
      }
    }

    return 'video/webm';
  }

  String _sanitizeFilename(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');

    if (cleaned.isEmpty) {
      return 'packing_evidence_'
          '${DateTime.now().millisecondsSinceEpoch}';
    }

    return cleaned;
  }

  Future<void> dispose() async {
    if (isRecording) {
      try {
        _recorder?.stop();
      } catch (_) {}
    }

    _recorder = null;
    _recordingStartedAt = null;
    _chunks.clear();

    await stopPreview();
  }
}
