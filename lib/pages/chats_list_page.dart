import 'package:chat_app/pages/users_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/presence_service.dart';
import 'chat_page.dart';

class ChatsListPage extends StatelessWidget {
  const ChatsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);

    void logout() async {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      // El AuthWrapper en main.dart se encargará de redirigir al login
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UsersPage()),
              );
            },
          ),
          IconButton( // ← NUEVO BOTÓN
            icon: Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: StreamBuilder<List<Chat>>(
        stream: chatService.getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No tienes chats'),
                  SizedBox(height: 8),
                  Text('Presiona el botón + para empezar uno nuevo'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat.participants.firstWhere(
                    (id) => id != chatService.getCurrentUserId(),
              );

              return FutureBuilder<AppUser?>(
                future: chatService.getUser(otherUserId),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.transparent,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (user?.displayName ?? user?.email ?? '?')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (user?.isOnline == true) // ← Mostrar indicador de online
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            )
                        ],
                      ),
                      title: Text(user?.displayName ?? user?.email ?? 'Usuario'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chat.lastMessage ?? 'Sin mensajes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: chat.lastMessage != null ? FontWeight.normal : FontWeight.w300,
                            ),
                          ),
                          SizedBox(height: 2),
                          /*StreamBuilder<AppUser?>(
                            stream: Provider.of<PresenceService>(context)
                                .getUserPresenceStream(otherUserId),
                            builder: (context, presenceSnapshot) {
                              final presenceUser = presenceSnapshot.data;
                              final isOnline = presenceUser?.isOnline ?? false;

                              return Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: isOnline ? Colors.green : Colors.grey,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    isOnline ? 'En línea' : 'Desconectado',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isOnline ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),*/
                        ],
                      ),
                      trailing: chat.lastMessageTime != null
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(chat.lastMessageTime!),
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          if (chat.getUnreadCountForUser(chatService.getCurrentUserId() ?? '') > 0)
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              padding: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${chat.getUnreadCountForUser(chatService.getCurrentUserId() ?? '') > 9 ? '9+' : chat.getUnreadCountForUser(chatService.getCurrentUserId() ?? '')}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      )
                          : null,
                      onTap: () {
                        if (user != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(chatId: chat.id, otherUser: user),
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UsersPage()),
          );
        },
        child: Icon(Icons.chat),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(time).inDays == 1) {
      return 'Ayer';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}