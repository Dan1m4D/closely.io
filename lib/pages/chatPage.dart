import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:closely_io/classes/chatMessage.dart';
import 'package:closely_io/providers/gestureProvider.dart';
import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChatPage extends StatefulWidget {
  final String device;
  final String endpointId;

  const ChatPage({
    super.key,
    required this.device,
    required this.endpointId,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController _messageController = TextEditingController();
  List<ChatMessage> _messages = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // shake detector
  late StreamSubscription<AccelerometerEvent> _accelerometerStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _setupPayloadListener();
    _loadChatHistory();
    _accelerometerStreamSubscription =
        accelerometerEventStream().listen((event) {
      if (event.x.abs() > 1) {
        final gestureProvider =
            Provider.of<GestureProvider>(context, listen: false);
        gestureProvider.updateAccelerometerData(event);
        gestureProvider.detectShake(event);
      }
    });
  }

  @override
  void dispose() {
    _accelerometerStreamSubscription.cancel();
    super.dispose();
  }

  void _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('your_channel_id', 'your_channel_name',
            importance: Importance.max, priority: Priority.high);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, title, body, platformChannelSpecifics);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GestureProvider>(
      builder: (context, gestureProvider, child) {
        if (gestureProvider.isShaking) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Shake detected'),
                  content: const Text('Did you wave at your friend? 👋'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _messageController.text =
                            'Your friend is waving at you! 👋';
                        _sendMessage();
                        gestureProvider.resetValues();
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK'),
                    ),
                    TextButton(
                        onPressed: () {
                          gestureProvider.resetValues();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel')),
                  ],
                );
              });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Chat with ${widget.device}'),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _messages.map((message) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        child: Align(
                          alignment: message.isSentByMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: message.isSentByMe
                                  ? Colors.blue
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                color: message.isSentByMe
                                    ? Colors.white
                                    : Colors.black,
                                fontFamily: "",
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your message',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        _sendMessage();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setupPayloadListener() {
    try {
      Nearby().acceptConnection(
        widget.endpointId,
        onPayLoadRecieved: (endid, payload) async {
          if (payload.type == PayloadType.BYTES) {
            String receivedMessage = utf8.decode(payload.bytes!);
            setState(() {
              _messages
                  .add(ChatMessage(text: receivedMessage, isSentByMe: false));
              _saveChatHistory(); // Save received message to local storage
            });
            _showNotification(
                'New Message', receivedMessage); // Show notification
          }
        },
        onPayloadTransferUpdate: (endid, payloadTransferUpdate) {},
      );
    } catch (exception) {
      print(exception);
    }
  }

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(text: message, isSentByMe: true));
      });
      Nearby().sendBytesPayload(
        widget.endpointId,
        utf8.encode(message),
      );
      _saveChatHistory(); // Save sent message to local storage
      _messageController.clear();
    }
  }

  void _saveChatHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> messagesJson =
        _messages.map((message) => json.encode(message.toJson())).toList();
    await prefs.setStringList('chat_history', messagesJson);
  }

  Future<void> _loadChatHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? messagesJson = prefs.getStringList('chat_history');
    if (messagesJson != null) {
      setState(() {
        _messages = messagesJson
            .map((json) => ChatMessage.fromJson(jsonDecode(json)))
            .toList();
      });
    }
  }
}
