// WHAT THIS FILE DOES:
// Fetches the global rankings from Firestore.
//
// KEY CONCEPTS IN THIS FILE:
// • Querying: Using .orderBy() and .limit() to get specific data.
// • Mapping: Converting a list of Firestore documents into a list of Models.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_model.dart';
import '../../core/errors/result.dart';
import '../../core/errors/app_error.dart';

class LeaderboardRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Result<List<LeaderboardModel>>> getTopPlayers() async {
    try {
      final snapshot = await _db
          .collection('users')
          .orderBy('xp', descending: true)
          .limit(100)
          .get();

      final players = snapshot.docs
          .map((doc) => LeaderboardModel.fromJson(doc.data()))
          .toList();

      return Success(players);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }
}
