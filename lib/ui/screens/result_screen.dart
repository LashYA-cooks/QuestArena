// WHAT THIS FILE DOES:
// Displays the final scores, the winner, and rewards (XP/Coins).
//
// KEY CONCEPTS IN THIS FILE:
// • Lottie: Using high-quality vector animations for "Victory" or "Defeat".
// • Conditional Layouts: Different colors and text based on whether the user won or lost.
// • Navigation: Returning the user back to the main Hub (HomeScreen).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/user_providers.dart';
import '../../data/models/game_room_model.dart';

class ResultScreen extends ConsumerWidget {
  final GameRoomModel room;
  const ResultScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) return const Scaffold();

    final isWinner = room.winnerId == currentUser.uid;
    final isDraw = room.winnerId == 'draw';
    
    // Determine the player's final score
    final myScore = currentUser.uid == room.player1['uid'] 
        ? room.player1['score'] 
        : (room.player2?['score'] ?? 0);
        
    final opponentScore = currentUser.uid == room.player1['uid'] 
        ? (room.player2?['score'] ?? 0)
        : room.player1['score'];

    return Scaffold(
      body: Stack(
        children: [
          // Background Glow
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  isWinner ? AppColors.teal.withOpacity(0.2) : AppColors.red.withOpacity(0.2),
                  AppColors.primaryBg,
                ],
                radius: 1.0,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animation Placeholder/Lottie
                  SizedBox(
                    height: 140,
                    child: isWinner 
                      ? const Icon(Icons.emoji_events_rounded, size: 100, color: AppColors.gold)
                      : const Icon(Icons.sentiment_very_dissatisfied_rounded, size: 100, color: AppColors.red),
                  ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 16),

                  Text(
                    isDraw ? "IT'S A DRAW!" : (isWinner ? 'VICTORY!' : 'DEFEAT'),
                    style: AppTextStyles.display.copyWith(
                      fontSize: 36,
                      color: isWinner ? AppColors.teal : AppColors.red,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().slideY(begin: 0.5, end: 0),

                  const SizedBox(height: 24),

                  // Score Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.surface),
                    ),
                    child: Column(
                      children: [
                        _ResultRow(label: 'YOUR SCORE', value: '$myScore', color: AppColors.gold),
                        const Divider(color: AppColors.surface, height: 24),
                        _ResultRow(label: 'OPPONENT', value: '$opponentScore', color: AppColors.textSecondary),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 24),

                  // Rewards Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RewardItem(
                        label: 'XP GAINED', 
                        value: isWinner ? '+50' : '+15', 
                        icon: Icons.trending_up_rounded, 
                        color: AppColors.purple
                      ),
                      _RewardItem(
                        label: 'COINS', 
                        value: isWinner ? '+20' : '+5', 
                        icon: Icons.monetization_on_rounded, 
                        color: AppColors.gold
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 40),

                  // Action Buttons
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('BACK TO HOME', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ResultRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.label),
        Text(value, style: AppTextStyles.display.copyWith(fontSize: 24, color: color)),
      ],
    );
  }
}

class _RewardItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _RewardItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 20)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 10)),
      ],
    );
  }
}
