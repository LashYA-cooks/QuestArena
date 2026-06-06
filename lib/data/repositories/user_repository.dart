// WHAT THIS FILE DOES:
// Manages player profile data logic with detailed error reporting.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../models/user_model.dart';
import '../models/match_history_model.dart';
import '../services/firestore_service.dart';

class UserRepository {
  final FirestoreService _service;

  UserRepository(this._service);

  Future<Result<void>> createUserProfile(UserModel user) async {
    try {
      // 1. Check if the username is taken
      final isAvailable = await _service.isUsernameAvailable(user.username);
      if (!isAvailable) {
        return const Failure(DatabaseError("Username already taken."));
      }

      // 2. Try to save the document
      await _service.setData(
        path: 'users/${user.uid}',
        data: user.toJson(),
      );
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  Future<Result<UserModel>> getUserProfile(String uid) async {
    try {
      final doc = await _service.getDocument('users/$uid');
      if (doc.exists) {
        return Success(UserModel.fromJson(doc.data() as Map<String, dynamic>));
      }
      return const Failure(DatabaseError("User profile not found."));
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson(doc.data()!);
    });
  }

  Future<void> deleteUserProfile(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
  }

  Future<void> updateUserStats({
    required String uid,
    required int xpGained,
    required int coinsGained,
    required bool isWin,
  }) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      int currentXp = data['xp'] ?? 0;
      int currentLevel = data['level'] ?? 1;
      int currentCoins = data['coins'] ?? 0;
      int wins = data['totalWins'] ?? 0;
      int losses = data['totalLosses'] ?? 0;

      // Update XP and Coins
      currentXp += xpGained;
      currentCoins += coinsGained;
      if (isWin) {
        wins++;
      } else if (xpGained > 0) { // If it was a draw or loss but they played
        losses++;
      }

      // Check for Level Up
      int xpToNext = 100 * currentLevel;
      while (currentXp >= xpToNext) {
        currentXp -= xpToNext;
        currentLevel++;
        xpToNext = 100 * currentLevel;
      }

      // Calculate Rank
      String rank = 'Bronze';
      if (currentXp + (currentLevel * 1000) >= 10000) {
        rank = 'Diamond';
      } else if (currentXp + (currentLevel * 1000) >= 4000) {
        rank = 'Platinum';
      } else if (currentXp + (currentLevel * 1000) >= 1500) {
        rank = 'Gold';
      } else if (currentXp + (currentLevel * 1000) >= 500) {
        rank = 'Silver';
      }

      // Achievements Logic
      final achievements = List<String>.from(data['achievements'] ?? []);
      if (isWin && !achievements.contains('first_win')) {
        achievements.add('first_win');
      }
      if (wins >= 10 && !achievements.contains('veteran')) {
        achievements.add('veteran');
      }

      transaction.update(userRef, {
        'xp': currentXp,
        'level': currentLevel,
        'xpToNextLevel': xpToNext,
        'coins': currentCoins,
        'totalWins': wins,
        'totalLosses': losses,
        'rank': rank,
        'achievements': achievements,
      });
    });
  }

  Future<void> saveMatchHistory(String uid, MatchHistoryModel history) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('matchHistory')
        .doc(history.matchId)
        .set(history.toJson());
  }

  Stream<List<MatchHistoryModel>> watchMatchHistory(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('matchHistory')
        .orderBy('playedAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MatchHistoryModel.fromJson(doc.data()))
          .toList();
    });
  }
}
