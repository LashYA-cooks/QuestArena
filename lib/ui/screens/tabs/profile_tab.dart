// WHAT THIS FILE DOES:
// Displays the player's detailed stats and achievements grid.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/auth_providers.dart';
import 'edit_profile_screen.dart';
class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final totalMatches = user.totalWins + user.totalLosses;

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
            CircleAvatar(radius: 50,
                backgroundImage:
                NetworkImage(user.avatarUrl ?? '')
            ),
            const SizedBox(height: 16),

            Column(
              children: [
                Text(
                  user.username,
                  style: AppTextStyles.headline,
                ),

                Text(
                  user.rank,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.gold,
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1B1B30),
                    Color(0xFF131325),
                  ],
                ),

                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileInfoCard(
                          title: 'RANK',
                          value: user.rank,
                          icon: Icons.workspace_premium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProfileInfoCard(
                          title: 'COINS',
                          value: '${user.coins}',
                          icon: Icons.monetization_on,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _ProfileInfoCard(
                          title: 'MATCHES',
                          value: '$totalMatches',
                          icon: Icons.sports_esports,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProfileInfoCard(
                          title: 'LEVEL',
                          value: '${user.level}',
                          icon: Icons.trending_up,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'XP PROGRESS',
                      style: AppTextStyles.label,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: user.xp / user.xpToNextLevel,
                      minHeight: 10,
                      backgroundColor: AppColors.surface,
                      color: AppColors.gold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '${user.xp}/${user.xpToNextLevel} XP',
                    style: AppTextStyles.label,
                  ),
                ],
              ),
            ),







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

                    gradient: isUnlocked
                        ? const LinearGradient(
                      colors: [
                        Color(0xFF1B1B30),
                        Color(0xFF131325),
                      ],
                    )
                        : null,
                    color: isUnlocked
                        ? null
                        : AppColors.cardBg.withOpacity(0.3),

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
class _ProfileInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ProfileInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.surface,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.gold,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headline,
          ),
          Text(
            title,
            style: AppTextStyles.label,
          ),
        ],
      ),
    );
  }
}
