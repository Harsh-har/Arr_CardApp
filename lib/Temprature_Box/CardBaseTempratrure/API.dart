import 'dart:convert';
import 'package:http/http.dart' as http;

class CardWeatherService {
  Future<Map<String, String>?> cardFetchAQIAndUV(double lat, double lon) async {
    try {
      final String url =
          'http://api.weatherapi.com/v1/current.json?key=e5971bfddae1455caf2100342252006&q=$lat,$lon&aqi=yes';

      print('🔁 Requesting AQI & UV: $url');

      final response = await http.get(Uri.parse(url));

      print('✅ Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract values
        final double pm25 = data['current']['air_quality']['pm2_5'];
        final double uv = data['current']['uv'];
        final double tempC = data['current']['temp_c'];
        final int humidity = data['current']['humidity'];

        return {
          'pm2_5': pm25.toStringAsFixed(1),
          'uv': uv.toString(),
          'temp': tempC.toStringAsFixed(1),
          'humidity': humidity.toString()
        };
      }
    } catch (e) {
      print('❌ Error fetching AQI/UV: $e');
    }

    return null;
  }
}
