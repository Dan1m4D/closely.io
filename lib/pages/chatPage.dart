import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChatPage extends StatefulWidget {
  final String device;
  final String endpointId;

  const ChatPage({Key? key, required this.device, required this.endpointId})
      : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController _messageController = TextEditingController();
  List<ChatMessage> _messages = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _setupPayloadListener();
    _loadChatHistory();
  }

  void _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('your_channel_id', 'your_channel_name',
            importance: Importance.max, priority: Priority.high);
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: Align(
                      alignment: message.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: message.isSentByMe ? Colors.blue : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          message.text,
                          style: TextStyle(color: message.isSentByMe ? Colors.white : Colors.black),
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
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
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
  }

  void _setupPayloadListener() {
    try {
      Nearby().acceptConnection(
        widget.endpointId,
        onPayLoadRecieved: (endid, payload) async {
          if (payload.type == PayloadType.BYTES) {
            String receivedMessage = String.fromCharCodes(payload.bytes!);
            setState(() {
              _messages.add(ChatMessage(text: receivedMessage, isSentByMe: false));
              _saveChatHistory(); // Save received message to local storage
            });
            _showNotification('New Message', receivedMessage); // Show notification
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
        Uint8List.fromList(message.codeUnits),
      );
      _saveChatHistory(); // Save sent message to local storage
      _messageController.clear();
    }
  }

  void _saveChatHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> messagesJson = _messages.map((message) => json.encode(message.toJson())).toList();
    await prefs.setStringList('chat_history', messagesJson);
  }

  Future<void> _loadChatHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? messagesJson = prefs.getStringList('chat_history');
    if (messagesJson != null) {
      setState(() {
        _messages = messagesJson.map((json) => ChatMessage.fromJson(jsonDecode(json))).toList();
      });
    }
  }
}

class ChatMessage {
  final String text;
  final bool isSentByMe;

  ChatMessage({required this.text, required this.isSentByMe});

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isSentByMe': isSentByMe,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isSentByMe: json['isSentByMe'],
    );
  }
}
