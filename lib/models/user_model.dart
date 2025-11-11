import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final DateTime? createdAt;
  final bool isOnline;
  final DateTime? lastSeen;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.createdAt,
    this.isOnline = false,
    this.lastSeen,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      id: id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      isOnline: data['isOnline'] ?? false,
      lastSeen: data['lastSeen'] != null
          ? (data['lastSeen'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt ?? DateTime.now(),
      'isOnline': isOnline,
      'lastSeen': lastSeen,
    };
  }
}