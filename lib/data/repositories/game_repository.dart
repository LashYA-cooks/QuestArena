// WHAT THIS FILE DOES:
// Manages the real-time state of a specific game session.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_room_model.dart';

class GameRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Watch a specific game room
  Stream<GameRoomModel?> watchRoom(String roomId) {
    return _db.collection('gameRooms').doc(roomId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return GameRoomModel.fromJson(doc.data()!);
    });
  }

  // Set the player as "Ready"
  Future<void> setPlayerReady(String roomId, int playerNumber) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'player$playerNumber.isReady': true,
    });
  }

  // Submit an answer
  Future<void> submitAnswer({
    required String roomId,
    required String userId,
    required int playerNumber,
    required String answer,
    required int scoreIncrement,
  }) async {
    final roomRef = _db.collection('gameRooms').doc(roomId);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final playerKey = 'player$playerNumber';
      final currentScore = snapshot.get('$playerKey.score') ?? 0;
      final currentAnswers = List<String>.from(snapshot.get('$playerKey.answers') ?? []);
      
      currentAnswers.add(answer);
      
      transaction.update(roomRef, {
        '$playerKey.score': currentScore + scoreIncrement,
        '$playerKey.answers': currentAnswers,
      });
    });
  }
}
