// WHAT THIS FILE DOES:
// Provides the global top 100 list to the UI.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/leaderboard_repository.dart';
import '../data/models/leaderboard_model.dart';
import '../core/errors/result.dart';

final leaderboardRepositoryProvider = Provider((ref) => LeaderboardRepository());

final leaderboardProvider = StreamProvider<List<LeaderboardModel>>((ref) {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.watchTopPlayers();
});
