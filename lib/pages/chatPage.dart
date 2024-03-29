import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nearby_connections/nearby_connections.dart';

class ChatPage extends StatefulWidget {
  final String device;
  final String endpointId; // ID do dispositivo conectado

  const ChatPage({Key? key, required this.device, required this.endpointId})
      : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController _messageController = TextEditingController();
  List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    // Configurar a recepção de payloads de bytes
    _setupPayloadListener();
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
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[index]),
                );
              },
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
              _messages.add(receivedMessage);
            });
          }
        },
        onPayloadTransferUpdate: (endid, payloadTransferUpdate) {},
      );
    } catch (exception) {
      // Handle any exceptions
      print(exception);
    }
  }

  void _sendMessage() {
    String message = _messageController.text.trim();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add("Me: $message");
      });
      // Enviar a mensagem para o dispositivo correspondente
      Nearby().sendBytesPayload(
        widget.endpointId,
        Uint8List.fromList(message.codeUnits),
      );
      _messageController.clear();
    }
  }
}
