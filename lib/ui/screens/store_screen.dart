// WHAT THIS FILE DOES:
// Virtual marketplace for cosmetic items.
//
// KEY CONCEPTS IN THIS FILE:
// • Transaction Logic: Ensuring coins are only deducted if the purchase succeeds.
// • Feedback: Using Snackbars and Dialogs to confirm user actions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/user_providers.dart';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  void _showPurchaseDialog(BuildContext context, Map<String, dynamic> item, int userCoins) {
    if (userCoins < (item['price'] as int)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins!'), backgroundColor: AppColors.red),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Confirm Purchase', style: AppTextStyles.headline),
        content: Text('Buy ${item['name']} for ${item['price']} coins?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              // In a real app, this would be a Firestore Transaction
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Purchased ${item['name']}!'), backgroundColor: AppColors.teal),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            child: const Text('BUY NOW', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    final mockItems = [
      {'id': 'viking_helmet', 'name': 'Viking Helmet', 'price': 500, 'icon': Icons.shield},
      {'id': 'golden_frame', 'name': 'Golden Frame', 'price': 1000, 'icon': Icons.crop_free},
      {'id': 'wizard_hat', 'name': 'Wizard Hat', 'price': 750, 'icon': Icons.auto_awesome},
      {'id': 'dragon_pet', 'name': 'Dragon Pet', 'price': 2500, 'icon': Icons.pets},
    ];

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text('VIRTUAL STORE', style: AppTextStyles.display.copyWith(fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 18),
                    const SizedBox(width: 6),
                    Text('${user?.coins ?? 0}', style: AppTextStyles.headline.copyWith(fontSize: 14, color: AppColors.gold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: mockItems.length,
        itemBuilder: (context, index) {
          final item = mockItems[index];
          return Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.surface),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item['icon'] as IconData, size: 50, color: AppColors.purple),
                const SizedBox(height: 12),
                Text(item['name'] as String, style: AppTextStyles.bodyMd),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _showPurchaseDialog(context, item, user?.coins ?? 0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold, 
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('${item['price']} C', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
