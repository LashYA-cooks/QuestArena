// WHAT THIS FILE DOES:
// Shows the player's summary, stats, and quick-start button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/matchmaking_providers.dart';
import '../../../data/models/matchmaking_model.dart';
import '../../../core/utils/rank_calculator.dart';
import '../store_screen.dart';
import '../matchmaking_screen.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) {
          return const Center(child: Text('User profile not found.'));
        }

        final rankColor = RankCalculator.getRankColor(user.rank);
        final totalMatches = user.totalWins + user.totalLosses;
        final winRate = totalMatches == 0
            ? 0
            : ((user.totalWins / totalMatches) * 100).round();

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOP BAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DASHBOARD',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StoreScreen(),
                        ),
                      ),
                      icon: const Icon(
                        Icons.shopping_bag_rounded,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // PLAYER HEADER CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: rankColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: rankColor.withValues(alpha: 0.1),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.surface,
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: user.avatarUrl ?? '',
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(
                                      strokeWidth: 2),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.person),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.username,
                              style: AppTextStyles.headline,
                            ),
                            Text(
                              'Rank: ${user.rank}',
                              style: AppTextStyles.label.copyWith(
                                color: rankColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: user.xp / user.xpToNextLevel,
                                backgroundColor: AppColors.surface,
                                color: rankColor,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Level ${user.level} - ${user.xp}/${user.xpToNextLevel} XP',
                              style: AppTextStyles.label,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'QUICK STATS',
                  style: AppTextStyles.label,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _StatCard(
                      label: 'WINS',
                      value: user.totalWins.toString(),
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      label: 'LOSSES',
                      value: user.totalLosses.toString(),
                      color: AppColors.red,
                    ),
                    const SizedBox(width: 8),
                    _StatCard(
                      label: 'WIN %',
                      value: '$winRate%',
                      color: AppColors.gold,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // BATTLE BUTTON
                GestureDetector(
                  onTap: () async {
                    final ticket = MatchmakingModel(
                      uid: user.uid,
                      username: user.username,
                      avatarUrl: user.avatarUrl,
                      rank: user.rank,
                      searchStartedAt: DateTime.now(),
                    );

                    await ref
                        .read(matchmakingRepositoryProvider)
                        .startSearching(ticket);

                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MatchmakingScreen(),
                        ),
                      );
                    }
                  },
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.purple,
                          Color(0xFF5A3EBC),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(
                            Icons.flash_on_rounded,
                            size: 120,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                              Text(
                                'BATTLE NOW',
                                style: AppTextStyles.display.copyWith(
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'RECENT HISTORY',
                  style: AppTextStyles.label,
                ),

                const SizedBox(height: 12),

                ref.watch(matchHistoryProvider).when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('History Error: $e'),
                      data: (history) {
                        if (history.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppColors.surface,
                                  style: BorderStyle.solid),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.history_rounded,
                                    color: AppColors.textMuted, size: 32),
                                const SizedBox(height: 12),
                                Text(
                                  'No match history yet.\nStart a battle to see your results!',
                                  style: AppTextStyles.label
                                      .copyWith(color: AppColors.textMuted),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: history.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = history[index];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.surface),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (item.isWin
                                              ? AppColors.teal
                                              : AppColors.red)
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      item.isWin
                                          ? Icons.emoji_events_rounded
                                          : Icons.close_rounded,
                                      color: item.isWin
                                          ? AppColors.teal
                                          : AppColors.red,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.isWin
                                              ? 'Victory against ${item.opponentName}'
                                              : 'Defeat by ${item.opponentName}',
                                          style: AppTextStyles.bodyMd.copyWith(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${DateFormat('MMM d, HH:mm').format(item.playedAt)}  •  ${item.myScore}-${item.opponentScore}',
                                          style: AppTextStyles.label
                                              .copyWith(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '+${item.xpGained} XP',
                                    style: AppTextStyles.label.copyWith(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1B1B30),
              Color(0xFF131325),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.surface,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.headline.copyWith(
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.label.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
