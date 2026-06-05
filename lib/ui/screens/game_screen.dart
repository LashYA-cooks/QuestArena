// WHAT THIS FILE DOES:
// The core quiz screen. Handles question display, timer, and score updates.
//
// KEY CONCEPTS IN THIS FILE:
// • AnimationController: Precise control over the countdown timer.
// • State Feedback: Changing button colors based on correct/wrong answers.
// • Real-time Sync: Watching the opponent's score while playing.

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
  List<String> _shuffledOptions = [];
  int _lastQuestionIndex = -1;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..reverse(from: 1.0);

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

  int _processedIndex = -1;

  // Prepares the options list once per question
  void _prepareOptions(GameRoomModel room) {
    if (_lastQuestionIndex != room.currentQuestionIndex) {
      final question = room.questions[room.currentQuestionIndex];
      _shuffledOptions = List<String>.from(question['incorrect_answers'])
        ..add(question['correct_answer'])
        ..shuffle();
      _lastQuestionIndex = room.currentQuestionIndex;
    }

    if (_processedIndex != room.currentQuestionIndex) {
      _processedIndex = room.currentQuestionIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasAnswered = false;
            _selectedAnswer = null;
          });
          _timerController.reverse(from: 1.0);
        }
      });
    }
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

    ref.listen(gameRoomProvider(widget.roomId), (prev, next) {
      if (next.value?.status == 'finished') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ResultScreen(room: next.value!)),
        );
      }
    });

    return Scaffold(
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (room) {
          if (room == null) return const Center(child: Text('Room Error'));
          
          if (room.questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.gold),
                  const SizedBox(height: 24),
                  Text('Waiting for questions...', style: AppTextStyles.bodyMd),
                  const SizedBox(height: 40),
                  TextButton(
                    onPressed: () => ref.read(gameRepositoryProvider).triggerQuestionsFallback(widget.roomId),
                    child: Text('TAP HERE IF STUCK (FALLBACK)', style: AppTextStyles.label.copyWith(color: AppColors.gold)),
                  ),
                ],
              ),
            );
          }

          // Ensure options are ready and timer is reset for the current question
          _prepareOptions(room);
          final question = room.questions[room.currentQuestionIndex];

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _PlayerScore(
                        name: room.player1['username'], 
                        score: room.player1['score'] ?? 0, 
                        isLeft: true,
                        timer: _timerController,
                        hasAnswered: (room.player1['answers'] as List).length > room.currentQuestionIndex,
                      ),
                      Text('${room.currentQuestionIndex + 1}/${room.questions.length}', style: AppTextStyles.label),
                      _PlayerScore(
                        name: room.player2?['username'] ?? 'Opponent', 
                        score: room.player2?['score'] ?? 0,
                        isLeft: false,
                        timer: _timerController,
                        hasAnswered: (room.player2?['answers'] as List? ?? []).length > room.currentQuestionIndex,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
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
                  Text(
                    question['question'],
                    style: AppTextStyles.headline,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn().scale(),
                  const Spacer(),
                  ..._shuffledOptions.map((option) => Padding(
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
  final AnimationController timer;
  final bool hasAnswered;

  const _PlayerScore({
    required this.name, 
    required this.score, 
    required this.isLeft,
    required this.timer,
    required this.hasAnswered,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(name, style: AppTextStyles.label.copyWith(
          color: hasAnswered ? AppColors.teal : AppColors.textSecondary,
        )),
        Text('$score', style: AppTextStyles.headline.copyWith(
          color: hasAnswered ? AppColors.teal : AppColors.gold,
          fontSize: 20,
        )),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: AnimatedBuilder(
            animation: timer,
            builder: (context, child) => LinearProgressIndicator(
              value: hasAnswered ? 0 : timer.value,
              backgroundColor: AppColors.surface,
              color: hasAnswered ? AppColors.teal : (timer.value < 0.3 ? AppColors.red : AppColors.purple),
              minHeight: 3,
            ),
          ),
        ),
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
