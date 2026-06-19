// WHAT THIS FILE DOES:
// Represents a single completed match record for the player's history.

import 'package:flutter/foundation.dart';

class MatchHistoryModel {
  final String matchId;
  final String opponentName;
  final bool isWin;
  final int myScore;
  final int opponentScore;
  final int xpGained;
  final DateTime playedAt;

  MatchHistoryModel({
    required this.matchId,
    required this.opponentName,
    required this.isWin,
    required this.myScore,
    required this.opponentScore,
    required this.xpGained,
    required this.playedAt,
  });

  factory MatchHistoryModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    try {
      if (json['playedAt'] != null) {
        final val = json['playedAt'];
        if (val is DateTime) {
          parsedDate = val;
        } else if (val is String) {
          parsedDate = DateTime.parse(val);
        } else {
          parsedDate = (val as dynamic).toDate();
        }
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }

    return MatchHistoryModel(
      matchId: json['matchId'] ?? '',
      opponentName: json['opponentName'] ?? 'Unknown',
      isWin: json['isWin'] ?? false,
      myScore: json['myScore'] ?? 0,
      opponentScore: json['opponentScore'] ?? 0,
      xpGained: json['xpGained'] ?? 0,
      playedAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'matchId': matchId,
    'opponentName': opponentName,
    'isWin': isWin,
    'myScore': myScore,
    'opponentScore': opponentScore,
    'xpGained': xpGained,
    'playedAt': playedAt,
  };
}
