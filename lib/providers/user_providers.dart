// WHAT THIS FILE DOES:
// Provides the current player's profile data globally.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';
import '../data/services/firestore_service.dart';
import '../data/repositories/user_repository.dart';
import 'package:dio/dio.dart';
import '../data/models/user_model.dart';
import '../data/models/match_history_model.dart';
import '../core/errors/result.dart';

final dioProvider = Provider((ref) => Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 5),
)));

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final userRepositoryProvider = Provider((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return UserRepository(service);
});

final currentUserProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);

  final repo = ref.watch(userRepositoryProvider);
  return repo.watchUserProfile(authState.uid).handleError((error) {
    print('User Stream Error: $error');
  });
});

final matchHistoryProvider = StreamProvider.autoDispose<List<MatchHistoryModel>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value([]);

  final repo = ref.watch(userRepositoryProvider);
  return repo.watchMatchHistory(authState.uid);
});
