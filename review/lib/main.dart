import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  LatLng? userLocation;
  MapController _mapController = MapController();

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
      _mapController.move(userLocation!, 12.0);  // Zoom to user's location
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Location Tracking App')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLocation ?? LatLng(0, 0), // Default to (0,0) initially
              initialZoom: 2.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
                maxZoom: 19,
              ),
              if (userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLocation!,
                      child: Builder(
                        builder: (context) {
                          return Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          );
                        }
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SemicircleFAB(
            latitude: userLocation!.latitude,
            longitude: userLocation!.longitude,
          ),
        ],
      ),
    );
  }
}

class SemicircleFAB extends StatefulWidget {
  @override
  final double latitude;
  final double longitude;

  const SemicircleFAB({super.key, required this.latitude, required this.longitude});



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



