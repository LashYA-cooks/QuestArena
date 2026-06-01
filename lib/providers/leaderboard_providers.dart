// WHAT THIS FILE DOES:
// Provides the global top 100 list to the UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/leaderboard_repository.dart';
import '../data/models/leaderboard_model.dart';
import '../core/errors/result.dart';

final leaderboardRepositoryProvider = Provider((ref) => LeaderboardRepository());

final leaderboardProvider = FutureProvider<List<LeaderboardModel>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  final result = await repo.getTopPlayers();
  
  return switch (result) {
    Success(data: final list) => list,
    Failure(error: final e) => throw e.message,
  };
});
