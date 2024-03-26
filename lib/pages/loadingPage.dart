import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lottie/lottie.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('closely');

    bool userExists = box.containsKey('user');

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
