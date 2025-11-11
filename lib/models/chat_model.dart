import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants;
  final DateTime createdAt;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCounts;
  //final Map<String, int> lastReadMessage;

  Chat({
    required this.id,
    required this.participants,
    required this.createdAt,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCounts = const {},
    //this.lastReadMessage = const {},
  });

  factory Chat.fromFirestore(Map<String, dynamic> data, String id) {
    return Chat(
      id: id,
      participants: List<String>.from(data['participants'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'] != null
          ? (data['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCounts: _safeIntMapConvert(data['unreadCounts']),
      //lastReadMessage: _safeIntMapConvert(data['lastReadMessage']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'participants': participants,
      'createdAt': createdAt,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCounts': unreadCounts,
      //'lastReadMessage':
      // lastReadMessage,
    };
  }

  // Método helper para obtener unreadCount del usuario actual
  int getUnreadCountForUser(String userId) {
    return unreadCounts[userId] ?? 0;
  }

  // Método helper para Map<String, int>
  static Map<String, int> _safeIntMapConvert(dynamic mapData) {
    if (mapData == null) return {};
    try {
      final Map<dynamic, dynamic> dynamicMap = Map<dynamic, dynamic>.from(mapData);
      final Map<String, int> result = {};

      dynamicMap.forEach((key, value) {
        if (key is String && value is int) {
          result[key] = value;
        } else if (key is String && value is num) {
          result[key] = value.toInt();
        }
      });

      return result;
    } catch (e) {
      return {};
    }
  }
}