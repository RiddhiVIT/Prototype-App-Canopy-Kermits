import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';

class WeatherForecastPage extends StatefulWidget {
  final double latitude;
  final double longitude;

  WeatherForecastPage({required this.latitude, required this.longitude});

  @override
  _WeatherForecastPageState createState() => _WeatherForecastPageState();
}

class _WeatherForecastPageState extends State<WeatherForecastPage> {
  String apiKey = '69c284512329438da7184210242109'; // Replace with your WeatherAPI key
  Map<String, dynamic>? weatherData;

  // Mapping for weather conditions to Lottie animations
  Map<String, String> dayAnimationMap = {
    'Sunny': 'assets/sunny anime.json',
    'Partly cloudy': 'assets/partly cloudy day.json',
    'Cloudy': 'assets/cloudy.json',
    'Rain': 'assets/just rain.json',
    'Patchy rain nearby': 'assets/just rain.json',
    'Moderate or heavy rain with thunder': 'assets/thunder and rain.json',
    // More mappings after updates
  };

  Map<String, String> nightAnimationMap = {
    'Clear': 'assets/clear night.json',
    'Partly cloudy': 'assets/partly cloudy day.json',
    'Cloudy': 'assets/cloudy.json',
    'Rain': 'assets/night rain.json',
    'Moderate or heavy rain with thunder': 'assets/thunder and rain.json',
    'Patchy rain nearby': 'assets/just rain.json',
    // More Mappings after updates
  };

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  // Fetch the weather data using WeatherAPI
  Future<void> fetchWeather() async {
    final url =
        'http://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=${widget.latitude},${widget.longitude}&days=1';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Forecast'),
      ),
      body: Center(
        child: weatherData == null
            ? CircularProgressIndicator()
            : ListView.builder(
          itemCount: weatherData!['forecast']['forecastday'].length,
          itemBuilder: (context, index) {
            var forecast = weatherData!['forecast']['forecastday'][index];
            var dayCondition = forecast['day']['condition']['text'];
            var nightCondition = forecast['astro']['moonrise']; // Just a placeholder for night condition logic

            // Determine if it's day or night
            String animationPath;
            if (DateTime.now().hour >= 6 && DateTime.now().hour < 18) {
              // Daytime
              animationPath = dayAnimationMap[dayCondition] ?? 'assets/sunny anime.json'; // Default day animation
            } else {
              // Nighttime
              animationPath = nightAnimationMap[nightCondition] ?? 'assets/clear night.json'; // Default night animation
            }

            return ListTile(
              title: Text(forecast['date']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Condition: ${dayCondition}'),
                  Text('Max Temp: ${forecast['day']['maxtemp_c']}°C'),
                  Text('Min Temp: ${forecast['day']['mintemp_c']}°C'),
                ],
              ),
              leading: Lottie.asset(animationPath),
            );
          },
        ),
      ),
    );
  }
}
