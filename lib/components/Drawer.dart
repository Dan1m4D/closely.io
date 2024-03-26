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
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          DrawerHeader(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Image(
                  image: AssetImage('assets/images/logo.png'),
                  height: 90,
                ),
                Text(
                  "Welcome,\n$user",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          MenuItem(
            child: ListTile(
              leading: Icon(
                Icons.home,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              title: Text(
                'H O M E',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          ),
          MenuItem(
            child: ListTile(
              leading: Icon(
                Icons.gesture,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              title: Text(
                'G E S T U R E S',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/gesture');
              },
            ),
          ),
          MenuItem(
            child: ListTile(
              leading: Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              title: Text(
                'S E T T I N G S',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onBackground),
              ),
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
