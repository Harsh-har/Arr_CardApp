import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../MQTT_STRUCTURE/MQTT_SETUP.dart';
import 'Detailed_Data/GraphAQI.dart';
import 'Detailed_Data/GraphHumidity.dart';
import 'Detailed_Data/GraphTemprature.dart';
import 'Detailed_Data/GraphUV.dart';
import 'Detailed_Data/Water_Level/Waterlevel.dart';
import 'Weather_Provider.dart';

class TemperatureTemplate extends StatefulWidget {
  const TemperatureTemplate({super.key});

  @override
  State<TemperatureTemplate> createState() => _TemperatureTemplateState();
}

class _TemperatureTemplateState extends State<TemperatureTemplate> {

  String getPM25Icon(double pm25) {
    if (pm25 <= 12) return 'assets/AQI_Icons/green.svg';
    if (pm25 <= 35) return 'assets/AQI_Icons/yellow.svg';
    if (pm25 <= 55) return 'assets/AQI_Icons/orange.svg';
    if (pm25 <= 150) return 'assets/AQI_Icons/pink.svg';
    return 'assets/AQI_Icons/purple.svg';
  }

  Color getWaterLevelColor(double percent) {
    if (percent <= 10) return Colors.redAccent;
    if (percent <= 20) return Colors.orange;
    if (percent <= 80) return Colors.blueAccent;
    return Colors.blue;
  }


  @override
  Widget build(BuildContext context) {
    return Consumer2<MQTTService, WeatherProvider>(
      builder: (context, mqttProvider, weatherProvider, _) {
    final mqttProvider = Provider.of<MQTTService>(context);
    final weatherProvider = Provider.of<WeatherProvider>(context);

    final String waterLevel = mqttProvider.waterLevel ?? '--';
    final String temperature = mqttProvider.temperature ?? '--';
    final String humidity = mqttProvider.humidity ?? '--';
    final String pm25 = weatherProvider.pm25 ?? '--';
    final String uvIndex = weatherProvider.uvIndex ?? '--';

    final double? pm25Value = double.tryParse(pm25);
    final String pm25Icon = pm25Value != null
        ? getPM25Icon(pm25Value)
        : 'assets/AQI_Icons/purple.svg';

    final bool isPortrait = MediaQuery
        .of(context)
        .orientation == Orientation.portrait;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.only(left: 10, bottom: 8, top: 3),
          color: Colors.black54,
          alignment: Alignment.centerLeft, // Ensures child aligns left
          child: isPortrait
              ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              // Prevent Row from filling extra space
              mainAxisAlignment: MainAxisAlignment.start,
              children: _buildParameterList(
                context,
                waterLevel,
                temperature,
                humidity,
                pm25,
                uvIndex,
                pm25Icon,
                isPortrait,
              ),
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildParameterList(
              context,
              waterLevel,
              temperature,
              humidity,
              pm25,
              uvIndex,
              pm25Icon,
              isPortrait,
            ),
          ),
        ),
      ),
    );
   }
  );
 }

  List<Widget> _buildParameterList(BuildContext context, String waterLevel,
      String temperature, String humidity, String pm25, String uvIndex,
      String pm25Icon, bool isPortrait,) {
    final spacing = isPortrait ? const SizedBox(width: 33) : const SizedBox(
        height: 40);

    // Safely parse values
    final double wLevel = double.tryParse(waterLevel) ?? 0;
    final double tempValue = double.tryParse(temperature) ?? 0;
    final double humidityValue = double.tryParse(humidity) ?? 0;
    final double pm25Value = double.tryParse(pm25) ?? 0;
    final double uvValue = double.tryParse(uvIndex) ?? 0;

    // === Volume-Based Fill Calculation ===
    const double tankHeight = 132; // cm
    const double tankDiameter = 109; // cm
    const double tankVolume = 979; // L (your real volume)

    double actualHeight = (tankHeight - wLevel).clamp(0.0, tankHeight); // From bottom
    double radius = tankDiameter / 2;
    double volume = 3.1416 * radius * radius * actualHeight / 1000; // cm³ to Liters
    double filledPercentage = (volume / tankVolume * 100).clamp(0, 100);
    String waterLevelDisplay = '${filledPercentage.toStringAsFixed(0)}%';

    final Color waterIconColor = getWaterLevelColor(filledPercentage);

    // Dummy data
    final List<double> waterData = List.filled(6, wLevel);
    final List<double> tempData = List.filled(6, tempValue);
    final List<double> humidityData = List.filled(6, humidityValue);
    final List<double> pm25Data = List.filled(6, pm25Value);
    final List<double> uvData = List.filled(6, uvValue);


    return [

      _parameterItem(
          context, 'assets/Parameters_Icons/WaterLevel.svg', waterLevelDisplay,
          'Water Level', waterData, iconColor: waterIconColor),
      spacing,
      _parameterItem(
          context, 'assets/Parameters_Icons/temperature.svg', '$temperature°C',
          'Temperature', tempData),
      spacing,
      _parameterItem(
          context, 'assets/Parameters_Icons/humidity.svg', '$humidity%',
          'Humidity', humidityData),
      spacing,
      _parameterItem(context, pm25Icon, pm25, 'PM2.5', pm25Data),
      spacing,
      _parameterItem(context, 'assets/Parameters_Icons/uv_index_2.svg', uvIndex,
          'UV Index', uvData),
    ];
  }

  Widget _parameterItem(BuildContext context, String iconPath, String value, String parameterType, List<double> dataPoints, {Color? iconColor,}) {
    final bool isAQIIcon = iconPath.contains('AQI_Icons');
    final double iconSize = isAQIIcon ? 17 : 24;

    return InkWell(
      onTap: () {
        if (parameterType == 'Water Level') {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => WaterLevel(parameterType: 'Water Level'),
          ));
        } else if (parameterType == 'Temperature') {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) =>
                TempGraph(dataPoints: dataPoints,
                    parameterType: 'Inside Temperature'),
          ));
        } else if (parameterType == 'Humidity') {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => GraphHumidity(dataPoints: dataPoints, parameterType: 'Humidity',),
          ));
        } else if (parameterType == 'PM2.5') {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) =>
                GraphAQI(dataPoints: dataPoints, parameterType: 'Air Quality'),
          ));
        } else if (parameterType == 'UV Index') {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => GraphUV(dataPoints: dataPoints, parameterType: 'UV Index',),
          ));
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconPath,
            height: iconSize,
            width: iconSize,
            color: iconColor, // 👈 apply dynamic color if available
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
                fontSize: 17, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
