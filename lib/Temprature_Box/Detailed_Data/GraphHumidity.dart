import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GraphHumidity extends StatefulWidget {
  final String parameterType;
  final List<double> dataPoints;

  const GraphHumidity({super.key, required this.parameterType, required this.dataPoints});

  @override
  State<GraphHumidity> createState() => _GraphHumidityState();
}

class _GraphHumidityState extends State<GraphHumidity> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  double get latestHumidity => widget.dataPoints.isNotEmpty ? widget.dataPoints.last : 0;

  Color getFillColor(double humidity) {
    if (humidity < 30) return Colors.redAccent;
    if (humidity <= 50) return Colors.blue;
    if (humidity < 80) return Colors.lightBlue;
    return Colors.blue;
  }

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.initState();
    _animationController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _animationController.dispose();
    super.dispose();
  }

  double _humidityToHeightFactor(double value) => (value.clamp(0, 100)) / 100;

  @override
  Widget build(BuildContext context) {
    final color = getFillColor(latestHumidity);
    final fillFactor = _humidityToHeightFactor(latestHumidity);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Humidity", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(240, 330),
              painter: DropletPainter(
                fillFraction: fillFactor,
                color: color,
                animationValue: _animationController,
              ),
            ),

            Positioned(
              bottom: 45, // Adjust this value to move the text inside the droplet
              child: Text(
                "${latestHumidity.toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DropletPainter extends CustomPainter {
  final double fillFraction; // 0 to 1
  final Color color;
  final Animation<double> animationValue;

  DropletPainter({required this.fillFraction, required this.color, required this.animationValue}) : super(repaint: animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final dropletPath = Path();
    final centerX = size.width / 2;
    final height = size.height;
    final width = size.width;

    // Create a teardrop shape
    dropletPath.moveTo(centerX, 0);
    dropletPath.quadraticBezierTo(width, height * 1.0, centerX, height);
    dropletPath.quadraticBezierTo(0, height * 1.0, centerX, 0);
    dropletPath.close();

    // Clip inside droplet
    canvas.save();
    canvas.clipPath(dropletPath);

    final paint = Paint()
      ..color = color.withOpacity(1.0)
      ..style = PaintingStyle.fill;

    // Fill height based on humidity
    final fillHeight = height * (1 - fillFraction);
    final waveHeight = 8;
    final waveSpeed = animationValue.value * 2 * pi;

    final wavePath = Path();
    wavePath.moveTo(0, height);
    for (double i = 0; i <= width; i++) {
      double dx = i;
      double dy = fillHeight + sin((i / width * 2 * pi) + waveSpeed) * waveHeight;
      wavePath.lineTo(dx, dy);
    }
    wavePath.lineTo(width, height);
    wavePath.lineTo(0, height);
    wavePath.close();

    canvas.drawPath(wavePath, paint);
    canvas.restore();

    // Draw outer droplet border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(dropletPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant DropletPainter oldDelegate) {
    return oldDelegate.fillFraction != fillFraction || oldDelegate.color != color;
  }
}
