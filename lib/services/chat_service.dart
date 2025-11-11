import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener todos los chats del usuario actual
  Stream<List<Chat>> getUserChats() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Chat.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtener mensajes de un chat específico
  Stream<List<Message>> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Message.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Enviar mensaje a un chat específico
  Future<void> sendMessage(String chatId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final message = Message(
      id: '',
      text: text,
      senderEmail: user.email!,
      senderId: user.uid,
      timestamp: DateTime.now(),
      chatId: chatId,
    );

    // Agregar mensaje al subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toFirestore());

    // Actualizar último mensaje en el chat
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': DateTime.now(),
    });

    // INCREMENTAR unreadCount para el otro usuario
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final chatData = chatDoc.data();
    if (chatData != null) {
      final participants = List<String>.from(chatData['participants'] ?? []);
      final otherUserId = participants.firstWhere(
            (id) => id != user.uid,
        orElse: () => '',
      );

      if (otherUserId.isNotEmpty) {
        await incrementUnreadCount(chatId, otherUserId);

        await _sendPushNotification(chatId, text, user.uid);
      }
    }
  }

  // Agregar este método en ChatService
  Future<void> _sendPushNotification(String chatId, String messageText, String senderId) async {
    try {
      // Obtener el otro usuario del chat
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data();
      if (chatData == null) return;

      final participants = List<String>.from(chatData['participants'] ?? []);
      final otherUserId = participants.firstWhere(
            (id) => id != senderId,
        orElse: () => '',
      );

      if (otherUserId.isEmpty) return;

      // Obtener información del usuario remitente
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final senderData = senderDoc.data();
      final senderName = senderData?['displayName'] ?? senderData?['email'] ?? 'Alguien';

      // Obtener el token FCM del usuario destinatario
      final userDoc = await _firestore.collection('users').doc(otherUserId).get();
      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'];

      if (fcmToken == null || fcmToken.isEmpty) return;

      // Enviar notificación mediante Cloud Functions o HTTP
      await _sendFCMNotification(fcmToken, senderName, messageText, chatId);
    } catch (e) {
      print('Error enviando notificación: $e');
    }
  }

// Método para enviar via HTTP (requiere Cloud Functions para producción)
  Future<void> _sendFCMNotification(String token, String senderName, String message, String chatId) async {
    // Esto es un ejemplo básico - en producción usar Cloud Functions
    print('📲 Enviando notificación a $token');
    print('💬 De: $senderName - Mensaje: $message');
  }

  // Crear o obtener chat existente entre dos usuarios
  Future<String?> getOrCreateChat(String otherUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return null;

    // Buscar chat existente
    final existingChat = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in existingChat.docs) {
      final chat = Chat.fromFirestore(doc.data(), doc.id);
      if (chat.participants.contains(otherUserId) &&
          chat.participants.contains(currentUserId)) {
        return doc.id;
      }
    }

    // Crear nuevo chat
    final newChat = Chat(
      id: '',
      participants: [currentUserId, otherUserId],
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore.collection('chats').add(newChat.toFirestore());
    return docRef.id;
  }

  // Obtener todos los usuarios (excepto el actual)
  Stream<List<AppUser>> getOtherUsers() {
    final currentUserId = _auth.currentUser?.uid;

    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) {
        return AppUser.fromFirestore(doc.data(), doc.id);
      })
          .toList();
    });
  }

  // Obtener ID del usuario actual
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Obtener información de un usuario específico
  Future<AppUser?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return AppUser.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  // Y actualizar los métodos existentes:
  Future<void> incrementUnreadCount(String chatId, String userId) async {
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final currentCounts = Map<String, int>.from(chatDoc.data()?['unreadCounts'] ?? {});
    final currentCount = currentCounts[userId] ?? 0;

    currentCounts[userId] = currentCount + 1;

    await _firestore.collection('chats').doc(chatId).update({
      'unreadCounts': currentCounts,
    });
  }

  Future<void> resetUnreadCount(String chatId, String userId) async {
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final currentCounts = Map<String, int>.from(chatDoc.data()?['unreadCounts'] ?? {});

    currentCounts[userId] = 0;

    await _firestore.collection('chats').doc(chatId).update({
      'unreadCounts': currentCounts,
    });
  }
}