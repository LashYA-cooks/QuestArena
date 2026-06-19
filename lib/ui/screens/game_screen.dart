// WHAT THIS FILE DOES:
// Optimized core quiz screen. Isolated rebuilds for maximum performance.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/game_providers.dart';
import '../../providers/user_providers.dart';
import '../../data/models/game_room_model.dart';
import '../../core/utils/game_utils.dart';
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
  int _processedIndex = -1;

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
    // Listen for completion to navigate away
    ref.listen(gameRoomProvider(widget.roomId), (prev, next) {
      if (next.value?.status == 'finished') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ResultScreen(room: next.value!)),
        );
      }
    });

    final roomAsync = ref.watch(gameRoomProvider(widget.roomId));

    return Scaffold(
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
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

          _prepareOptions(room);
          final question = room.questions[room.currentQuestionIndex];
          final qText = GameUtils.decodeHtmlEntities(question['question']);

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Header with scores
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PlayerScore(
                          name: room.player1['username'], 
                          score: room.player1['score'] ?? 0, 
                          isLeft: true,
                          hasAnswered: (room.player1['answers'] as List).length > room.currentQuestionIndex,
                        ),
                        Text('${room.currentQuestionIndex + 1}/${room.questions.length}', style: AppTextStyles.label),
                        _PlayerScore(
                          name: room.player2?['username'] ?? 'Opponent', 
                          score: room.player2?['score'] ?? 0,
                          isLeft: false,
                          hasAnswered: (room.player2?['answers'] as List? ?? []).length > room.currentQuestionIndex,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // Timer bar
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _timerController,
                        builder: (context, child) => LinearProgressIndicator(
                          value: _timerController.value,
                          backgroundColor: AppColors.surface,
                          color: _timerController.value < 0.3 ? AppColors.red : AppColors.gold,
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Question Text
                    Text(
                      qText,
                      style: AppTextStyles.headline,
                      textAlign: TextAlign.center,
                    ).animate(key: ValueKey(room.currentQuestionIndex)).fadeIn().scale(),
                    
                    const SizedBox(height: 40),

                    // Shuffled Options
                    ..._shuffledOptions.map((option) {
                      final decodedOption = GameUtils.decodeHtmlEntities(option);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _AnswerButton(
                          text: decodedOption,
                          isSelected: _selectedAnswer == option,
                          isCorrect: _hasAnswered && option == question['correct_answer'],
                          isWrong: _hasAnswered && _selectedAnswer == option && option != question['correct_answer'],
                          onTap: () => _handleAnswerSelection(option),
                        ),
                      );
                    }),

                    if (_hasAnswered)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(
                          'Waiting for opponent...',
                          style: AppTextStyles.label.copyWith(color: AppColors.gold),
                        ).animate(onPlay: (c) => c.repeat()).fadeIn().fadeOut(),
                      ),
                  ],
                ),
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
  final bool hasAnswered;

  const _PlayerScore({
    required this.name, 
    required this.score, 
    required this.isLeft,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isCorrect 
              ? AppColors.teal.withValues(alpha: 0.1) 
              : isWrong 
                  ? AppColors.red.withValues(alpha: 0.1)
                  : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCorrect 
                ? AppColors.teal 
                : isWrong 
                    ? AppColors.red 
                    : isSelected 
                        ? AppColors.purple 
                        : AppColors.surface, 
            width: 2
          ),
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
