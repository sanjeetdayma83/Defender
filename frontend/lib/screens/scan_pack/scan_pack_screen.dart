import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '';
import '../../services/packing/packing_api_service.dart';
import '../../services/camera/camera_recording_service.dart';
import '../../services/orders/order_service.dart';
import '../../services/scanner/barcode_input_service.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/camera_preview_widget.dart';

class ScanPackScreen extends StatefulWidget {
  const ScanPackScreen({super.key});

  @override
  State<ScanPackScreen> createState() => _ScanPackScreenState();
}

class _ScanPackScreenState extends State<ScanPackScreen> {
  final OrderService _orderService = OrderService();

  final CameraRecordingService _cameraService = CameraRecordingService();

  final MediaUploadService _mediaUploadService = const MediaUploadService();

  final TextEditingController _scanController = TextEditingController();

  late final BarcodeInputService _barcodeInputService;

  List<CameraDeviceInfo> _cameras = <CameraDeviceInfo>[];

  CameraDeviceInfo? _selectedCamera;

  Order? _currentOrder;

  RecordingResult? _lastRecording;

  bool _loadingCamera = true;
  bool _recording = false;
  bool _lookingUp = false;
  bool _uploading = false;

  String? _cameraError;
  String? _scanError;
  String? _uploadError;

  String? _lastScannedBarcode;

  int _scanCount = 0;

  DateTime? _lastScanAt;

  Timer? _timer;

  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _barcodeInputService = BarcodeInputService(
      onBarcode: _handleScannerBarcode,
    );

    _barcodeInputService.start();

    _initializeCamera();
  }

  void _handleScannerBarcode(String barcode) {
    if (!mounted) {
      return;
    }

    final value = barcode.trim();

    if (value.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final previousScan = _lastScanAt;

    // Prevent accidental duplicate scanner events.
    if (_lastScannedBarcode == value &&
        previousScan != null &&
        now.difference(previousScan) < const Duration(milliseconds: 700)) {
      return;
    }

    _lastScanAt = now;
    _lastScannedBarcode = value;
    _scanCount++;

    _scanController
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);

    setState(() {
      _scanError = null;
    });

    _processScan();
  }

  Future<void> _initializeCamera() async {
    if (mounted) {
      setState(() {
        _loadingCamera = true;
        _cameraError = null;
      });
    }

    try {
      final supported = await _cameraService.isSupported();

      if (!supported) {
        throw Exception('Browser camera APIs are not available.');
      }

      var cameras = await _cameraService.getCameras();

      if (cameras.isEmpty) {
        try {
          await _cameraService.openCamera();

          cameras = await _cameraService.getCameras();
        } catch (_) {
          throw Exception(
            'Camera permission is required. '
            'Please allow camera access in Chrome.',
          );
        }
      }

      if (cameras.isEmpty) {
        throw Exception('No camera device was detected.');
      }

      final selected = cameras.first;

      await _cameraService.openCamera(deviceId: selected.deviceId);

      if (!mounted) {
        return;
      }

      setState(() {
        _cameras = cameras;
        _selectedCamera = selected;
        _loadingCamera = false;
        _cameraError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingCamera = false;
        _cameraError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _changeCamera(CameraDeviceInfo? camera) async {
    if (camera == null || _recording) {
      return;
    }

    try {
      await _cameraService.openCamera(deviceId: camera.deviceId);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedCamera = camera;
        _cameraError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _processScan() async {
    final value = _scanController.text.trim();

    if (value.isEmpty || _lookingUp) {
      return;
    }

    // A recording may be active, but a new valid scan must first
    // resolve to an order before we change the active recording.
    final previousOrder = _currentOrder;
    final wasRecording = _recording;

    setState(() {
      _lookingUp = true;
      _scanError = null;
    });

    try {
      final order = await _orderService.findByBarcode(value);

      if (!mounted) {
        return;
      }

      // ----------------------------------------------------------
      // Invalid scan
      // ----------------------------------------------------------

      if (order == null) {
        setState(() {
          _lookingUp = false;
          _scanError = 'Order not found for barcode: $value';
        });

        return;
      }

      // ----------------------------------------------------------
      // Same order scanned again
      // ----------------------------------------------------------

      if (wasRecording &&
          previousOrder != null &&
          previousOrder.awb.toLowerCase() == order.awb.toLowerCase()) {
        setState(() {
          _lookingUp = false;
          _currentOrder = order;
          _scanError = null;
        });

        return;
      }

      // ----------------------------------------------------------
      // New valid order while another recording is active
      // ----------------------------------------------------------

      if (wasRecording && previousOrder != null) {
        setState(() {
          _lookingUp = false;
        });

        await _finishCurrentRecording(previousOrder);

        if (!mounted) {
          return;
        }
      }

      // ----------------------------------------------------------
      // Activate new order
      // ----------------------------------------------------------

      setState(() {
        _currentOrder = order;
        _lookingUp = false;
        _scanError = null;
        _uploadError = null;
        _lastRecording = null;
        _recordingDuration = Duration.zero;
      });

      // ----------------------------------------------------------
      // Start recording for new valid order
      // ----------------------------------------------------------

      if (!_recording) {
        await _startRecording();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _lookingUp = false;
        _scanError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _finishCurrentRecording(Order order) async {
    if (!_recording) {
      return;
    }

    _timer?.cancel();

    RecordingResult? result;

    try {
      result = await _cameraService.stopRecording(identifier: order.awb);
    } catch (error) {
      if (mounted) {
        setState(() {
          _recording = false;
          _uploading = false;
          _uploadError = error.toString().replaceFirst('Exception: ', '');
        });
      }

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _recording = false;
      _recordingDuration = Duration.zero;
      _lastRecording = result;
      _uploading = result != null;
      _uploadError = null;
    });

    if (result == null) {
      setState(() {
        _uploading = false;
        _uploadError = 'Previous recording could not be created.';
      });

      return;
    }

    await _uploadRecording(result, order);
  }

  Future<void> _startRecording() async {
    if (_recording) {
      return;
    }

    final order = _currentOrder;

    if (order == null) {
      return;
    }

    if (_cameraService.stream == null) {
      setState(() {
        _cameraError =
            'Camera is not ready. '
            'Please select a camera.';
      });
      return;
    }

    final started = await _cameraService.startRecording();

    if (!started) {
      if (!mounted) {
        return;
      }

      setState(() {
        _cameraError = 'Unable to start video recording.';
      });

      return;
    }

    _timer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _recording = true;
      _recordingDuration = Duration.zero;
      _uploadError = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_recording) {
        return;
      }

      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
  }

  Future<void> _stopRecording() async {
    if (!_recording) {
      return;
    }

    final order = _currentOrder;

    if (order == null) {
      return;
    }

    await _finishCurrentRecording(order);
  }

  Future<void> _uploadRecording(RecordingResult recording, Order order) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _uploading = true;
      _uploadError = null;
    });

    try {
      final response = await _mediaUploadService.uploadRecording(
        recording: recording,
        awb: order.awb,
        sku: order.product.sku,
      );

      if (!mounted) {
        return;
      }

      if (!response.success || response.media == null) {
        throw Exception(response.message ?? 'Cloud upload failed.');
      }

      setState(() {
        _uploading = false;
        _uploadError = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Uploaded to B2: '
            '${recording.filename}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _uploading = false;
        _uploadError = error.toString().replaceFirst('Exception: ', '');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cloud upload failed.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: 'RETRY', onPressed: _retryUpload),
        ),
      );
    }
  }

  Future<void> _retryUpload() async {
    final recording = _lastRecording;
    final order = _currentOrder;

    if (recording == null || order == null || _uploading) {
      return;
    }

    await _uploadRecording(recording, order);
  }

  void _clearScan() {
    if (_recording || _uploading) {
      return;
    }

    _scanController.clear();

    setState(() {
      _currentOrder = null;
      _scanError = null;
      _uploadError = null;
      _lastRecording = null;
      _lastScannedBarcode = null;
      _recordingDuration = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');

    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final order = _currentOrder;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scan & Pack',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Scan an AWB, order ID or SKU '
            'to begin packing verification.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildCameraPanel()),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _buildScanPanel()),
            ],
          ),
          const SizedBox(height: 20),
          if (order != null) _buildOrderPanel(order),
          if (_lastRecording != null) ...[
            const SizedBox(height: 20),
            _buildRecordingResult(_lastRecording!),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraPanel() {
    return LDCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                const Icon(Icons.videocam_outlined),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Packing Camera',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                if (_recording)
                  LDStatusBadge(text: 'RECORDING', color: Colors.red),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: _loadingCamera
                  ? const Center(child: CircularProgressIndicator())
                  : _cameraError != null
                  ? _buildCameraError()
                  : CameraPreviewWidget(stream: _cameraService.stream),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<CameraDeviceInfo>(
                  initialValue: _selectedCamera,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Camera Device',
                    prefixIcon: Icon(Icons.camera_alt_outlined),
                  ),
                  items: _cameras
                      .map(
                        (camera) => DropdownMenuItem<CameraDeviceInfo>(
                          value: camera,
                          child: Text(
                            camera.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _recording ? null : _changeCamera,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loadingCamera ? null : _initializeCamera,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Cameras'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_recording)
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                          ),
                          onPressed: _stopRecording,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: Text(_formatDuration(_recordingDuration)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              color: Colors.white54,
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              _cameraError ?? 'Camera unavailable',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanPanel() {
    final scannerActive = _barcodeInputService.isStarted;

    return LDCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipment Scanner',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),

          // ----------------------------------------------------
          // Scanner status
          // ----------------------------------------------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scannerActive
                  ? Colors.green.withValues(alpha: 0.07)
                  : Colors.red.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scannerActive
                    ? Colors.green.withValues(alpha: 0.20)
                    : Colors.red.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: scannerActive ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    scannerActive
                        ? 'USB HID Scanner Ready'
                        : 'Scanner Inactive',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '$_scanCount scans',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Scan a barcode with the USB scanner. '
            'The scanner should send Enter after the barcode.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),

          // ----------------------------------------------------
          // Last scanned barcode
          // ----------------------------------------------------
          if (_lastScannedBarcode != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Scan',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _lastScannedBarcode!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ----------------------------------------------------
          // Manual input
          // ----------------------------------------------------
          TextField(
            controller: _scanController,
            autofocus: true,
            onSubmitted: (_) => _processScan(),
            decoration: InputDecoration(
              labelText: 'AWB / Order ID / SKU',
              hintText: 'Example: FMPP3767030215',
              prefixIcon: const Icon(Icons.qr_code_scanner),
              suffixIcon: IconButton(
                onPressed: _lookingUp ? null : _processScan,
                icon: _lookingUp
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
              ),
            ),
          ),

          // ----------------------------------------------------
          // Scan error
          // ----------------------------------------------------
          if (_scanError != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.20)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _scanError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ----------------------------------------------------
          // Current status
          // ----------------------------------------------------
          if (_currentOrder != null)
            LDStatusBadge(
              text: _recording ? 'PACKING IN PROGRESS' : 'ORDER FOUND',
              color: _recording ? Colors.cyan.shade700 : Colors.green,
            )
          else
            const LDStatusBadge(
              text: 'WAITING FOR SCAN',
              color: Colors.blueGrey,
            ),

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: _recording || _uploading ? null : _clearScan,
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderPanel(Order order) {
    return LDCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Shipment Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              LDStatusBadge(text: order.status, color: Colors.green),
            ],
          ),
          const Divider(height: 28),
          Wrap(
            spacing: 28,
            runSpacing: 18,
            children: [
              _infoItem('AWB', order.awb),
              _infoItem('Order ID', order.orderId),
              _infoItem('Marketplace', order.marketplace),
              _infoItem('SKU', order.product.sku),
              _infoItem('Quantity', order.quantity.toString()),
              _infoItem('Variant', order.product.variant),
              _infoItem('Color', order.product.color),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String title, String value) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingResult(RecordingResult recording) {
    final bool uploadSuccess = !_uploading && _uploadError == null;

    return LDCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _uploading
                  ? Colors.blue.withValues(alpha: 0.1)
                  : uploadSuccess
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _uploading
                  ? Icons.cloud_upload_outlined
                  : uploadSuccess
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              color: _uploading
                  ? Colors.blue
                  : uploadSuccess
                  ? Colors.green
                  : Colors.red,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _uploading
                      ? 'Uploading to B2...'
                      : uploadSuccess
                      ? 'Cloud Backup Complete'
                      : 'Cloud Upload Failed',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(recording.filename, overflow: TextOverflow.ellipsis),
                Text(
                  '${(recording.sizeBytes / 1024).toStringAsFixed(1)} KB · '
                  '${(recording.durationMs / 1000).toStringAsFixed(1)} sec',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (_uploadError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _uploadError!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (_uploading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_uploadError != null)
            OutlinedButton(onPressed: _retryUpload, child: const Text('Retry'))
          else
            const Icon(Icons.verified_outlined, color: Colors.green),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _barcodeInputService.dispose();
    _scanController.dispose();
    _cameraService.dispose();
    super.dispose();
  }
}

