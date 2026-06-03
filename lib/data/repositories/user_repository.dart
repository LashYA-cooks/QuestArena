// WHAT THIS FILE DOES:
// Manages player profile data logic with detailed error reporting.

import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class UserRepository {
  final FirestoreService _service;

  UserRepository(this._service);

  Future<Result<void>> createUserProfile(UserModel user) async {
    try {
      // Check if username is already taken
      final isAvailable =
      await _service.isUsernameAvailable(user.username);

      if (!isAvailable) {
        return const Failure(
          DatabaseError("Username already taken."),
        );
      }

      await _service.setData(
        path: 'users/${user.uid}',
        data: user.toJson(),
      );

      return const Success(null);
    } catch (e) {
      print('Firestore Error: $e');
      return Failure(
        DatabaseError(e.toString()),
      );
    }
  }

  Future<Result<UserModel>> getUserProfile(
      String uid,
      ) async {
    try {
      final doc =
      await _service.getDocument('users/$uid');

      if (doc.exists) {
        return Success(
          UserModel.fromJson(
            doc.data() as Map<String, dynamic>,
          ),
        );
      }

      return const Failure(
        DatabaseError(
          "User profile not found.",
        ),
      );
    } catch (e) {
      print('Firestore Error: $e');

      return Failure(
        DatabaseError(e.toString()),
      );
    }
  }

  Future<Result<void>> updateUserProfile(
      UserModel user,
      ) async {
    try {
      await _service.setData(
        path: 'users/${user.uid}',
        data: user.toJson(),
      );

      return const Success(null);
    } catch (e) {
      print('Firestore Error: $e');

      return Failure(
        DatabaseError(e.toString()),
      );
    }
  }
}