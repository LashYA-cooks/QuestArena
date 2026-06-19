// WHAT THIS FILE DOES:
// Reactive state for the matchmaking process.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_providers.dart';
import '../data/repositories/matchmaking_repository.dart';
import '../data/models/matchmaking_model.dart';

final matchmakingRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return MatchmakingRepository(dio);
});

// This provider watches the matchmaking document in real-time
final matchmakingTicketProvider = StreamProvider.autoDispose((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value(null);

  final repo = ref.watch(matchmakingRepositoryProvider);
  return repo.watchTicket(user.uid);
});
