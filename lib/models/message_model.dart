import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String text;
  final String senderEmail;
  final String senderId;
  final DateTime timestamp;
  final String chatId;

  Message({
    required this.id,
    required this.text,
    required this.senderEmail,
    required this.senderId,
    required this.timestamp,
    required this.chatId,
  });

  factory Message.fromFirestore(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      text: data['text'] ?? '',
      senderEmail: data['senderEmail'] ?? '',
      senderId: data['senderId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      chatId: data['chatId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'text': text,
      'senderEmail': senderEmail,
      'senderId': senderId,
      'timestamp': timestamp,
      'chatId': chatId,
    };
  }
}