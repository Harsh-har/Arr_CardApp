import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {

  Future<Map<String, String>?> fetchAQIAndUV(double lat, double lon) async {
    try {
      final String url =
          'http://api.weatherapi.com/v1/current.json?key=e5971bfddae1455caf2100342252006&q=$lat,$lon&aqi=yes';

      print('🔁 Requesting AQI & UV: $url');

      final response = await http.get(Uri.parse(url));

      print('✅ Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final double pm25 = data['current']['air_quality']['pm2_5'];
        final double uv = data['current']['uv'];

        return {
          'pm2_5': pm25.toStringAsFixed(1),
          'uv': uv.toString()
        };
      }
    } catch (e) {
      print('❌ Error fetching AQI/UV: $e');
    }

    return null;
  }
}
