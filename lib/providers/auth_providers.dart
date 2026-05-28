// WHAT THIS FILE DOES:
// Exposes the Auth logic to the UI using Riverpod.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../data/services/auth_service.dart';
import '../data/repositories/auth_repository.dart';

// 1. Provide the Service
final authServiceProvider = Provider((ref) => FirebaseAuthService());

// 2. Provide the Repository
final authRepositoryProvider = Provider((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthRepository(service);
});

// 3. Provide the Auth State (Logged In / Logged Out)
final authStateProvider = StreamProvider<User?>((ref) async* {
  // Add a 2-second delay so the Splash Screen animations have time to play
  await Future.delayed(const Duration(seconds: 2));

  try {
    Firebase.app(); // Check if Firebase is initialized
    yield* ref.watch(authServiceProvider).authStateChanges;
  } catch (e) {
    // If Firebase isn't setup, we emit null once to show the Login screen in demo mode
    yield null;
  }
});
