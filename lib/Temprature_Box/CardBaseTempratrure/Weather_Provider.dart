import 'package:flutter/cupertino.dart';
import 'API.dart';

class CardBaseWeatherProvider extends ChangeNotifier {
  String pm25 = '--';
  String uvIndex = '--';
  String temperature = '--';
  String humidity = '--';

  Future<void> cardFetchAQIAndUV() async {
    final cardWeatherService = CardWeatherService();
    final result = await cardWeatherService.cardFetchAQIAndUV(13.38391, 80.07582);

    if (result != null) {
      pm25 = result['pm2_5'] ?? '--';
      uvIndex = result['uv'] ?? '--';
      temperature = result['temp'] ?? '--';
      humidity = result['humidity'] ?? '--';
      notifyListeners();

      print('✅ PM2.5=$pm25, UV=$uvIndex, Temp=$temperature°C, Humidity=$humidity%');
    } else {
      print("❌ Failed to fetch weather data");
    }
  }
}
