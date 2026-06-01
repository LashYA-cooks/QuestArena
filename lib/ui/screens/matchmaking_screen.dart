// WHAT THIS FILE DOES:
// Animated UI that players see while waiting for an opponent.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/matchmaking_providers.dart';
import '../../providers/user_providers.dart';
import '../../data/models/matchmaking_model.dart';

import 'lobby_screen.dart';

class MatchmakingScreen extends ConsumerWidget {
  const MatchmakingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(matchmakingTicketProvider);
    final user = ref.watch(currentUserProvider).value;

    // IMPORTANT: Listen for changes to navigate to the Lobby
    ref.listen(matchmakingTicketProvider, (previous, next) {
      final ticket = next.value;
      if (ticket != null && ticket.status == 'matched' && ticket.gameRoomId != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LobbyScreen(roomId: ticket.gameRoomId!),
          ),
        );
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [AppColors.surface, AppColors.primaryBg],
            center: Alignment.center,
            radius: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Pulse Effect
            Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(3, (index) => 
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.purple.withOpacity(0.5)),
                    ),
                  ).animate(onPlay: (controller) => controller.repeat())
                   .scale(duration: 2.seconds, begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), delay: (index * 600).ms)
                   .fadeOut()
                ),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(user?.avatarUrl ?? ''),
                ),
              ],
            ),
            
            const SizedBox(height: 60),
            
            Text('SEARCHING FOR OPPONENT', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Text('RANK: ${user?.rank ?? 'Bronze'}', style: AppTextStyles.label.copyWith(color: AppColors.gold)),
            
            const SizedBox(height: 100),
            
            TextButton.icon(
              onPressed: () async {
                if (user != null) {
                  await ref.read(matchmakingRepositoryProvider).cancelSearching(user.uid);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.close, color: AppColors.red),
              label: Text('CANCEL SEARCH', style: AppTextStyles.label.copyWith(color: AppColors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
