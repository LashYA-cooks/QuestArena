// WHAT THIS FILE DOES:
// The entry point for all game modes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../data/models/matchmaking_model.dart';
import '../../../providers/matchmaking_providers.dart';
import '../matchmaking_screen.dart';
import '../private_room_screen.dart';

class BattleTab extends ConsumerWidget {
  const BattleTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BATTLE HUB', style: AppTextStyles.display),
              Text('Select your challenge', style: AppTextStyles.label),
              
              const SizedBox(height: 40),
              
              _BattleModeCard(
                title: 'RANKED MATCH',
                subtitle: 'Compete for XP and Rank',
                icon: Icons.flash_on_rounded,
                color: AppColors.purple,
                onTap: () async {
                  if (user != null) {
                    final ticket = MatchmakingModel(
                      uid: user.uid,
                      username: user.username,
                      avatarUrl: user.avatarUrl,
                      rank: user.rank,
                      searchStartedAt: DateTime.now(),
                    );
                    await ref.read(matchmakingRepositoryProvider).startSearching(ticket);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchmakingScreen()));
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              _BattleModeCard(
                title: 'PRIVATE DUEL',
                subtitle: 'Play against a friend',
                icon: Icons.vpn_key_rounded,
                color: AppColors.gold,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivateRoomScreen()));
                },
              ),
              
              const SizedBox(height: 16),
              
              _BattleModeCard(
                title: 'PRACTICE',
                subtitle: 'Sharpen your skills (No XP)',
                icon: Icons.psychology_rounded,
                color: AppColors.teal,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BattleModeCard({
    required this.title, 
    required this.subtitle, 
    required this.icon, 
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surface),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headline.copyWith(fontSize: 18)),
                  Text(subtitle, style: AppTextStyles.label),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.surface, size: 16),
          ],
        ),
      ),
    );
  }
}
