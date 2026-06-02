// WHAT THIS FILE DOES:
// Acts as a bridge between the raw Firebase Service and the UI.

import 'package:firebase_auth/firebase_auth.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final FirebaseAuthService _service;

  AuthRepository(this._service);

  Future<Result<User?>> login(String email, String password) async {
    try {
      final credential = await _service.signIn(email, password);
      return Success(credential.user);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error Code: ${e.code}');
      return Failure(AuthError(_mapFirebaseError(e.code)));
    } catch (e) {
      print('Generic Auth Error: $e');
      return Failure(UnknownError(e.toString()));
    }
  }

  Future<Result<User?>> register(String email, String password) async {
    try {
      final credential = await _service.signUp(email, password);
      return Success(credential.user);
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error Code: ${e.code}');
      return Failure(AuthError(_mapFirebaseError(e.code)));
    } catch (e) {
      print('Generic Auth Error: $e');
      return Failure(UnknownError(e.toString()));
    }
  }

  Future<void> logout() => _service.signOut();

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'An account already exists with this email.';
      case 'weak-password': return 'Password is too weak.';
      case 'operation-not-allowed': return 'Email/Password login is not enabled in Firebase Console.';
      default: return 'Authentication failed: $code';
    }
  }
}
