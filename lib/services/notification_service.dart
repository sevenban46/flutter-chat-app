import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Configurar notificaciones locales
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // Solicitar permisos
    NotificationSettings notificationSettings = await _firebaseMessaging
        .requestPermission(alert: true, badge: true, sound: true);

    // Configurar handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Mostrar notificación cuando la app está en foreground
    _showLocalNotification(message);
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    // Manejar cuando se toca la notificación (app en background/terminada)
    print('Notificación tocada: ${message.data}');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'chat_channel',
          'Mensajes de Chat',
          channelDescription: 'Notificaciones para nuevos mensajes',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'Nuevo mensaje',
      message.notification?.body ?? 'Tienes un nuevo mensaje',
      details,
    );
  }

  Future<String?> getDeviceToken() async {
    return await _firebaseMessaging.getToken();
  }

  // En NotificationService, agregar:
  void setupTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      // Actualizar token en Firestore cuando cambie
      await _updateTokenInFirestore(newToken);
    });
  }

  Future<void> _updateTokenInFirestore(String newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': newToken},
      );
    }
  }
}
