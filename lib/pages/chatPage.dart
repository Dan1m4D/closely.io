import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:closely_io/classes/chatMessage.dart';
import 'package:closely_io/providers/gestureProvider.dart';
import 'package:closely_io/providers/themeProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:camera/camera.dart';

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
  late CameraController _cameraController;

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _setupPayloadListener();
    _loadChatHistory();
    _initializeCamera();
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
                      _messageController.text = 'wave_gesture_detected';
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
                    child: const Text('Cancel'),
                  ),
                ],
              );
            },
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Chat with ${widget.device}'),
            actions: [
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  _clearChatHistory();
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _messages.map((message) {
                      if (message.imageBytes != null) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          child: Align(
                            alignment: message.isSentByMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.6,
                              ),
                              decoration: BoxDecoration(
                                color: message.isSentByMe
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.all(8.0),
                              child: Image.memory(
                                message.imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          child: Align(
                            alignment: message.isSentByMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              decoration: BoxDecoration(
                                color: message.isSentByMe
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[300],
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.all(8.0),
                              child: message.text! == "wave_gesture_detected"
                                  ? Image.asset(
                                      'assets/gifs/waving.gif') // Use Image.asset to display the GIF
                                  : Text(
                                      message.text!,
                                      style: TextStyle(
                                        color: message.isSentByMe
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      }
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
                    IconButton(
                      icon: const Icon(Icons.photo),
                      onPressed: () {
                        _openGallery();
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

  void _initializeCamera() async {
    final cameras = await availableCameras();
    //final firstCamera = cameras.first;
    final frontCamera = cameras.last;
    _cameraController = CameraController(frontCamera, ResolutionPreset.high);

    await _cameraController.initialize();
  }

  void _setupPayloadListener() {
    try {
      Nearby().acceptConnection(
        widget.endpointId,
        onPayLoadRecieved: (endid, payload) async {
          if (payload.type == PayloadType.BYTES) {
            if (_isImage(payload.bytes!)) {
              setState(() {
                _messages.add(ChatMessage(
                  imageBytes: payload.bytes!,
                  isSentByMe: false,
                ));
                _saveChatHistory();
              });
            } else {
              String receivedMessage = utf8.decode(payload.bytes!);
              setState(() {
                _messages.add(ChatMessage(
                  text: receivedMessage,
                  isSentByMe: false,
                ));
                _saveChatHistory();
                _showNotification('New Message', receivedMessage);
              });
            }
          }
        },
        onPayloadTransferUpdate: (endid, payloadTransferUpdate) {},
      );
    } catch (exception) {
      print(exception);
    }
  }

  bool _isImage(Uint8List bytes) {
    return bytes.length >= 2 &&
        bytes[0] == 0xFF &&
        (bytes[1] == 0xD8 || // JPEG
            bytes[1] == 0x89 || // PNG
            bytes[1] == 0x47 || // GIF
            bytes[1] == 0x49 || // TIFF
            bytes[1] == 0x42); // BMP
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

  void _openGallery() {
    if (!_cameraController.value.isInitialized) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Camera Preview"),
        content: CameraPreview(_cameraController),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha o diálogo sem capturar a imagem
            },
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fecha o diálogo
              _captureAndSendImage(); // Captura e envia a imagem
            },
            child: Text("Capture"),
          ),
        ],
      ),
    );
  }

  void _captureAndSendImage() async {
    try {
      final XFile? image = await _cameraController.takePicture();
      if (image == null) {
        return;
      }
      Uint8List imageBytes = await image.readAsBytes();
      Nearby().sendBytesPayload(widget.endpointId, imageBytes);
      setState(() {
        _messages.add(ChatMessage(
            imageBytes: imageBytes, isSentByMe: true)); // Add sent image
      });
      _saveChatHistory(); // Save sent message to local storage
    } catch (e) {
      print("Error capturing and sending image: $e");
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

  void _clearChatHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
    setState(() {
      _messages.clear();
    });
  }
}
