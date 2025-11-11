// Agregar fuera de la clase AuthService
import 'package:firebase_auth/firebase_auth.dart';

class AuthResult {
  final bool success;
  final User? user;
  final String? errorMessage;

  AuthResult({
    required this.success,
    this.user,
    this.errorMessage,
  });
}