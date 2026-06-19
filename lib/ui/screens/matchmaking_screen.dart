// WHAT THIS FILE DOES:
// Highly polished Animated UI for matchmaking.
// Uses a radar-inspired design to maintain a high-tech "Gaming" feel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/matchmaking_providers.dart';
import '../../providers/user_providers.dart';
import 'lobby_screen.dart';

class MatchmakingScreen extends ConsumerWidget {
  const MatchmakingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    // Navigation logic: Listen for the ticket to become 'matched'
    ref.listen(matchmakingTicketProvider, (previous, next) {
      final ticket = next.value;
      if (ticket != null && ticket.status == 'matched' && ticket.gameRoomId != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LobbyScreen(roomId: ticket.gameRoomId!)),
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // 1. Cyberpunk-themed background
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primaryBg,
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFF1A1A2E), AppColors.primaryBg],
              ),
            ),
          ),

          // 2. Animated Radar Rings & Avatar (Perfectly Centered)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Sonar Rings
                    ...List.generate(4, (index) {
                      return Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.purple.withValues(alpha: 0.1 * (4 - index)),
                            width: 1,
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .scale(
                        duration: 3.seconds,
                        begin: const Offset(0.2, 0.2),
                        end: const Offset(1.3, 1.3),
                        curve: Curves.easeOut,
                        delay: (index * 800).ms,
                      )
                      .fadeOut();
                    }),

                    // Rotating Radar Sweep
                    RepaintBoundary(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.purple.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .rotate(duration: 4.seconds),
                    ),

                    // Player Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.purple.withValues(alpha: 0.4),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.surface,
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user?.avatarUrl ?? '',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(color: AppColors.purple),
                            errorWidget: (context, url, error) => const Icon(Icons.person, size: 50, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),

                // Center Text Group
                Text(
                  'FINDING OPPONENT',
                  style: AppTextStyles.display.copyWith(fontSize: 20, letterSpacing: 4),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1.seconds),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'RANK: ${user?.rank.toUpperCase() ?? 'BRONZE'}',
                    style: AppTextStyles.label.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 32),

                // Animated status messages
                DefaultTextStyle(
                  style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
                  child: const AnimatedStatusSwitcher(),
                ),
              ],
            ),
          ),

          // 3. Cancel Button (Fixed at Bottom)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton.icon(
                onPressed: () async {
                  if (user != null) {
                    await ref.read(matchmakingRepositoryProvider).cancelSearching(user.uid);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.close_rounded, color: AppColors.red, size: 20),
                label: Text(
                  'CANCEL SEARCH',
                  style: AppTextStyles.label.copyWith(color: AppColors.red, fontWeight: FontWeight.bold),
                ),
              ).animate().fadeIn(delay: 500.ms),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedStatusSwitcher extends StatefulWidget {
  const AnimatedStatusSwitcher({super.key});

  @override
  State<AnimatedStatusSwitcher> createState() => _AnimatedStatusSwitcherState();
}

class _AnimatedStatusSwitcherState extends State<AnimatedStatusSwitcher> {
  int _index = 0;
  final _messages = [
    'Scanning nearby warriors...',
    'Checking skill brackets...',
    'Connecting to battle arena...',
    'Preparing the questions...',
    'Almost there...',
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _index = (_index + 1) % _messages.length;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _messages[_index],
      key: ValueKey(_messages[_index]),
      textAlign: TextAlign.center,
    ).animate().fadeIn().slideY(begin: 0.1, end: 0).then(delay: 2.seconds).fadeOut();
  }
}
