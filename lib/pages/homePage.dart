import 'package:closely_io/components/Drawer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: Form(
          key: const Key('form'),
          child: Column(
            children: [
              const Text('Welcome to Closely.io'),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Enter your name',
                ),
              ),

              ],
          ),
        ),
      ),
    );
  }
}
