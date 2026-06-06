// WHAT THIS FILE DOES:
// Manages the real-time state of a specific game session.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../../core/utils/game_utils.dart';
import '../models/game_room_model.dart';

class GameRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _dio = Dio();

  // Create a private room
  Future<String> createPrivateRoom(Map<String, dynamic> player1Data, String code) async {
    final roomId = _db.collection('gameRooms').doc().id;
    
    // Fetch questions from client side since Cloud Functions are not available on Spark plan
    List<Map<String, dynamic>> questions = [];
    try {
      final response = await _dio.get("https://opentdb.com/api.php?amount=10&type=multiple");
      questions = (response.data['results'] as List).map((q) => {
        'question': GameUtils.decodeHtmlEntities(q['question']),
        'correct_answer': GameUtils.decodeHtmlEntities(q['correct_answer']),
        'incorrect_answers': (q['incorrect_answers'] as List)
            .map((a) => GameUtils.decodeHtmlEntities(a))
            .toList(),
      }).toList();
    } catch (e) {
      print("Trivia API Error: $e");
      questions = GameUtils.getFallbackQuestions();
    }

    await _db.collection('gameRooms').doc(roomId).set({
      'roomId': roomId,
      'roomCode': code,
      'status': 'waiting',
      'player1': {...player1Data, 'isReady': false, 'score': 0, 'answers': []},
      'player2': null,
      'createdAt': FieldValue.serverTimestamp(),
      'questions': questions,
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

      final data = snapshot.data() as Map<String, dynamic>;
      final playerKey = 'player$playerNumber';
      
      final player1 = data['player1'] as Map<String, dynamic>;
      final player2 = data['player2'] as Map<String, dynamic>?;

      if (player2 == null) return; // Can't progress without both players

      final currentP1Answers = List<String>.from(player1['answers'] ?? []);
      final currentP2Answers = List<String>.from(player2['answers'] ?? []);
      
      final currentIdx = data['currentQuestionIndex'] ?? 0;
      final questions = List<dynamic>.from(data['questions'] ?? []);

      // 1. Update current player's answers and score
      final updatedAnswers = playerNumber == 1 ? currentP1Answers : currentP2Answers;
      
      // Safety: Don't add more answers than there are questions or if already answered this index
      if (updatedAnswers.length > currentIdx) return; 

      updatedAnswers.add(answer);
      final oldScore = (playerNumber == 1 ? player1['score'] : player2['score']) ?? 0;
      final newScore = oldScore + scoreIncrement;

      transaction.update(roomRef, {
        '$playerKey.answers': updatedAnswers,
        '$playerKey.score': newScore,
      });

      // 2. Check if we should move to the next question
      final p1Len = playerNumber == 1 ? updatedAnswers.length : currentP1Answers.length;
      final p2Len = playerNumber == 2 ? updatedAnswers.length : currentP2Answers.length;

      if (p1Len > currentIdx && p2Len > currentIdx) {
        if (currentIdx + 1 < questions.length) {
          transaction.update(roomRef, {'currentQuestionIndex': currentIdx + 1});
        } else {
          // Game Finished
          final p1Score = playerNumber == 1 ? newScore : (player1['score'] ?? 0);
          final p2Score = playerNumber == 2 ? newScore : (player2['score'] ?? 0);
          
          String winnerId = 'draw';
          if (p1Score > p2Score) winnerId = player1['uid'];
          if (p2Score > p1Score) winnerId = player2['uid'];

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

  // Claim match rewards
  Future<void> claimRewards(String roomId, String userId, bool isWin) async {
    final roomRef = _db.collection('gameRooms').doc(roomId);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final claimed = List<String>.from(snapshot.get('claimedRewards') ?? []);
      if (claimed.contains(userId)) return; // Already claimed

      claimed.add(userId);
      transaction.update(roomRef, {'claimedRewards': claimed});
    });
  }
}
