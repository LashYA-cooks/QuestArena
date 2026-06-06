// WHAT THIS FILE DOES:
// Displays the player's detailed stats and achievements grid.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../core/errors/result.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) return const Center(child: Text('User not found'));

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
            elevation: 0,
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
                
                // Stats Summary (Added for better visibility)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ProfileStat(label: 'LEVEL', value: '${user.level}'),
                    _ProfileStat(label: 'WINS', value: '${user.totalWins}'),
                    _ProfileStat(label: 'COINS', value: '${user.coins}'),
                  ],
                ),

                const SizedBox(height: 40),
                
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

                const SizedBox(height: 48),

                // Delete Account Button
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmation(context, ref, user.uid),
                  icon: const Icon(Icons.delete_forever_rounded, color: AppColors.red, size: 20),
                  label: Text(
                    'DELETE ACCOUNT', 
                    style: AppTextStyles.label.copyWith(color: AppColors.red, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('DELETE ACCOUNT?', style: AppTextStyles.headline.copyWith(color: AppColors.red)),
        content: Text(
          'This action is permanent. All your XP, coins, and achievements will be lost forever.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: AppTextStyles.label),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // 1. Delete Firestore data first
              await ref.read(userRepositoryProvider).deleteUserProfile(uid);
              
              // 2. Delete Auth account
              final result = await ref.read(authRepositoryProvider).deleteAccount();
              
              if (context.mounted && result is Failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text((result as Failure).error.message),
                    backgroundColor: AppColors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headline.copyWith(color: AppColors.gold, fontSize: 24)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 10)),
      ],
    );
  }
}
