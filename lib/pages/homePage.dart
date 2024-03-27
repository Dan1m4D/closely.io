import 'package:closely_io/components/layout/Drawer.dart';
import 'package:closely_io/components/layout/Hero.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  Future<void> _askPermissions() async {
    // location permission
    await Permission.location.isGranted; // Check
    await Permission.location.request(); // Ask
    

    // Bluetooth permissions
    bool granted = !(await Future.wait([
      // Check
      Permission.bluetooth.isGranted,
      Permission.bluetoothAdvertise.isGranted,
      Permission.bluetoothConnect.isGranted,
      Permission.bluetoothScan.isGranted,
    ]))
        .any((element) => false);
    [
      // Ask
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
    ].request();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _askPermissions();
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      drawer: const AppDrawer(),
      body: const Column(
        children: [AppHero(), Text('Home Page')],
      ),
    );
  }
}
