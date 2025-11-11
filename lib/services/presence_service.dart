import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/user_model.dart';

class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Actualizar estado de presencia
  Future<void> updateUserPresence(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);

    if (isOnline) {
      await userRef.update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } else {
      await userRef.update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  // Cambiar este método para que retorne AppUser completo o solo presencia
  Stream<AppUser?> getUserPresenceStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return AppUser.fromFirestore(snapshot.data()!, snapshot.id);
      }
      return null;
    });
  }

  // Obtener stream de presencia de un usuario
  Stream<Map<String, dynamic>> getUserPresence(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      return {
        'isOnline': data?['isOnline'] ?? false,
        'lastSeen': data?['lastSeen'] != null
            ? (data?['lastSeen'] as Timestamp).toDate()
            : null,
      };
    });
  }

  // Configurar listeners de conectividad
  void setupPresenceListener() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Actualizar a online cuando la app se inicia/activa
    updateUserPresence(true);

    // Escuchar cambios de conectividad
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        updateUserPresence(true);
      } else {
        updateUserPresence(false);
      }
    });
  }

  // Limpiar presencia cuando la app se cierra
  Future<void> cleanupPresence() async {
    await updateUserPresence(false);
  }
}