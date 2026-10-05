import 'package:flutter/material.dart';

class LossDefenderLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  const LossDefenderLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/loss_defender_logo.png',
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Loss Defender',
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: width,
          height: height,
          child: const Center(
            child: Text(
              'LOSS DEFENDER',
              style: TextStyle(
                color: Color(0xFF0B2A68),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        );
      },
    );
  }
}
