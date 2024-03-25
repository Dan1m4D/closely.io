import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class GesturePage extends StatefulWidget {
  const GesturePage({super.key});

  @override
  State<GesturePage> createState() => _GesturePageState();
}

class _GesturePageState extends State<GesturePage> {
  double _x = 0;
  double _y = 0;
  double _z = 0;
  double _max_x = 0;
  double _max_y = 0;
  double _max_z = 0;

  final bool _show = false;
  static const double threshold = 25;
  int _shakeCount = 0;
  StreamSubscription? _streamSubscription;
  bool _isShaking = false;

  @override
  void initState() {
    super.initState();
    _streamSubscription = accelerometerEventStream().listen((event) {
      if (event.x.abs() > _max_x) {
        setState(() {
          _max_x = event.x.abs();
        });
      }
      if (event.y.abs() > _max_y) {
        setState(() {
          _max_y = event.y.abs();
        });
      }
      if (event.z.abs() > _max_z) {
        setState(() {
          _max_z = event.z.abs();
        });
      }
      setState(() {
        _x = event.x;
        _y = event.y;
        _z = event.z;
      });
      detectShake(event);
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  void countShakes() {
    _shakeCount++;
  }

  void detectShake(AccelerometerEvent event) {
    if (event.x.abs() > threshold) {
      countShakes();
      if (!_isShaking && _shakeCount > 2) {
        setState(() {
          _isShaking = true;
          _shakeCount = 0;
        });
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Shake detected!"),
              content: const Text("Do you want to say hi?"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isShaking = false;
                    });
                  },
                  child: const Text(
                    "OK",
                  ),
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String x = _x.toStringAsFixed(1);
    String y = _y.toStringAsFixed(1);
    String z = _z.toStringAsFixed(1);

    String maxX = _max_x.toStringAsFixed(1);
    String maxY = _max_y.toStringAsFixed(1);
    String maxZ = _max_z.toStringAsFixed(1);

    bool show = _show;

    return Scaffold(
      appBar: AppBar(
        title: const Text("G E S T U R E S"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("X: $x; Max: $maxX"),
            Text("Y: $y; Max: $maxY"),
            Text("Z: $z; Max: $maxZ"),
            Text("Shake count: $_shakeCount"),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _max_x = 0;
                      _max_y = 0;
                      _max_z = 0;
                      _shakeCount = 0;
                    });
                  },
                  child: const Text("Reset max values"),
                ),
                ElevatedButton(
                  onPressed: () {
                    show = true;
                  },
                  child: const Text("Show dialog"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
