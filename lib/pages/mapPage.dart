import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late Position position;

  Future<Position> _getCurrentPosition() async {
    return Geolocator.getCurrentPosition();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Position>(
      future: _getCurrentPosition(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final position = snapshot.data!;
          double lat = position.latitude;
          double long = position.longitude;
          return Scaffold(
            appBar: AppBar(
              title: const Text('M A P  P A G E'),
              centerTitle: true,
            ),
            body: Center(
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(lat, long),
                      initialZoom: 20,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom |
                            InteractiveFlag.doubleTapZoom |
                            InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      openStreetMapTileLater,
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 80.0,
                            height: 80.0,
                            point: LatLng(lat, long),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.location_on,
                              size: 50,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 50),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text('Latitude: $lat'),
                            const SizedBox(width: 20),
                            Text('Longitude: $long'),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

TileLayer get openStreetMapTileLater => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    );
