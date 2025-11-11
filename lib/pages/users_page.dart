import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart';
import 'chat_page.dart';

class UsersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Usuarios'),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: chatService.getOtherUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(child: Text('No hay otros usuarios'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    //user.email[0].toUpperCase(),
                    (user.displayName ?? user.email)[0].toUpperCase(),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                //title: Text(user.displayName ?? user.email),
                title: Text(user.displayName ?? user.email),
                subtitle: Text(user.email),
                onTap: () async {
                  final chatId = await chatService.getOrCreateChat(user.id);
                  if (chatId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(chatId: chatId, otherUser: user),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}