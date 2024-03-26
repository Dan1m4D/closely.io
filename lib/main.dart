import 'package:closely_io/pages/gesturePage.dart';
import 'package:closely_io/pages/homePage.dart';
import 'package:closely_io/pages/loginPage.dart';
import 'package:closely_io/pages/settingsPage.dart';
import 'package:closely_io/providers/themeProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/color_schemes.g.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
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
