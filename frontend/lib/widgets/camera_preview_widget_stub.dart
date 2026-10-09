import 'package:flutter/material.dart';

class CameraPreviewWidget extends StatelessWidget {
  final dynamic stream;

  const CameraPreviewWidget({super.key, required this.stream});

  @override
  Widget build(BuildContext context) {
    if (stream == null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 48),
            SizedBox(height: 12),
            Text(
              'Camera preview unavailable',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const Text(
        'Camera preview is available on supported web devices.',
        style: TextStyle(color: Colors.white70),
        textAlign: TextAlign.center,
      ),
    );
  }
}
