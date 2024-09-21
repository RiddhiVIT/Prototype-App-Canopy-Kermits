import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'weather_forecast_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Tracking App',
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
  late WebViewController _controller;
  LatLng? userLocation;

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

    // Send user location to the WebView
    if (userLocation != null) {
      _controller.evaluateJavascript(
          'updateMap(${userLocation!.latitude}, ${userLocation!.longitude});');
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeatherForecastPage(
          latitude: userLocation!.latitude,
          longitude: userLocation!.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Location Tracking App')),
      body: Stack(
        children: [
          WebView(
            initialUrl: Uri.dataFromString(
              '''
          <!DOCTYPE html>
          <html>
          <head>
              <title>Map</title>
              <meta name="viewport" content="initial-scale=1.0, user-scalable=no" />
              <style>
                  html, body { height: 100%; margin: 0; padding: 0; }
                  #map { height: 100%; }
              </style>
              <script src="https://unpkg.com/leaflet/dist/leaflet.js"></script>
              <link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css" />
          </head>
          <body>
              <div id="map"></div>
              <script>
                  var map = L.map('map').setView([0, 0], 2);
                  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                      maxZoom: 19,
                  }).addTo(map);

                  function updateMap(lat, lon) {
                      map.setView([lat, lon], 12);
                      L.marker([lat, lon]).addTo(map).bindPopup('You are here!');
                  }
              </script>
          </body>
          </html>
          ''',
              mimeType: 'text/html',
            ).toString(),
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController controller) {
              _controller = controller;
            },
          ),
          SemicircleFAB(),
        ],
      ),
    );
  }
}

class SemicircleFAB extends StatefulWidget {
  @override
  State<SemicircleFAB> createState() => _SemicircleFABState();
}

class _SemicircleFABState extends State<SemicircleFAB> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: MediaQuery.of(context).size.width / 4 -
          (MediaQuery.of(context).size.shortestSide / 4),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => WeatherForecastPage(
              latitude: userLocation!.latitude,
              longitude: userLocation!.longitude,
            ),);
        },
        child: Container(
          width: MediaQuery.of(context).size.shortestSide,
          height: MediaQuery.of(context).size.shortestSide / 4,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              bottomLeft:
                  Radius.circular(MediaQuery.of(context).size.shortestSide),
              bottomRight:
                  Radius.circular(MediaQuery.of(context).size.shortestSide),
            ),
          ),
          child: Center(
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Second Page')),
      body: Center(
          child: Text('Welcome to the Second Page!',
              style: TextStyle(fontSize: 24))),
    );
  }
}

class LatLng {
  final double latitude;
  final double longitude;

  LatLng(this.latitude, this.longitude);
}
