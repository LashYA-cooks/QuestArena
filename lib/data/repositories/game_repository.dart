// WHAT THIS FILE DOES:
// Manages the real-time state of a specific game session.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/game_utils.dart';
import '../models/game_room_model.dart';

class GameRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a private room
  Future<String> createPrivateRoom(Map<String, dynamic> player1Data, String code) async {
    final roomId = _db.collection('gameRooms').doc().id;
    await _db.collection('gameRooms').doc(roomId).set({
      'roomId': roomId,
      'roomCode': code,
      'status': 'fetching_questions',
      'player1': {...player1Data, 'isReady': false, 'score': 0, 'answers': []},
      'player2': null,
      'createdAt': FieldValue.serverTimestamp(),
      'questions': [], // Let Cloud Functions populate this
    });
    return roomId;
  }

  // Join a private room using a code
  Future<String?> joinPrivateRoom(Map<String, dynamic> player2Data, String code) async {
    // Look for rooms with this code that are not already active/finished
    final query = await _db
        .collection('gameRooms')
        .where('roomCode', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final status = doc.get('status');

    // Only allow joining if it's in a 'waiting' or 'fetching_questions' state
    if (status != 'waiting' && status != 'fetching_questions') return null;

    await doc.reference.update({
      'player2': {...player2Data, 'isReady': false, 'score': 0, 'answers': []},
      'status': 'active', // Room is now full
    });

    return doc.id;
  }

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

      // Check if both players have finished the current question
      final updatedSnapshot = await transaction.get(roomRef);
      final p1Answers = List<String>.from(updatedSnapshot.get('player1.answers') ?? []);
      final p2Answers = List<String>.from(updatedSnapshot.get('player2.answers') ?? []);
      final currentIdx = updatedSnapshot.get('currentQuestionIndex') ?? 0;
      final questions = List<dynamic>.from(updatedSnapshot.get('questions') ?? []);

      // If both players have answered the current question
      if (p1Answers.length > currentIdx && p2Answers.length > currentIdx) {
        if (currentIdx + 1 < questions.length) {
          // Move to next question
          transaction.update(roomRef, {'currentQuestionIndex': currentIdx + 1});
        } else {
          // Game Finished!
          final p1Score = updatedSnapshot.get('player1.score') ?? 0;
          final p2Score = updatedSnapshot.get('player2.score') ?? 0;
          
          String winnerId = 'draw';
          if (p1Score > p2Score) winnerId = updatedSnapshot.get('player1.uid');
          if (p2Score > p1Score) winnerId = updatedSnapshot.get('player2.uid');

          transaction.update(roomRef, {
            'status': 'finished',
            'winnerId': winnerId,
          });
        }
      }
    });
  }

  // Emergency Fallback: If Cloud Function fails, the client will push mock questions
  Future<void> triggerQuestionsFallback(String roomId) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'questions': GameUtils.getFallbackQuestions(),
      'status': 'waiting',
    });
  }
}
