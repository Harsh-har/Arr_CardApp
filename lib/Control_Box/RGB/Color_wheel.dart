import 'dart:math';
import 'package:flutter/material.dart';

class ColorWheelWithSaturation extends StatefulWidget {
  final double size;
  final double initialHue;
  final HSVColor? initialColor;
  final ValueChanged<HSVColor> onColorChanged;
  final ValueChanged<HSVColor>? onColorChangeEnd; // ✅ new

  const ColorWheelWithSaturation({
    super.key,
    this.size = 300,
    this.initialHue = 0,
    this.initialColor,
    required this.onColorChanged,
    this.onColorChangeEnd, // ✅ new
  });

  @override
  State<ColorWheelWithSaturation> createState() =>
      _ColorWheelWithSaturationState();
}

class _ColorWheelWithSaturationState extends State<ColorWheelWithSaturation> {
  late double _hue;
  late double _saturation;
  late double _shade;

  bool _isDraggingRing = false;
  bool _isDraggingCenter = false;
  final double ringStrokeWidth = 30;

  @override
  void initState() {
    super.initState();
    _hue = widget.initialHue;
    _saturation = widget.initialColor?.saturation ?? 1.0;
    _shade = widget.initialColor?.value ?? 1.0;
  }

  void _updateHue(Offset localOffset) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final dx = localOffset.dx - center.dx;
    final dy = localOffset.dy - center.dy;

    double angle = atan2(dy, dx);
    double hue = (angle * 180 / pi + 90) % 360;

    setState(() => _hue = hue);

    // 🔴 live update
    widget.onColorChanged(HSVColor.fromAHSV(1, _hue, _saturation, _shade));
  }

  void _updateCenter(Offset localOffset) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final ringRadius = (widget.size / 2) - 15;
    final logicalRadius = ringRadius - ringStrokeWidth;

    double dx = localOffset.dx - center.dx;
    double dy = localOffset.dy - center.dy;

    double distance = sqrt(dx * dx + dy * dy);
    double scale = distance > logicalRadius ? logicalRadius / distance : 1.0;
    dx *= scale;
    dy *= scale;

    // Swap logic: saturation vertically, value horizontally
    double saturation = (-dy / logicalRadius + 1) / 2; // vertical: bottom=0, top=1
    double brightness = (dx / logicalRadius + 1) / 2;  // horizontal: left=0, right=1

    setState(() {
      _saturation = saturation.clamp(0.0, 1.0);
      _shade = brightness.clamp(0.0, 1.0);
    });

    widget.onColorChanged(HSVColor.fromAHSV(1, _hue, _saturation, _shade));
  }

  void _onPanStart(DragStartDetails details) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final dx = details.localPosition.dx - center.dx;
    final dy = details.localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final ringRadius = (widget.size / 2) - 15;

    if (distance >= ringRadius - ringStrokeWidth / 2 &&
        distance <= ringRadius + ringStrokeWidth / 2) {
      _isDraggingRing = true;
      _updateHue(details.localPosition);
    } else if (distance < ringRadius - ringStrokeWidth / 2) {
      _isDraggingCenter = true;
      _updateCenter(details.localPosition);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isDraggingRing) _updateHue(details.localPosition);
    if (_isDraggingCenter) _updateCenter(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    _isDraggingRing = false;
    _isDraggingCenter = false;

    // 🟢 final callback
    if (widget.onColorChangeEnd != null) {
      widget.onColorChangeEnd!(
        HSVColor.fromAHSV(1, _hue, _saturation, _shade),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.size / 2;
    final ringRadius = center - 15;
    final radius = ringRadius - ringStrokeWidth;
    // Visual radius for saturation/brightness circle
    final sbVisualRadius = radius * 1.7 / 2;

// Map saturation (vertical) and brightness (horizontal) to dx/dy
    double dx = (_shade - 0.5) * 2 * radius;       // horizontal: left-right
    double dy = -(_saturation - 0.5) * 2 * radius; // vertical: bottom-top

// Limit distance inside circle
    double dist = sqrt(dx * dx + dy * dy);
    if (dist > radius) {
      double scale = radius / dist;
      dx *= scale;
      dy *= scale;
    }

// Scale to painter size
    dx *= sbVisualRadius / radius;
    dy *= sbVisualRadius / radius;

// Center coordinates
    final centerOffset = Offset(center + dx, center + dy);


    final angle = (_hue - 90) * pi / 180;
    final hueThumbX = center + ringRadius * cos(angle);
    final hueThumbY = center + ringRadius * sin(angle);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTapDown: (details) {
        final center = Offset(widget.size / 2, widget.size / 2);
        final dx = details.localPosition.dx - center.dx;
        final dy = details.localPosition.dy - center.dy;
        final ringRadius = (widget.size / 2) - 15;
        final logicalRadius = ringRadius - ringStrokeWidth;

        if (dx * dx + dy * dy <= logicalRadius * logicalRadius) {
          _updateCenter(details.localPosition);

          // 🟢 also fire end on tap
          if (widget.onColorChangeEnd != null) {
            widget.onColorChangeEnd!(
              HSVColor.fromAHSV(1, _hue, _saturation, _shade),
            );
          }
        }
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _ColorWheelPainter(),
            ),
            Positioned(
              left: hueThumbX - 14,
              top: hueThumbY - 14,
              child: Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 5),
                  color: Colors.transparent,
                ),
              ),
            ),
            CustomPaint(
              size: Size(radius * 1.7, radius * 1.7),
              painter: _SaturationBrightnessPainter(_hue),
            ),
            Positioned(
              left: centerOffset.dx - 12,
              top: centerOffset.dy - 12,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: Colors.transparent,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);

    final rect = Rect.fromCircle(center: center, radius: radius - 15);
    final sweepGradient = SweepGradient(
      colors: [
        for (double h = 0; h <= 360; h += 1)
          HSVColor.fromAHSV(1, h, 1, 1).toColor(),
      ],
      transform: GradientRotation(-pi / 2),
    );

    final paint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30;

    canvas.drawCircle(center, radius - 15, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SaturationBrightnessPainter extends CustomPainter {
  final double hue;

  _SaturationBrightnessPainter(this.hue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Bottom: full color, Top: light/white
    final gradient = LinearGradient(
      begin: Alignment.topCenter,  // white at top
      end: Alignment.bottomCenter, // full color at bottom
      colors: [
        Colors.white,
        HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
      ],
    );


    final paint = Paint()..shader = gradient.createShader(rect);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _SaturationBrightnessPainter oldDelegate) =>
      oldDelegate.hue != hue;
}
