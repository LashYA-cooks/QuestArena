// WHAT THIS FILE DOES:
// The "Waiting Area" where players face off before the quiz begins.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/game_providers.dart';
import '../../providers/user_providers.dart';
import 'game_screen.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final String roomId;
  const LobbyScreen({super.key, required this.roomId});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  int _countdown = 3;
  Timer? _timer;

  void _startCountdown() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => GameScreen(roomId: widget.roomId)),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(gameRoomProvider(widget.roomId));
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (room) {
          if (room == null) return const Center(child: Text('Room not found'));

          final p1 = room.player1;
          final p2 = room.player2;
          
          // If both players are ready, start the timer
          if (p1['isReady'] == true && p2 != null && p2['isReady'] == true) {
            _startCountdown();
          }

          return Stack(
            children: [
              Column(
                children: [
                  // Player 1 (Top)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: AppColors.purple.withAlpha(25),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 60, 
                            backgroundColor: AppColors.surface,
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: p1['avatarUrl'] ?? '',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                errorWidget: (context, url, error) => const Icon(Icons.person, size: 50),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(p1['username'], style: AppTextStyles.headline),
                          _ReadyBadge(isReady: p1['isReady'] ?? false),
                        ],
                      ),
                    ),
                  ),
                  
                  // Player 2 (Bottom)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: AppColors.gold.withAlpha(12),
                      child: p2 == null 
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: AppColors.gold),
                              const SizedBox(height: 24),
                              Text('WAITING FOR OPPONENT', style: AppTextStyles.label),
                              const SizedBox(height: 8),
                              Text('ROOM CODE:', style: AppTextStyles.label.copyWith(fontSize: 10)),
                              Text(room.roomCode, style: AppTextStyles.display.copyWith(color: AppColors.gold, fontSize: 32)),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ReadyBadge(isReady: p2['isReady'] ?? false),
                              const SizedBox(height: 16),
                              Text(p2['username'], style: AppTextStyles.headline),
                          CircleAvatar(
                            radius: 60, 
                            backgroundColor: AppColors.surface,
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: p2['avatarUrl'] ?? '',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                errorWidget: (context, url, error) => const Icon(Icons.person, size: 50),
                              ),
                            ),
                          ),
                        ],
                          ),
                    ),
                  ),
                ],
              ),
              
              // VS Circle
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: AppColors.primaryBg, shape: BoxShape.circle),
                  child: Text('VS', style: AppTextStyles.display.copyWith(color: AppColors.gold)),
                ).animate().scale(delay: 400.ms, curve: Curves.elasticOut),
              ),

              // Countdown Overlay
              if (p1['isReady'] == true && p2 != null && p2['isReady'] == true)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text('$_countdown', style: AppTextStyles.display.copyWith(fontSize: 100))
                        .animate(key: ValueKey(_countdown))
                        .scale(duration: 500.ms)
                        .fadeOut(delay: 500.ms),
                  ),
                ),

              // Ready Button
              if (p2 != null && !(p1['isReady'] == true && p2['isReady'] == true))
                Positioned(
                  bottom: 40,
                  left: 40,
                  right: 40,
                  child: ElevatedButton(
                    onPressed: () {
                      final isP1 = currentUser?.uid == p1['uid'];
                      ref.read(gameRepositoryProvider).setPlayerReady(widget.roomId, isP1 ? 1 : 2);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('I AM READY!'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReadyBadge extends StatelessWidget {
  final bool isReady;
  const _ReadyBadge({required this.isReady});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isReady ? AppColors.teal : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isReady ? 'READY' : 'WAITING...',
        style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
