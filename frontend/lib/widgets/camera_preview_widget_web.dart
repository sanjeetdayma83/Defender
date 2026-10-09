import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class CameraPreviewWidget extends StatefulWidget {
  final web.MediaStream? stream;

  const CameraPreviewWidget({super.key, required this.stream});

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  web.HTMLVideoElement? _video;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CameraPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.stream != widget.stream) {
      _attachStreamToExistingVideo();
    }
  }

  void _attachStreamToExistingVideo() {
    final video = _video;

    if (video == null) {
      return;
    }

    video.srcObject = widget.stream;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stream == null) {
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

    return HtmlElementView.fromTagName(
      tagName: 'video',
      onElementCreated: (Object element) {
        final video = element as web.HTMLVideoElement;

        video.autoplay = true;
        video.muted = true;
        video.playsInline = true;
        video.controls = false;
        video.style.width = '100%';
        video.style.height = '100%';
        video.style.objectFit = 'cover';

        video.srcObject = widget.stream;

        _video = video;
      },
    );
  }

  @override
  void dispose() {
    final video = _video;

    if (video != null) {
      video.srcObject = null;
    }

    super.dispose();
  }
}
