import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class GraphAQI extends StatefulWidget {
  final String parameterType;
  final List<double> dataPoints;

  const GraphAQI({super.key, required this.parameterType, required this.dataPoints});

  @override
  State<GraphAQI> createState() => _GraphAQIState();
}

class _GraphAQIState extends State<GraphAQI> {

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  String getPM25Icon(double pm25) {
    if (pm25 <= 12) {
      return 'assets/AQI_Icons/green.svg';
    } else if (pm25 <= 35) {
      return 'assets/AQI_Icons/yellow.svg';
    } else if (pm25 <= 55) {
      return 'assets/AQI_Icons/orange.svg';
    } else if (pm25 <= 150) {
      return 'assets/AQI_Icons/pink.svg';
    } else {
      return 'assets/AQI_Icons/purple.svg';
    }
  }

  String getAQIExpression(num value) {
    if (value <= 50) return "Good 😊";
    if (value <= 100) return "Moderate 😐";
    if (value <= 150) return "Unhealthy for Sensitive 😷";
    if (value <= 200) return "Unhealthy 😷";
    if (value <= 300) return "Very Unhealthy 😨";
    return "Hazardous ☠️";
  }


  @override
  Widget build(BuildContext context) {
    final latestAQI = widget.dataPoints.isNotEmpty ? widget.dataPoints.last : 0;
    final iconPath = getPM25Icon(latestAQI.toDouble());
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.parameterType,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // AQI Icon Display
          Center(
            child: Column(
              children: [
                SvgPicture.asset(iconPath, width: 100, height: 100),
                const SizedBox(height: 8),
                Text(
                  'Air Quality: ${latestAQI.toStringAsFixed(1)}',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),


          // AQI Graph
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 300,
                    axisLineStyle: const AxisLineStyle(
                      color: Colors.white24, // optional: lighter dial ring
                      thickness: 15,
                    ),
                    majorTickStyle: const MajorTickStyle(
                      color: Colors.white,
                    ),
                    minorTickStyle: const MinorTickStyle(
                      color: Colors.white54,
                    ),
                    axisLabelStyle: const GaugeTextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    ranges: <GaugeRange>[
                      GaugeRange(startValue: 0, endValue: 50, color: Colors.green),
                      GaugeRange(startValue: 50, endValue: 100, color: Colors.yellow),
                      GaugeRange(startValue: 100, endValue: 150, color: Colors.orange),
                      GaugeRange(startValue: 150, endValue: 200, color: Colors.pink),
                      GaugeRange(startValue: 200, endValue: 300, color: Colors.purple),
                    ],
                    pointers: <GaugePointer>[
                      NeedlePointer(
                        value: widget.dataPoints.last.toDouble(),
                        needleColor: Colors.white,
                        knobStyle: const KnobStyle(color: Colors.white),
                        enableAnimation: true,          // Enable animation
                        animationType: AnimationType.ease,  // Smooth animation
                        animationDuration: 2000,        // Duration in milliseconds
                      )

                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Text(
                          widget.dataPoints.last.toInt().toString(),
                          style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        angle: 90,
                        positionFactor: 0.5,
                      ),
                      GaugeAnnotation(
                        widget: Text(
                          getAQIExpression(widget.dataPoints.last),
                          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w400),
                        ),
                        angle: 90,
                        positionFactor: 1.0,
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
