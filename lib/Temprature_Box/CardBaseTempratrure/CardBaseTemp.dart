import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../MQTT_STRUCTURE/MQTT_SETUP.dart';
import '../Detailed_Data/GraphAQI.dart';
import '../Detailed_Data/GraphHumidity.dart';
import '../Detailed_Data/GraphTemprature.dart';
import '../Detailed_Data/GraphUV.dart';
import 'Weather_Provider.dart';

class CardBaseTemp extends StatelessWidget {
  const CardBaseTemp({super.key});

  /// Returns AQI icon based on PM2.5 value
  String getPM25Icon(double pm25) {
    if (pm25 <= 12) return 'assets/AQI_Icons/green.svg';
    if (pm25 <= 35) return 'assets/AQI_Icons/yellow.svg';
    if (pm25 <= 55) return 'assets/AQI_Icons/orange.svg';
    if (pm25 <= 150) return 'assets/AQI_Icons/pink.svg';
    return 'assets/AQI_Icons/purple.svg';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MQTTService, CardBaseWeatherProvider>(
      builder: (context, mqttProvider, weatherProvider, _) {
        final String temperature = weatherProvider.temperature ?? '--';
        final String humidity = weatherProvider.humidity ?? '--';
        final String pm25 = weatherProvider.pm25 ?? '--';
        final String uvIndex = weatherProvider.uvIndex ?? '--';

        // PM2.5 value + icon mapping
        final double? pm25Value = double.tryParse(pm25);
        final String pm25Icon = pm25Value != null
            ? getPM25Icon(pm25Value)
            : 'assets/AQI_Icons/purple.svg';

        // Graph values
        final double tempValue = double.tryParse(temperature) ?? 0;
        final double humidityValue = double.tryParse(humidity) ?? 0;
        final double pm25Val = double.tryParse(pm25) ?? 0;
        final double uvValue = double.tryParse(uvIndex) ?? 0;

        final List<double> tempData = List.filled(6, tempValue);
        final List<double> humidityData = List.filled(6, humidityValue);
        final List<double> pm25Data = List.filled(6, pm25Val);
        final List<double> uvData = List.filled(6, uvValue);

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Color(0xFF050505),
                Color(0xFF1A1A1A),
                Color(0xFF1A1A1A),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: _parameterItem(
                        context,
                        'assets/Parameters_Icons/temperature.svg',
                        '$temperature°',
                        'Temperature',
                        tempData,
                        iconSize: 32,
                        valueFontSize: 35,
                        valueFontWeight: FontWeight.w700,
                        iconColor: Colors.lightBlueAccent,
                        valueColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.only(left: 5, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _parameterItem(
                      context,
                      'assets/Parameters_Icons/humidity.svg',
                      '$humidity%',
                      'Humidity',
                      humidityData,
                      iconSize: 28,
                      valueFontSize: 18,
                      valueFontWeight: FontWeight.w600,
                      valueColor: Colors.white,
                      iconColor: Colors.lightBlueAccent,
                      subLabel: 'Humidity',
                    ),
                    _parameterItem(
                      context,
                      pm25Icon, // ✅ AQI icons
                      pm25,
                      'PM2.5',
                      pm25Data,
                      iconSize: 26,
                      valueFontSize: 18,
                      valueFontWeight: FontWeight.w600,
                      valueColor: Colors.white,
                      subLabel: 'AQI',
                    ),
                    _parameterItem(
                      context,
                      'assets/Parameters_Icons/uv_index_2.svg',
                      uvIndex,
                      'UV Index',
                      uvData,
                      iconSize: 28,
                      valueFontSize: 18,
                      valueFontWeight: FontWeight.w600,
                      valueColor: Colors.white,
                      iconColor: Colors.yellowAccent,
                      subLabel: 'UV',
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  /// Reusable widget for parameters
  Widget _parameterItem(
      BuildContext context,
      String? iconPath,
      String value,
      String parameterType,
      List<double> dataPoints, {
        double iconSize = 24,
        double valueFontSize = 16,
        FontWeight valueFontWeight = FontWeight.w500,
        Color valueColor = Colors.white,
        Color? iconColor,
        String? subLabel,
      }) {
    return InkWell(
      onTap: () {
        if (parameterType == 'Temperature') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TempGraph(
                dataPoints: dataPoints,
                parameterType: 'Inside Temperature',
              ),
            ),
          );
        } else if (parameterType == 'Humidity') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GraphHumidity(
                dataPoints: dataPoints,
                parameterType: 'Humidity',
              ),
            ),
          );
        } else if (parameterType == 'PM2.5') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GraphAQI(
                dataPoints: dataPoints,
                parameterType: 'Air Quality',
              ),
            ),
          );
        } else if (parameterType == 'UV Index') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GraphUV(
                dataPoints: dataPoints,
                parameterType: 'UV Index',
              ),
            ),
          );
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconPath != null)
            SvgPicture.asset(
              iconPath,
              height: iconSize,
              width: iconSize,
              color: (parameterType == 'PM2.5')
                  ? null // ✅ Keep AQI icons original colors
                  : (iconColor ?? Colors.white),
            ),
          if (iconPath != null) const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  fontWeight: valueFontWeight,
                  color: valueColor,
                ),
              ),
              if (subLabel != null)
                Text(
                  subLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
