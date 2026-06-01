// WHAT THIS FILE DOES:
// The core quiz screen. Handles question display, timer, and score updates.
//
// KEY CONCEPTS IN THIS FILE:
// • AnimationController: Precise control over the countdown timer.
// • State Feedback: Changing button colors based on correct/wrong answers.
// • Real-time Sync: Watching the opponent's score while playing.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/game_providers.dart';
import '../../providers/user_providers.dart';
import '../../data/models/game_room_model.dart';
import 'result_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String roomId;
  const GameScreen({super.key, required this.roomId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _timerController;
  String? _selectedAnswer;
  bool _hasAnswered = false;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..reverse(from: 1.0);

    // Auto-submit when timer hits zero
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && !_hasAnswered) {
        _handleAnswerSelection("TIMEOUT");
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _handleAnswerSelection(String answer) async {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
    });
    _timerController.stop();

    final room = ref.read(gameRoomProvider(widget.roomId)).value;
    final user = ref.read(currentUserProvider).value;
    if (room == null || user == null) return;

    final isP1 = user.uid == room.player1['uid'];
    final question = room.questions[room.currentQuestionIndex];
    final isCorrect = answer == question['correct_answer'];

    // Calculate score: 10 base + speed bonus
    int score = 0;
    if (isCorrect) {
      score = 10 + (_timerController.value * 5).toInt();
    }

    await ref.read(gameRepositoryProvider).submitAnswer(
      roomId: widget.roomId,
      userId: user.uid,
      playerNumber: isP1 ? 1 : 2,
      answer: answer,
      scoreIncrement: score,
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(gameRoomProvider(widget.roomId));

    // LISTEN for game finished status
    ref.listen(gameRoomProvider(widget.roomId), (prev, next) {
      if (next.value?.status == 'finished') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ResultScreen(room: next.value!)),
        );
      }
    });

    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (room) {
          if (room == null) return const Center(child: Text('Room Error'));

          final question = room.questions[room.currentQuestionIndex];
          final options = List<String>.from(question['incorrect_answers'])..add(question['correct_answer'])..shuffle();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header: Scores & Progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PlayerScore(
                        name: room.player1['username'], 
                        score: room.player1['score'] ?? 0, 
                        isLeft: true
                      ),
                      Text('${room.currentQuestionIndex + 1}/10', style: AppTextStyles.label),
                      _PlayerScore(
                        name: room.player2['username'], 
                        score: room.player2['score'] ?? 0, 
                        isLeft: false
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Timer Bar
                  AnimatedBuilder(
                    animation: _timerController,
                    builder: (context, child) => LinearProgressIndicator(
                      value: _timerController.value,
                      backgroundColor: AppColors.surface,
                      color: _timerController.value < 0.3 ? AppColors.red : AppColors.gold,
                      minHeight: 10,
                    ),
                  ),

                  const Spacer(),

                  // Question Text
                  Text(
                    question['question'],
                    style: AppTextStyles.headline,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn().scale(),

                  const Spacer(),

                  // Answer Buttons
                  ...options.map((option) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AnswerButton(
                      text: option,
                      isSelected: _selectedAnswer == option,
                      isCorrect: _hasAnswered && option == question['correct_answer'],
                      isWrong: _hasAnswered && _selectedAnswer == option && option != question['correct_answer'],
                      onTap: () => _handleAnswerSelection(option),
                    ),
                  )),
                  
                  if (_hasAnswered)
                    Text(
                      'Waiting for opponent...',
                      style: AppTextStyles.label.copyWith(color: AppColors.gold),
                    ).animate(onPlay: (c) => c.repeat()).fadeIn().fadeOut(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlayerScore extends StatelessWidget {
  final String name;
  final int score;
  final bool isLeft;
  const _PlayerScore({required this.name, required this.score, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(name, style: AppTextStyles.label),
        Text('$score', style: AppTextStyles.headline.copyWith(color: AppColors.gold)),
      ],
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.surface;
    Color bgColor = AppColors.cardBg;

    if (isCorrect) {
      borderColor = AppColors.teal;
      bgColor = AppColors.teal.withOpacity(0.1);
    } else if (isWrong) {
      borderColor = AppColors.red;
      bgColor = AppColors.red.withOpacity(0.1);
    } else if (isSelected) {
      borderColor = AppColors.purple;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(
          text,
          style: AppTextStyles.bodyMd.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
