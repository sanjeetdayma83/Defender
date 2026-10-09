import 'package:flutter/material.dart';

class EvidenceVideoPlayer extends StatelessWidget {
  final String url;

  const EvidenceVideoPlayer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.video_library_outlined, color: Colors.white54, size: 48),
          SizedBox(height: 12),
          Text(
            'Video playback is available on supported web devices.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
