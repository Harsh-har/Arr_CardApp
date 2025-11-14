import 'dart:math';
import 'package:flutter/material.dart';

class GraphUV extends StatefulWidget {
  final String parameterType;
  final List<double> dataPoints;

  const GraphUV({super.key, required this.parameterType, required this.dataPoints});

  @override
  State<GraphUV> createState() => _GraphUVState();
}

class _GraphUVState extends State<GraphUV> {
  double get latestUV => widget.dataPoints.isNotEmpty ? widget.dataPoints.last : 0;

  String getUVExpression(double uv) {
    if (uv <= 2) return "Low";
    if (uv <= 5) return "Moderate";
    if (uv <= 7) return "High";
    if (uv <= 10) return "Very High";
    return "Extreme";
  }

  Color getUVColor(double uv) {
    if (uv <= 2) return Colors.blue;
    if (uv <= 5) return Colors.green;
    if (uv <= 7) return Colors.orange;
    if (uv <= 10) return Colors.amber;
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final color = getUVColor(latestUV);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("UV Index", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomPaint(
              size: const Size(250, 250),
              painter: SunPainter(
                uvValue: latestUV,
                sunColor: color,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              latestUV.toStringAsFixed(1),
              style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              getUVExpression(latestUV),
              style: const TextStyle(fontSize: 20, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class SunPainter extends CustomPainter {
  final double uvValue;
  final Color sunColor;

  SunPainter({required this.uvValue, required this.sunColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 50 + uvValue * 2.5; // sun size increases with UV
    final rayLength = 20 + uvValue * 3; // ray length increases with UV
    final rayCount = 8 + (uvValue).round(); // number of rays increases with UV

    final sunPaint = Paint()
      ..color = sunColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final rayPaint = Paint()
      ..color = sunColor.withOpacity(0.7)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Draw sun circle
    canvas.drawCircle(center, radius, sunPaint);

    // Draw sun rays
    for (int i = 0; i < rayCount; i++) {
      final angle = 2 * pi * i / rayCount;
      final start = Offset(
        center.dx + cos(angle) * (radius + 5),
        center.dy + sin(angle) * (radius + 5),
      );
      final end = Offset(
        center.dx + cos(angle) * (radius + rayLength),
        center.dy + sin(angle) * (radius + rayLength),
      );
      canvas.drawLine(start, end, rayPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SunPainter oldDelegate) {
    return oldDelegate.uvValue != uvValue || oldDelegate.sunColor != sunColor;
  }
}
