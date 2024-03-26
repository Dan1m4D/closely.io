import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Fetching data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
