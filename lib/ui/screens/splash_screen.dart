// WHAT THIS FILE DOES:
// The first screen a user sees. Handles logo animation and initial auth checking.
//
// KEY CONCEPTS IN THIS FILE:
// • flutter_animate: A declarative way to add complex animations with very little code.
// • ConsumerWidget: A Riverpod widget that allows us to listen to providers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Icon
            const Icon(
              Icons.shield_rounded,
              size: 100,
              color: AppColors.gold,
            )
                .animate()
                .fade(duration: 800.ms)
                .scale(delay: 200.ms, curve: Curves.elasticOut),

            const SizedBox(height: 24),

            // App Name
            Text(
              'QUESTARENA',
              style: AppTextStyles.display.copyWith(
                letterSpacing: 2,
                fontSize: 26,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .slideY(begin: 1, end: 0, duration: 600.ms, curve: Curves.easeOut)
                .fadeIn(),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              'BATTLE OF WITS',
              style: AppTextStyles.label.copyWith(color: AppColors.gold),
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
