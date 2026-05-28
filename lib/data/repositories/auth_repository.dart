// WHAT THIS FILE DOES:
// Acts as a bridge between the raw Firebase Service and the UI.
// It catches Firebase errors and returns our custom Result type.
//
// KEY CONCEPTS IN THIS FILE:
// • Error Mapping: Converting technical errors (like 'weak-password') into human-readable messages.
// • Result Wrapper: Ensuring the UI always knows if a call succeeded or failed.

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
      // Map Firebase errors to our AppError subtypes
      return Failure(AuthError(_mapFirebaseError(e.code)));
    } catch (e) {
      return const Failure(UnknownError());
    }
  }

  Future<Result<User?>> register(String email, String password) async {
    try {
      final credential = await _service.signUp(email, password);
      return Success(credential.user);
    } on FirebaseAuthException catch (e) {
      return Failure(AuthError(_mapFirebaseError(e.code)));
    } catch (e) {
      return const Failure(UnknownError());
    }
  }

  Future<void> logout() => _service.signOut();

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'An account already exists with this email.';
      case 'weak-password': return 'Password is too weak.';
      default: return 'Authentication failed. Please try again.';
    }
  }
}
