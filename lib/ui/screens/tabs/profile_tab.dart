// WHAT THIS FILE DOES:
// Displays the player's detailed stats and achievements grid.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/auth_providers.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const Center(child: CircularProgressIndicator());

    // List of all possible achievements to show "Locked" ones
    final allAchievements = [
      {'id': 'first_win', 'name': 'First Blood', 'desc': 'Win your first match', 'icon': Icons.flash_on_rounded},
      {'id': 'on_fire', 'name': 'On Fire', 'desc': 'Win 3 games in a row', 'icon': Icons.whatshot},
      {'id': 'veteran', 'name': 'Veteran', 'desc': 'Play 100 matches', 'icon': Icons.military_tech},
      {'id': 'scholar', 'name': 'Scholar', 'desc': 'Get 10/10 in one match', 'icon': Icons.school},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('PLAYER PROFILE', style: AppTextStyles.display.copyWith(fontSize: 18)),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.red),
            onPressed: () => ref.read(authRepositoryProvider).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            CircleAvatar(radius: 50, backgroundImage: NetworkImage(user.avatarUrl ?? '')),
            const SizedBox(height: 16),
            Text(user.username, style: AppTextStyles.headline),
            Text(user.rank, style: AppTextStyles.label.copyWith(color: AppColors.gold)),
            
            const SizedBox(height: 32),
            
            // Achievement Grid
            Text('ACHIEVEMENTS', style: AppTextStyles.label),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: allAchievements.length,
              itemBuilder: (context, index) {
                final achievement = allAchievements[index];
                final isUnlocked = user.achievements.contains(achievement['id']);
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUnlocked ? AppColors.cardBg : AppColors.cardBg.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isUnlocked ? AppColors.gold : AppColors.surface),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        achievement['icon'] as IconData, 
                        color: isUnlocked ? AppColors.gold : AppColors.textMuted,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        achievement['name'] as String, 
                        style: AppTextStyles.bodyMd.copyWith(
                          fontSize: 14,
                          color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
