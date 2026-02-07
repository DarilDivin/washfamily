import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WashFamily')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(48.8566, 2.3522), // Paris default
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.washfamily.washfamily',
              ),
              const MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(48.8566, 2.3522),
                    width: 80,
                    height: 80,
                    child: Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        onTap: (index) {
          // TODO: Logic needed
        },
      ),
    );
  }
}
