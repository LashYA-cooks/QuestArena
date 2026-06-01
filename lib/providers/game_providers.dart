// WHAT THIS FILE DOES:
// Provides real-time updates for a specific game room.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/game_repository.dart';
import '../data/models/game_room_model.dart';

final gameRepositoryProvider = Provider((ref) => GameRepository());

// We use .family because we need to pass a roomId as a parameter
final gameRoomProvider = StreamProvider.family<GameRoomModel?, String>((ref, roomId) {
  final repo = ref.watch(gameRepositoryProvider);
  return repo.watchRoom(roomId);
});
