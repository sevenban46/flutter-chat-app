import 'package:chat_app/services/notification_service.dart';
import 'package:chat_app/services/presence_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/chats_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Inicializar notificaciones
  final notificationService = NotificationService();
  await notificationService.initialize();
  notificationService.setupTokenRefresh();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<ChatService>(create: (_) => ChatService()),
        Provider<PresenceService>(create: (_) => PresenceService()),
      ],
      child: MaterialApp(
        title: 'Chat Privado',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: AuthWrapper(),
        routes: {
          '/login': (context) => LoginPage(),
          '/register': (context) => RegisterPage(),
          '/chats': (context) => ChatsListPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget  {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePresence();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupPresence();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final presenceService = Provider.of<PresenceService>(context, listen: false);

    if (state == AppLifecycleState.resumed) {
      presenceService.updateUserPresence(true);
    } else if (state == AppLifecycleState.paused) {
      presenceService.updateUserPresence(false);
    }
  }

  void _initializePresence() async {
    final presenceService = Provider.of<PresenceService>(context, listen: false);
    presenceService.setupPresenceListener();
  }

  void _cleanupPresence() async {
    final presenceService = Provider.of<PresenceService>(context, listen: false);
    await presenceService.cleanupPresence();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return ChatsListPage();
        }

        return LoginPage();
      },
    );
  }
}
  

