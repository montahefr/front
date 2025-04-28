// TODO Implement this library.import 'dart:convert';
import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = 'b80610e9a3611852acad5e733a120377';  // replace with your API key
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  Future<Map<String, dynamic>> getWeather(String cityName) async {
    final url = '$_baseUrl?q=$cityName&appid=$_apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load weather');
    }
  }
}