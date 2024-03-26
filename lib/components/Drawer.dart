import 'package:closely_io/components/MenuItem.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  
  @override
  Widget build(BuildContext context) {
    var box = Hive.box('closely');
    final user = box.get('user', defaultValue: '');
    return Drawer(
      backgroundColor: Theme.of(context).primaryColor,
      child: Column(
        children: [
          DrawerHeader(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/images/logo.png'),
                ),
                Text(
                  user,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          MenuItem(
            child: ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          ),
          MenuItem(
            child: ListTile(
              leading: const Icon(Icons.gesture),
              title: const Text('Gesture'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/gesture');
              },
            ),
          ),
          MenuItem(
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/settings');
              },
            ),
          ),
        ],
      ),
    );
  }
}
