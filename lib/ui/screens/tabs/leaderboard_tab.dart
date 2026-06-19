// WHAT THIS FILE DOES:
// Displays the global rankings with a "Hall of Fame" feel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/leaderboard_providers.dart';
import '../../../providers/user_providers.dart';

class LeaderboardTab extends ConsumerWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text('RANKINGS', style: AppTextStyles.display.copyWith(fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (players) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final isMe = player.uid == currentUser?.uid;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.purple.withOpacity(0.2) : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isMe ? AppColors.purple : AppColors.surface,
                    width: isMe ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Rank Number
                    SizedBox(
                      width: 40,
                      child: _RankBadge(index: index),
                    ),
                    
                    // Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.surface,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: player.avatarUrl ?? '',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 1),
                          errorWidget: (context, url, error) => const Icon(Icons.person, size: 20),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Name & Rank Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            player.username, 
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                              color: isMe ? AppColors.gold : AppColors.textPrimary,
                            ),
                          ),
                          Text('LVL ${player.level} • ${player.rank}', style: AppTextStyles.label.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                    
                    // XP
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${player.xp}', style: AppTextStyles.headline.copyWith(fontSize: 18, color: AppColors.gold)),
                        Text('XP', style: AppTextStyles.label.copyWith(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int index;
  const _RankBadge({required this.index});

  @override
  Widget build(BuildContext context) {
    if (index == 0) return const Icon(Icons.workspace_premium, color: AppColors.gold, size: 28);
    if (index == 1) return const Icon(Icons.workspace_premium, color: AppColors.rankSilver, size: 24);
    if (index == 2) return const Icon(Icons.workspace_premium, color: AppColors.rankBronze, size: 24);
    
    return Text(
      '${index + 1}', 
      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }
}
