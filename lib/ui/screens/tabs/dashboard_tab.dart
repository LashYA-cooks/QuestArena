// WHAT THIS FILE DOES:
// Shows the player's summary, stats, and quick-start button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';

import '../matchmaking_screen.dart';
import '../store_screen.dart';
import '../../../data/models/matchmaking_model.dart';
import '../../../providers/matchmaking_providers.dart';

import '../../../core/utils/rank_calculator.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    if (user == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
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
              color: rankColor.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: rankColor.withOpacity(0.1),
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage:
                  NetworkImage(user.avatarUrl ?? ''),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                      borderRadius:
                      BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value:
                        user.xp / user.xpToNextLevel,
                        backgroundColor:
                        AppColors.surface,
                        color: rankColor,
                        minHeight: 8,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.xp}/${user.xpToNextLevel} XP',
                          style: AppTextStyles.label,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user.xpToNextLevel - user.xp} XP to next rank',
                          style:
                          AppTextStyles.label.copyWith(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
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
                  builder: (_) =>
                  const MatchmakingScreen(),
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
              borderRadius:
              BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple
                      .withOpacity(0.5),
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
                    color: Colors.white
                        .withOpacity(0.1),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                      Text(
                        'BATTLE NOW',
                        style: AppTextStyles.display
                            .copyWith(
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

        ListView.separated(
            shrinkWrap: true,
            physics:
            const NeverScrollableScrollPhysics(),
            itemCount: 2,
            separatorBuilder: (_, __) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius:
            BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                index == 0
                    ? Icons.emoji_events_rounded
                    : Icons.close_rounded,
                color: index == 0
                    ? AppColors.teal
                    : AppColors.red,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      index == 0
                          ? 'Won against ProGamer'
                          : 'Lost to QuizMaster',
                      style:
                      AppTextStyles.bodyMd,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '2 mins ago',
                      style: AppTextStyles.label
                          .copyWith(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                index == 0
                    ? '+50 XP'
                    : '+15 XP',
                style: AppTextStyles.label,
              ),
            ],
          ),
        ),
      ),
      ],
    ),
    ),
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
            Text(
              label,
              style: AppTextStyles.label,
            ),
          ],
        ),
      ),
    );
  }
}