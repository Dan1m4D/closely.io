import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  // external storage permission
  Future<void> _askPermissions() async {
    // external storage permission
    await Permission.storage.isGranted; // Check
    await Permission.storage.request(); // Ask
  }

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('closely');

    bool userExists = box.containsKey('user');

    // Ask for permissions
    _askPermissions();

    // Handle the user existence
    if (userExists) {
      Future.delayed(2.seconds, () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    } else {
      Future.delayed(2.seconds, () {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/lottie/loading.json', width: 400, height: 400),
            const SizedBox(height: 20),
            const Text(
              'Loading...',
              style: TextStyle(fontSize: 30),
            ),
          ],
        ),
      ),
    );
  }
}
