import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'weather_forecast_page.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shuttle Stalking App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? userLocation;
  LatLng? desiredLocation;
  MapController _mapController = MapController();
  double? routeDistance; // Distance in meters
  String? estimatedTimeinSeconds;

  get formattedTime => formattedTime; // Time as a string

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });

    if (userLocation != null) {
      _mapController.move(userLocation!, 12.0); // Zoom to user's location
    }
  }

  void _addDesiredLocation(LatLng location) {
    // Example calculation, replace with your routing logic
    if (userLocation != null) {
      setState(() {
        desiredLocation = location;
        routeDistance = Geolocator.distanceBetween(userLocation!.latitude,
            userLocation!.longitude, location.latitude, location.longitude);
        estimatedTimeinSeconds = (routeDistance! / 1.4).toStringAsFixed(2); // Assuming average speed of 1.4 m/s (about 5 km/h)
        
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shuttle Stalking App')),
      body: GestureDetector(
        onDoubleTapDown: (details) {
          final position = details.localPosition;
          final size = MediaQuery.of(context).size;
          final tapPosition = LatLng(
            userLocation!.latitude +
                (position.dy / size.height) * 0.01, // Adjust as needed
            userLocation!.longitude +
                (position.dx / size.width) * 0.01, // Adjust as needed
          );
          _addDesiredLocation(tapPosition);
        },
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter:
                userLocation ?? LatLng(0, 0), // Default to (0,0) initially
                initialZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: ['a', 'b', 'c'],
                  maxZoom: 19,
                ),
                if (userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: userLocation!,
                        child: Builder(builder: (context) {
                          return Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          );
                        }),
                      ),
                      if (desiredLocation != null)
                        Marker(
                          point: desiredLocation!,
                          child: Builder(builder: (context) {
                            return Column(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                                // Tooltip or overlay with distance and time
                                Container(
                                  padding: EdgeInsets.all(5),
                                  color: Colors.white,
                                  child: Column(
                                    children: [
                                      Text(
                                        'Distance: ${routeDistance?.toStringAsFixed(2)} m',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      Text(
                                        'Estimated Time: ${estimatedTimeinSeconds ?? 'calculating...'} s',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                    ],
                  ),
              ],
            ),
            if (desiredLocation != null && routeDistance != null)
              Positioned(
                bottom: 20,
                left: 20,
                child: Container(
                  padding: EdgeInsets.all(10),
                  color: Colors.black54,
                  child: Text(
                    'Distance: ${routeDistance?.toStringAsFixed(2)} m\nEstimated Time: ${estimatedTimeinSeconds} s',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            SemicircleFAB(
              latitude: userLocation!.latitude,
              longitude: userLocation!.longitude,
            ),
          ],
        ),
      ),
    );
  }
}



  class SemicircleFAB extends StatefulWidget {
  @override
  final double latitude;
  final double longitude;

  const SemicircleFAB(
      {super.key, required this.latitude, required this.longitude});

  State<SemicircleFAB> createState() => _SemicircleFABState();
}

class _SemicircleFABState extends State<SemicircleFAB> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchWeather();
  }

  final String apiKey = '69c284512329438da7184210242109';
  Map<String, dynamic>? weatherData;

  Map<String, String> dayAnimationMap = {
    'Sunny': 'assets/sunny anime.json',
    'Partly cloudy': 'assets/partly cloudy day.json',
    'Cloudy': 'assets/cloudy.json',
    'Rain': 'assets/just rain.json',
    'Patchy rain nearby': 'assets/just rain.json',
    'Moderate or heavy rain with thunder': 'assets/thunder and rain.json',
    'Moderate rain': 'assets/just rain.json'
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

  Future<void> fetchWeather() async {
    final url =
        'http://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=${widget.latitude},${widget.longitude}&days=1';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          debugPrint("here");
          debugPrint(weatherData.toString());
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
    return Positioned(
      top: 0,
      left: MediaQuery.of(context).size.width / 4 -
          (MediaQuery.of(context).size.shortestSide / 4),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WeatherForecastPage(
                latitude: widget.latitude,
                longitude: widget.longitude,
              ),
            ),
          );
        },
        child: Container(
          width: MediaQuery.of(context).size.shortestSide,
          height: MediaQuery.of(context).size.shortestSide / 4,
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: BorderRadius.only(
              bottomLeft:
                  Radius.circular(MediaQuery.of(context).size.shortestSide),
              bottomRight:
                  Radius.circular(MediaQuery.of(context).size.shortestSide),
            ),
          ),
          child: Stack(
            children: [
              // Ensure the ListView has a size
              Positioned.fill(
                child: weatherData == null
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount:
                            weatherData!['forecast']['forecastday'].length,
                        itemBuilder: (context, index) {
                          var forecast =
                              weatherData!['forecast']['forecastday'][index];
                          var dayCondition =
                              forecast['day']['condition']['text'];
                          var nightCondition = forecast['astro']['moonrise'];

                          String animationPath;
                          if (DateTime.now().hour >= 6 &&
                              DateTime.now().hour < 18) {
                            animationPath = dayAnimationMap[dayCondition] ??
                                'assets/sunny anime.json';
                          } else {
                            animationPath = nightAnimationMap[nightCondition] ??
                                'assets/clear night.json';
                          }
                          return SizedBox(
                            width: 100,
                            height: 100,
                            child: lottie.Lottie.asset(animationPath),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
