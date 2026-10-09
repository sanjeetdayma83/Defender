import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class EvidenceVideoPlayer extends StatefulWidget {
  final String url;

  const EvidenceVideoPlayer({super.key, required this.url});

  @override
  State<EvidenceVideoPlayer> createState() => _EvidenceVideoPlayerState();
}

class _EvidenceVideoPlayerState extends State<EvidenceVideoPlayer> {
  static int _counter = 0;

  late final String _viewType;

  web.HTMLVideoElement? _video;

  @override
  void initState() {
    super.initState();

    _counter++;

    _viewType = 'loss-defender-evidence-video-$_counter';

    final video = web.HTMLVideoElement();

    video.src = widget.url;
    video.controls = true;
    video.autoplay = false;
    video.muted = false;
    video.loop = false;

    video.setAttribute('playsinline', 'true');

    video.style.width = '100%';
    video.style.height = '100%';
    video.style.objectFit = 'contain';
    video.style.backgroundColor = '#050B16';

    _video = video;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => video,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }

  @override
  void dispose() {
    try {
      _video?.pause();
    } catch (_) {}

    _video = null;

    super.dispose();
  }
}
