import 'package:flutter/material.dart';
import 'API_AQI_UV.dart';

class WeatherProvider extends ChangeNotifier {
  String pm25 = '--';
  String uvIndex = '--';

  Future<void> fetchAQIAndUV() async {
    final weatherService = WeatherService();
    final result = await weatherService.fetchAQIAndUV(28.9845, 77.7064); // Meerut

    if (result != null) {
      pm25 = result['pm2_5']!;
      uvIndex = result['uv']!;
      notifyListeners();

      print('✅ PM2.5=$pm25 µg/m³, UV Index=$uvIndex');

      // 🌫️ Notification logic for PM2.5
      final pmValue = double.tryParse(pm25);
      if (pmValue != null && pmValue > 200) {
        // NotificationService().showNotification(
        //   id: 1,
        //   title: '⚠️ Air Quality Alert',
        //   body: 'Air Quality level is $pm25 µg/m³ — Air quality is Dangerous!',
        // );
      } else if (pmValue != null && pmValue > 300) {
        // NotificationService().showNotification(
        //   id: 1,
        //   title: '⚠️ Air Quality Alert',
        //   body: 'Air Quality level is $pm25 µg/m³ — Air quality is hazardous!',
        // );
      }
    } else {
      print("❌ Failed to fetch PM2.5/UV data");
    }
  }
}
