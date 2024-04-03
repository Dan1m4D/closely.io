import 'package:closely_io/components/MenuItem.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late Position position;
  final box = Hive.box('closely');
  List<String> marksCoords = [];
  final user = Hive.box('closely').get('user');

  void _loadReceivedCoordinates() {
    List<String>? storedCoordinates = box.get('marks');
    if (storedCoordinates != null) {
      setState(() {
        marksCoords = List<String>.from(storedCoordinates);
      });
    }
  }

  Future<Position> _getCurrentPosition() async {
    return Geolocator.getCurrentPosition();
  }

  @override
  void initState() {
    super.initState();
    _loadReceivedCoordinates();
    _getCurrentPosition().then((value) {
      setState(() {
        position = value;
        marksCoords.add('$user:${position.latitude}:${position.longitude}');

      });
    });
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
                        markers: marksCoords.map((item) {
                          final coords = item.split(':');
                          final name = coords[0];
                          final lat = double.parse(coords[1]);
                          final long = double.parse(coords[2]);
                          return Marker(
                            width: 80.0,
                            height: 80.0,
                            point: LatLng(lat, long),
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 50,
                                  color: Colors.red,
                                ),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                        fontSize: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(10),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Where My Frinds?",
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: marksCoords.map((item) {
                            final coords = item.split(':');
                            final name = coords[0];
                            final lat =
                                double.parse(coords[1]).toStringAsFixed(2);
                            final long =
                                double.parse(coords[2]).toStringAsFixed(2);
                            return (MenuItem(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer),
                                  ),
                                  Text(
                                    '($lat, $long)',
                                    style: TextStyle(
                                        fontSize: 15,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer),
                                  ),
                                ],
                              ),
                            ));
                          }).toList(),
                        ),
                      )
                    ],
                  ),
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
