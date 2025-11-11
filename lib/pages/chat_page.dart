import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/presence_service.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final AppUser otherUser;

  const ChatPage({
    Key? key,
    required this.chatId,
    required this.otherUser,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _resetUnreadCount();
  }

  void _resetUnreadCount() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final currentUserId = chatService.getCurrentUserId();

    if (currentUserId != null) {
      await chatService.resetUnreadCount(widget.chatId, currentUserId);
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty) {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.sendMessage(widget.chatId, _messageController.text.trim());
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'desconocido';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) return 'ahora mismo';
    if (difference.inMinutes < 60) return 'hace ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'hace ${difference.inHours} h';
    if (difference.inDays == 1) return 'ayer';
    return 'hace ${difference.inDays} días';
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUser.displayName ?? widget.otherUser.email),
            StreamBuilder<AppUser?>(
              stream: Provider.of<PresenceService>(context)
                  .getUserPresenceStream(widget.otherUser.id),
              builder: (context, snapshot) {
                final user = snapshot.data;
                final isOnline = user?.isOnline ?? false;
                final lastSeen = user?.lastSeen;

                return Text(
                  isOnline
                      ? 'En línea'
                      : 'Últ. vez ${_formatLastSeen(lastSeen)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                );
              },
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: chatService.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == chatService.getCurrentUserId();

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      otherUser: widget.otherUser,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                Consumer<ChatService>(
                  builder: (context, chatService, child) {
                    final isSending = false;

                    return IconButton(
                      icon: Icon(Icons.send),
                      onPressed: isSending ? null : _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: isSending ? Colors.grey : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}