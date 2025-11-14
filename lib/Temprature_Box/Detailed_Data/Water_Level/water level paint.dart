import 'dart:math';
import 'package:flutter/material.dart';

class WaterLevelPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double wavePhase;
  final double waveStrength;

  WaterLevelPainter({
    required this.percentage,
    required this.color,
    required this.wavePhase,
    required this.waveStrength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.8);
    final path = Path();

    final double yOffset = size.height * (1 - percentage);
    final double waveHeight = 8 * waveStrength;

    path.moveTo(0, yOffset);
    for (double i = 0; i <= size.width; i++) {
      double dy = waveHeight * sin((i / size.width * 2 * pi) + wavePhase) + yOffset;
      path.lineTo(i, dy);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WaterLevelPainter old) {
    return old.percentage != percentage ||
        old.color != color ||
        old.wavePhase != wavePhase ||
        old.waveStrength != waveStrength;
  }
}
