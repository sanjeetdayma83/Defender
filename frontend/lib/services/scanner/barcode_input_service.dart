import 'dart:async';
import 'package:flutter/services.dart';

/// Receives barcode data from USB HID / keyboard-wedge scanners.
///
/// Most warehouse barcode scanners behave like a keyboard:
///   characters -> characters -> ENTER
///
/// This service buffers those characters and emits one complete
/// barcode when the scanner sends ENTER.
///
/// It does not replace ScannerService.
/// ScannerService remains responsible for WebHID device discovery.
class BarcodeInputService {
  final Duration scanTimeout;

  final void Function(String barcode) onBarcode;

  final StringBuffer _buffer = StringBuffer();

  Timer? _resetTimer;

  bool _started = false;

  BarcodeInputService({
    required this.onBarcode,
    this.scanTimeout = const Duration(milliseconds: 120),
  });

  bool get isStarted => _started;

  void start() {
    if (_started) {
      return;
    }

    _started = true;

    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  void stop() {
    if (!_started) {
      return;
    }

    _started = false;

    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);

    _resetBuffer();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!_started) {
      return false;
    }

    if (event is! KeyDownEvent) {
      return false;
    }

    final logicalKey = event.logicalKey;

    // Scanner usually sends ENTER after the barcode.
    if (logicalKey == LogicalKeyboardKey.enter ||
        logicalKey == LogicalKeyboardKey.numpadEnter) {
      _finishScan();
      return false;
    }

    // Ignore modifier/navigation keys.
    if (_isIgnoredKey(logicalKey)) {
      return false;
    }

    final character = event.character;

    if (character == null || character.isEmpty) {
      return false;
    }

    // Ignore control characters.
    if (character.codeUnitAt(0) < 32) {
      return false;
    }

    _buffer.write(character);

    _restartTimeout();

    return false;
  }

  bool _isIgnoredKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight ||
        key == LogicalKeyboardKey.capsLock ||
        key == LogicalKeyboardKey.tab ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight;
  }

  void _finishScan() {
    _resetTimer?.cancel();
    _resetTimer = null;

    final barcode = _buffer.toString().trim();

    _buffer.clear();

    if (barcode.isEmpty) {
      return;
    }

    onBarcode(barcode);
  }

  void _restartTimeout() {
    _resetTimer?.cancel();

    _resetTimer = Timer(scanTimeout, () {
      _resetBuffer();
    });
  }

  void _resetBuffer() {
    _resetTimer?.cancel();
    _resetTimer = null;
    _buffer.clear();
  }

  void dispose() {
    stop();
  }
}
