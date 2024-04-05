import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'chatPage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:closely_io/components/layout/Drawer.dart';
import 'package:closely_io/components/layout/Hero.dart';

import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final box = Hive.box('closely');
  List<String> marksCoords = [];
  late String userName =
      box.get('user', defaultValue: ''); // Replace with your username
  late Strategy strategy = Strategy.P2P_STAR; // Adjust strategy as needed
  Map<String, ConnectionInfo> endpointMap = {};
  Position? position;

  late final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<Position> _getCurrentPosition() async {
    return Geolocator.getCurrentPosition();
  }

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _askPermissions();
    _getCurrentPosition().then((value) {
      setState(() {
        position = value;
      });
    });
  }

  void _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> _askPermissions() async {
    // Location permission
    await Permission.location.isGranted; // Check
    await Permission.location.request(); // Ask

    bool granted = !(await Future.wait([
      // Check
      Permission.bluetooth.isGranted,
      Permission.bluetoothAdvertise.isGranted,
      Permission.bluetoothConnect.isGranted,
      Permission.bluetoothScan.isGranted,
      Permission.nearbyWifiDevices.isGranted,
      Permission.storage.isGranted,
    ]))
        .any((element) => false);
    [
      // Ask
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
      Permission.storage,
      Permission.notification,
    ].request();
  }

  Future<void> _startDiscovery() async {
    try {
      bool a = await Nearby().startDiscovery(
        userName,
        strategy,
        onEndpointFound: (id, name, serviceId) {
          // show sheet automatically to request connection
          showModalBottomSheet(
            context: context,
            builder: (builder) {
              return Center(
                child: Column(
                  children: <Widget>[
                    Text("id: $id"),
                    Text("Name: $name"),
                    Text("ServiceId: $serviceId"),
                    ElevatedButton(
                      child: const Text("Request Connection"),
                      onPressed: () {
                        Navigator.pop(context);
                        Nearby().requestConnection(
                          userName,
                          id,
                          onConnectionInitiated: (id, info) {
                            onConnectionInit(id, info);
                          },
                          onConnectionResult: (id, status) {},
                          onDisconnected: (id) {
                            setState(() {
                              endpointMap.remove(id);
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        onEndpointLost: (id) {
          showSnackbar(
              "Lost discovered Endpoint: ${endpointMap[id]?.endpointName}, id $id");
        },
      );
      showSnackbar("DISCOVERING: $a"); // SET STATE TO LOAD
    } catch (exception) {
      // showSnackbar('Discovery Error: $exception');
      if (await Permission.nearbyWifiDevices.isDenied) {
        Permission.nearbyWifiDevices.request();
      }

      // Handle platform exceptions like unable to start Bluetooth or insufficient permissions
    }
  }

  Future<void> _startAdvertising() async {
    try {
      bool a = await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: onConnectionInit,
        onConnectionResult: (id, status) {
        },
        onDisconnected: (id) {
          showSnackbar(
              "Disconnected: ${endpointMap[id]!.endpointName}, id $id");
          setState(() {
            endpointMap.remove(id);
          });
        },
      );
    } catch (exception) {
      //print('Advertising Error: $exception');
      // Handle platform exceptions like unable to start Bluetooth or insufficient permissions
    }
  }

  void showSnackbar(dynamic a) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
    ));
  }

  void onConnectionInit(String id, ConnectionInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Center(
          child: Column(
            children: <Widget>[
              Text("id: $id"),
              Text("Token: ${info.authenticationToken}"),
              Text("Name${info.endpointName}"),
              Text("Incoming: ${info.isIncomingConnection}"),
              ElevatedButton(
                child: const Text("Accept Connection"),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    endpointMap[id] = info;
                  });
                  Nearby().acceptConnection(
                    id,
                    onPayLoadRecieved: (endid, payload) async {
                      if (payload.type == PayloadType.BYTES) {
                        String str = String.fromCharCodes(payload.bytes!);
                       // showSnackbar("$endid: $str");

                        if (str.contains(':')) {
                          // used for file payload as file payload is mapped as
                          // payloadId:filename
                          int payloadId = int.parse(str.split(':')[0]);
                          String fileName = (str.split(':')[1]);
                        }
                      }
                    },
                    onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
                      if (payloadTransferUpdate.status ==
                          PayloadStatus.IN_PROGRESS) {
                        print(payloadTransferUpdate.bytesTransferred);
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.FAILURE) {
                        print("failed");
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.SUCCESS) {
                        // showSnackbar(
                            //"$endid success, total bytes = ${payloadTransferUpdate.totalBytes}");
                      }
                    },
                  );

                  String coordinates =
                      "${position!.latitude}:${position!.longitude}";
                  Nearby().sendBytesPayload(id, utf8.encode(coordinates));

                  _showNotification(
                    'Connection Accepted',
                    'Connected to ${info.endpointName}',
                  );
                },
              ),
              ElevatedButton(
                child: const Text("Reject Connection"),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await Nearby().rejectConnection(id);
                  } catch (e) {
                    // showSnackbar(e);
                  }
                },
              ),
            ],
          ),
        );
      },
    );

    Nearby().acceptConnection(
      id,
      onPayLoadRecieved: (endid, payload) async {
        if (payload.type == PayloadType.BYTES) {
          String str = String.fromCharCodes(payload.bytes!);
          print("====================================");
          print('Received coordinates: $str');
          print("info: $info.endpointName");
          print("====================================");
          _addReceivedCoordinates("${info.endpointName}:$str");
          // showSnackbar("Received coordinates from $endid: $str");
        }
      },
      onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
        if (payloadTransferUpdate.status == PayloadStatus.IN_PROGRESS) {
          print(payloadTransferUpdate.bytesTransferred);
        } else if (payloadTransferUpdate.status == PayloadStatus.FAILURE) {
          print("failed");
          // showSnackbar("Failed to receive coordinates from $endid");
        } else if (payloadTransferUpdate.status == PayloadStatus.SUCCESS) {
          // showSnackbar("Received coordinates successfully from $endid");
        }
      },
    );
  }

  void _addReceivedCoordinates(String coordinates) {
    setState(() {
      marksCoords.add(coordinates);
      print("====================================");
      print('Received coordinates: $marksCoords');
      print("====================================");
      // Store the updated list in Hive
      box.put('marks', marksCoords);
    });
  }

  // Function to load previously received coordinates from Hive
  void _loadReceivedCoordinates() {
    List<String>? storedCoordinates = box.get('marks', defaultValue: []);
    if (storedCoordinates != null) {
      setState(() {
        marksCoords = List<String>.from(storedCoordinates);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const AppHero(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _startDiscovery, // Start discovering nearby devices
                child: const Text(
                  'Search',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              ElevatedButton(
                onPressed: _startAdvertising, // Start advertising
                child: const Text(
                  'Advertise',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.all(10.0),
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Nearby Devices',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: endpointMap.length,
              itemBuilder: (context, index) {
                final key = endpointMap.keys.elementAt(index);
                late final String endpointName = endpointMap[key]!.endpointName;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.background,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10), // Border radius
                  ),
                  margin: EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 10), // Margin around each ListTile
                  child: ListTile(
                    title: Text(endpointName),
                    subtitle: Text(key),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            device: endpointName,
                            endpointId: key,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
