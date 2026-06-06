// WHAT THIS FILE DOES:
// Manages the player's presence in the matchmaking queue.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../../core/utils/game_utils.dart';
import '../models/matchmaking_model.dart';
import '../services/firestore_service.dart';

class MatchmakingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _dio = Dio();

  // Start searching for a match
  Future<void> startSearching(MatchmakingModel ticket) async {
    // 0. Check if a ticket already exists to prevent duplicate entries
    final existingDoc = await _db.collection('matchmaking').doc(ticket.uid).get();
    if (existingDoc.exists && existingDoc.get('status') == 'searching') {
      return; // Already searching
    }

    // 1. Save our ticket
    await _db.collection('matchmaking').doc(ticket.uid).set(ticket.toJson());

    // 2. Look for another player who is also searching
    final potentialMatches = await _db.collection('matchmaking')
        .where('status', isEqualTo: 'searching')
        .get();

    // Filter out our own ticket in Dart to avoid complex Firestore index requirements
    final matchDoc = potentialMatches.docs
        .where((doc) => doc.id != ticket.uid)
        .firstOrNull;

    if (matchDoc != null) {
      final opponentUid = matchDoc.id;

      // 3. Create a game room
      final roomId = _db.collection('gameRooms').doc().id;
      
      final player1Data = ticket.toJson();
      final player2Data = matchDoc.data();

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
        'roomCode': '', // Not needed for public matchmaking
        'status': 'waiting',
        'player1': {...player1Data, 'isReady': false, 'score': 0, 'answers': []},
        'player2': {...player2Data, 'isReady': false, 'score': 0, 'answers': []},
        'createdAt': FieldValue.serverTimestamp(),
        'questions': questions,
      });

      // 4. Update both tickets to 'matched'
      final batch = _db.batch();
      batch.update(_db.collection('matchmaking').doc(ticket.uid), {
        'status': 'matched',
        'matchedWith': opponentUid,
        'gameRoomId': roomId,
      });
      batch.update(_db.collection('matchmaking').doc(opponentUid), {
        'status': 'matched',
        'matchedWith': ticket.uid,
        'gameRoomId': roomId,
      });
      await batch.commit();
    }
  }

  // Cancel searching
  Future<void> cancelSearching(String uid) async {
    await _db.collection('matchmaking').doc(uid).delete();
  }

  // Listen to the matchmaking ticket for updates (e.g., when status becomes 'matched')
  Stream<MatchmakingModel?> watchTicket(String uid) {
    return _db.collection('matchmaking').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return MatchmakingModel.fromJson(doc.data()!);
    });
  }
}
