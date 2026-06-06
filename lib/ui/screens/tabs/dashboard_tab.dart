// WHAT THIS FILE DOES:
// Shows the player's summary, stats, and quick-start button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../data/models/match_history_model.dart';
import '../store_screen.dart';
import '../../../core/utils/rank_calculator.dart';
import 'package:intl/intl.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) return const Center(child: Text('User not found'));

        final rankColor = RankCalculator.getRankColor(user.rank);

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar with Store
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('DASHBOARD', style: AppTextStyles.headline.copyWith(fontSize: 18)),
                    IconButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen())),
                      icon: const Icon(Icons.shopping_bag_rounded, color: AppColors.gold),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Player Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: rankColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: rankColor.withOpacity(0.1),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage(user.avatarUrl ?? ''),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.username, style: AppTextStyles.headline),
                            Text('Rank: ${user.rank}', style: AppTextStyles.label.copyWith(color: rankColor)),
                            const SizedBox(height: 8),
                            // XP Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: user.xp / user.xpToNextLevel,
                                backgroundColor: AppColors.surface,
                                color: rankColor,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text('Level ${user.level} - ${user.xp}/${user.xpToNextLevel} XP', style: AppTextStyles.label),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text('QUICK STATS', style: AppTextStyles.label),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    _StatCard(label: 'WINS', value: user.totalWins.toString(), color: AppColors.teal),
                    const SizedBox(width: 16),
                    _StatCard(label: 'LOSSES', value: user.totalLosses.toString(), color: AppColors.red),
                  ],
                ),
                
                const SizedBox(height: 32),

                Text('RECENT HISTORY', style: AppTextStyles.label),
                const SizedBox(height: 12),
                
                ref.watch(matchHistoryProvider).when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('History Error: $e'),
                  data: (history) {
                    if (history.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surface, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.history_rounded, color: AppColors.textMuted, size: 32),
                            const SizedBox(height: 12),
                            Text(
                              'No match history yet.\nStart a battle to see your results!',
                              style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
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
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                                  color: (item.isWin ? AppColors.teal : AppColors.red).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.isWin ? Icons.emoji_events_rounded : Icons.close_rounded, 
                                  color: item.isWin ? AppColors.teal : AppColors.red,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.isWin ? 'Victory against ${item.opponentName}' : 'Defeat by ${item.opponentName}',
                                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${DateFormat('MMM d, HH:mm').format(item.playedAt)}  •  ${item.myScore}-${item.opponentScore}',
                                      style: AppTextStyles.label.copyWith(fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '+${item.xpGained} XP', 
                                style: AppTextStyles.label.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
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

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surface),
        ),
        child: Column(
          children: [
            Text(value, style: AppTextStyles.headline.copyWith(color: color)),
            Text(label, style: AppTextStyles.label),
          ],
        ),
      ),
    );
  }
}
