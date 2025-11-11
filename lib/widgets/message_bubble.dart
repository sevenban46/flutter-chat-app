import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final AppUser otherUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.otherUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  otherUser.displayName ?? otherUser.email, // ← USAR otherUser
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}