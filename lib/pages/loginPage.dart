import 'package:closely_io/components/FadeTransition.dart';
import 'package:closely_io/pages/homePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _box = Hive.box('closely');
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  ValueNotifier<bool> _started = ValueNotifier(false);

  // add user
  void addUser(String name) {
    _box.put('user', name);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.primaryContainer,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Hello ',
                    style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.waving_hand, size: 60, color: Colors.yellow)
                      .animate(
                    onPlay: (controller) {
                      controller.repeat(reverse: true);
                    },
                  ).rotate(
                    begin: -0.05,
                    end: 0.05,
                    curve: Curves.easeInOut,
                  ),
                ],
              ),
              SizedBox(
                width: 300,
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: TextFormField(
                    controller: _textController,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 40,
                        fontStyle: FontStyle.italic),
                    decoration: InputDecoration(
                      hintText: 'You',
                      hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 30,
                          fontStyle: FontStyle.italic),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty || value == "") {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const SizedBox(
                width: 300,
                child: Text(
                  "Ready to get closer?",
                  style: TextStyle(fontSize: 45),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ValueListenableBuilder(
                valueListenable: _started,
                builder: (context, value, child) => ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      addUser(_textController.text);
                      _started.value = true;
                      Navigator.pushReplacement(
                        context,
                        FadeInRoute(page: const HomePage(), routeName: "/home"),
                      );
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.arrow_forward, size: 40),
                  ),
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(),
                    )
                    .shimmer(
                      duration: const Duration(seconds: 1),
                      delay: 5.seconds,
                      color: Theme.of(context).colorScheme.primaryContainer,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
