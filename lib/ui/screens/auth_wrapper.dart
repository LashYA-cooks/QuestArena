// WHAT THIS FILE DOES:
// Listens to the authStateProvider and switches between Login and Home.
//
// KEY CONCEPTS IN THIS FILE:
// • ref.watch: The modern way to "observe" data and rebuild the UI.
// • AsyncValue: Riverpod's wrapper for data that might still be loading or has an error.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the authStateProvider
    final authState = ref.watch(authStateProvider);

    return authState.when(
      // 1. We have auth data (either a User or null)
      data: (user) {
        if (user != null) {
          // Temporarily show a simple scaffold until we build HomeScreen in Day 4
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Logged in as ${user.email}'),
                  ElevatedButton(
                    onPressed: () => ref.read(authRepositoryProvider).logout(),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
          );
        }
        return const LoginScreen();
      },
      // 2. We are still checking the auth state
      loading: () => const SplashScreen(),
      // 3. Something went wrong with the connection
      error: (e, stack) => Scaffold(
        body: Center(child: Text('Auth Error: $e')),
      ),
    );
  }
}
