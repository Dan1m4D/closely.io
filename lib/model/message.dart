import 'package:closely_io/model/device.dart';

class Message{
  final bool sent;
  final Device to;
  final Device from;
  final String message;



  Message({required this.sent, required this.to, required this.from, required this.message});
}