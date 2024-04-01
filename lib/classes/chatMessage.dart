import 'dart:convert';
import 'dart:typed_data';

class ChatMessage {
  final String? text;
  final Uint8List? imageBytes;
  final bool isSentByMe;

  ChatMessage({
    this.text,
    this.imageBytes,
    required this.isSentByMe,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
      'isSentByMe': isSentByMe,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      imageBytes: json['imageBytes'] != null
          ? base64Decode(json['imageBytes'])
          : null,
      isSentByMe: json['isSentByMe'],
    );
  }
}