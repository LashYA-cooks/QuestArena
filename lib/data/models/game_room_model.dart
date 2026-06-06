// WHAT THIS FILE DOES:
// The "Source of Truth" for a live 1v1 match.

class GameRoomModel {
  final String roomId;
  final String roomCode;
  final String status;
  final Map<String, dynamic> player1;
  final Map<String, dynamic>? player2;
  final List<dynamic> questions;
  final int currentQuestionIndex;
  final DateTime? questionDeadline;
  final String? winnerId;
  final List<String> claimedRewards;

  GameRoomModel({
    required this.roomId,
    this.roomCode = '',
    required this.status,
    required this.player1,
    this.player2,
    required this.questions,
    this.currentQuestionIndex = 0,
    this.questionDeadline,
    this.winnerId,
    this.claimedRewards = const [],
  });

  factory GameRoomModel.fromJson(Map<String, dynamic> json) {
    return GameRoomModel(
      roomId: json['roomId'] ?? '',
      roomCode: json['roomCode'] ?? '',
      status: json['status'] ?? 'waiting',
      player1: Map<String, dynamic>.from(json['player1'] ?? {}),
      player2: json['player2'] != null ? Map<String, dynamic>.from(json['player2']) : null,
      questions: List<dynamic>.from(json['questions'] ?? []),
      currentQuestionIndex: json['currentQuestionIndex'] ?? 0,
      questionDeadline: json['questionDeadline'] != null 
          ? DateTime.tryParse(json['questionDeadline'].toString()) 
          : null,
      winnerId: json['winnerId'],
      claimedRewards: List<String>.from(json['claimedRewards'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'roomCode': roomCode,
    'status': status,
    'player1': player1,
    'player2': player2,
    'questions': questions,
    'currentQuestionIndex': currentQuestionIndex,
    'questionDeadline': questionDeadline?.toIso8601String(),
    'winnerId': winnerId,
    'claimedRewards': claimedRewards,
  };
}
