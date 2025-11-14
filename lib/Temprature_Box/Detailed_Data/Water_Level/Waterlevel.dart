import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'water level paint.dart'; // Update with correct import
import '../../../MQTT_STRUCTURE/MQTT_SETUP.dart';

class WaterLevel extends StatefulWidget {
  final String parameterType;

  const WaterLevel({super.key, required this.parameterType});

  @override
  State<WaterLevel> createState() => _WaterLevelState();
}

class _WaterLevelState extends State<WaterLevel> with TickerProviderStateMixin {
  double previousFill = 0.0;
  double wavePhase = 0.0;
  double waveStrength = 1.0;

  late AnimationController _waveController;
  late Ticker _fadeTicker;
  double _targetStrength = 1.0;

  static const double maxTankHeight = 132;
  static const double maxVolume = 979;
  static const double tankDiameter = 109;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
      setState(() {
        wavePhase += 0.1;
      });
    });
    _waveController.repeat();

    _fadeTicker = createTicker((_) {
      if (waveStrength != _targetStrength) {
        setState(() {
          waveStrength += (_targetStrength - waveStrength) * 0.1;
          if ((_targetStrength - waveStrength).abs() < 0.01) {
            waveStrength = _targetStrength;
          }
        });
      }
    });
    _fadeTicker.start();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _waveController.dispose();
    _fadeTicker.dispose();
    super.dispose();
  }

  Color _getFillColor(double fillPercent) {
    if (fillPercent < 0.10) return Colors.redAccent;
    if (fillPercent < 0.20) return Colors.orangeAccent;
    if (fillPercent < 0.80) return Colors.blueAccent;
    return Colors.blue;
  }

  String _getAlertText(double fillPercent) {
    if (fillPercent < 0.10) return '⚠️ Danger: Tank Almost Empty';
    if (fillPercent < 0.20) return '⚠️ Low Water Level';
    if (fillPercent >= 0.85) return 'Tank Almost Full';
    if (fillPercent >= 0.95) return 'Tank Full';

    return 'Tank Level Normal';
  }

  @override
  Widget build(BuildContext context) {
    final mqttService = context.watch<MQTTService>();
    final double level = double.tryParse(mqttService.waterLevel) ?? maxTankHeight;

    double radius = tankDiameter / 2;
    double actualHeight = (maxTankHeight - level).clamp(0.0, maxTankHeight);
    double volume = 3.1416 * radius * radius * actualHeight / 1000;
    double fillPercent = (volume / maxVolume).clamp(0.0, 1.0);

    bool changed = (fillPercent - previousFill).abs() > 0.01;
    if (changed) {
      _targetStrength = 1.0;
      Future.delayed(const Duration(seconds: 2), () {
        _targetStrength = 0.0;
      });
    }

    final fillColor = _getFillColor(fillPercent);
    final alertText = _getAlertText(fillPercent);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.parameterType, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: previousFill, end: fillPercent),
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          onEnd: () => previousFill = fillPercent,
          builder: (context, animatedFill, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Water Tank", style: TextStyle(fontSize: 20, color: Colors.white)),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 120,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade900, Colors.black],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CustomPaint(
                          painter: WaterLevelPainter(
                            percentage: animatedFill,
                            color: fillColor,
                            wavePhase: wavePhase,
                            waveStrength: waveStrength,
                          ),
                          child: const SizedBox(width: 116, height: 246), // 120 - 2*2, 250 - 2*2
                        ),
                      ),
                    ),

                    Positioned(
                      top: 10,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.11),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),


                WaterInfoCardWidget(
                  level: level,
                  fillPercent: fillPercent,
                  volume: volume,
                  alertText: alertText,
                  fillColor: fillColor,
                ),

              ],
            );
          },
        ),
      ),
    );
  }
}

class WaterInfoCardWidget extends StatelessWidget {
  final double level;
  final double fillPercent;
  final double volume;
  final String alertText;
  final Color fillColor;

  const WaterInfoCardWidget({
    super.key,
    required this.level,
    required this.fillPercent,
    required this.volume,
    required this.alertText,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fillColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: fillColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Water Tank Status",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _info("Sensor Data", "${level.toStringAsFixed(1)} cm"),
                _info("Filled", "${(fillPercent * 100).toStringAsFixed(1)}%"),
                _info("Volume", "${volume.toStringAsFixed(1)} L", color: Colors.lightBlueAccent),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: fillColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alertText,
                    style: TextStyle(
                      color: fillColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value, {Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            )),
      ],
    );
  }
}
