import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/auth_result.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Agregar este método en la clase AuthService
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'El formato del email no es válido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este email';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'operation-not-allowed':
        return 'El registro con email/contraseña no está habilitado';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet';
      case 'too-many-requests':
        return 'Demasiados intentos. Por favor espera unos minutos';
      case 'invalid-credential':
        return 'Credenciales inválidas o usuario no existe';
      default:
      // Para errores no mapeados, mostrar un mensaje genérico en español
        print('Código de error no manejado: ${e.code} - ${e.message}');
        return 'Error de autenticación. Por favor intenta nuevamente';
    }
  }

  // Iniciar sesión
  Future<AuthResult> signIn(String email, String password) async { // ← Cambiar return type
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Crear/actualizar usuario en Firestore
      await _createUserInFirestore(result.user!);

      return AuthResult(success: true, user: result.user); // ← Nuevo return
    } on FirebaseAuthException catch (e) { // ← Capturar error específico
      final errorMessage = _getAuthErrorMessage(e);
      print('Error al iniciar sesión: $errorMessage');
      return AuthResult(success: false, errorMessage: errorMessage); // ← Nuevo return
    } catch (e) {
      print('Error inesperado: $e');
      if (e is FirebaseAuthException) {
        // Por si acaso algún error de Firebase no fue capturado
        final errorMessage = _getAuthErrorMessage(e);
        return AuthResult(success: false, errorMessage: errorMessage);
      }
      return AuthResult(success: false, errorMessage: 'Error inesperado. Por favor intenta nuevamente');
    }
  }

  // Registrar usuario
  Future<AuthResult> register(String email, String password) async { // ← Cambiar return type
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Crear usuario en Firestore
      await _createUserInFirestore(result.user!);

      return AuthResult(success: true, user: result.user); // ← Nuevo return
    } on FirebaseAuthException catch (e) { // ← Capturar error específico
      final errorMessage = _getAuthErrorMessage(e);
      print('Error al registrar: $errorMessage');
      return AuthResult(success: false, errorMessage: errorMessage); // ← Nuevo return
    } catch (e) {
      print('Error inesperado: $e');
      if (e is FirebaseAuthException) {
        // Por si acaso algún error de Firebase no fue capturado
        final errorMessage = _getAuthErrorMessage(e);
        return AuthResult(success: false, errorMessage: errorMessage);
      }
      return AuthResult(success: false, errorMessage: 'Error inesperado. Por favor intenta nuevamente');
    }
  }

  // Crear usuario en Firestore
  Future<void> _createUserInFirestore(User user) async {
    // GENERAR displayName desde el email - user.displayName siempre es null
    final displayName = _generateDisplayName(user.email!);

    // Obtener token FCM
    final notificationService = NotificationService();
    final fcmToken = await notificationService.getDeviceToken();

    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
      'isOnline': true,
      'fcmToken': fcmToken,
    }, SetOptions(merge: true));
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Agregar este método helper para generar displayName
  String _generateDisplayName(String email) {
    // Extraer la parte antes del @
    final namePart = email.split('@')[0];

    // Reemplazar puntos y guiones con espacios
    final cleanedName = namePart.replaceAll(RegExp(r'[._-]'), ' ');

    // Convertir a Title Case (primera letra de cada palabra en mayúscula)
    final words = cleanedName.split(' ');
    final titleCaseWords = words.map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).toList();

    return titleCaseWords.join(' ').trim();
  }

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}