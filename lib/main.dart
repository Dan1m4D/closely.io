import 'package:closely_io/pages/gesturePage.dart';
import 'package:closely_io/pages/homePage.dart';
import 'package:closely_io/pages/loginPage.dart';
import 'package:closely_io/pages/settingsPage.dart';
import 'package:closely_io/providers/themeProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

void main() async {
  // initialize hive
  await Hive.initFlutter();

  // open the box
  await Hive.openBox('closely');

  // testing purposes
  Animate.restartOnHotReload;

  // register the adapter
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// verify if user exists
  bool userExists() {
    var _box = Hive.box('closely');
    return _box.containsKey('user');
  }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Closely.io',
        theme: Provider.of<ThemeProvider>(context).theme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/gesture': (context) => const GesturePage(),
          '/settings': (context) => const SettingsPage(),
        });
  }
}
