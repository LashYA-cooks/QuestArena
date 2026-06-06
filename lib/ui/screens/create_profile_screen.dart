// WHAT THIS FILE DOES:
// Screen for first-time users to set up their profile.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/auth_providers.dart';
import '../../providers/user_providers.dart';
import '../../data/models/user_model.dart';
import '../../core/errors/result.dart';
import '../widgets/custom_text_field.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _usernameController = TextEditingController();
  String _selectedAvatar = 'https://api.dicebear.com/7.x/avataaars/png?seed=Felix';
  bool _isLoading = false;

  final List<String> _avatars = [
    'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Aneka',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Buddy',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Max',
  ];

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a username'), backgroundColor: AppColors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final currentUser = ref.read(authStateProvider).value;

    if (currentUser != null) {
      final newUser = UserModel(
        uid: currentUser.uid,
        email: currentUser.email ?? '',
        username: username,
        avatarUrl: _selectedAvatar,
      );

      final result = await ref.read(userRepositoryProvider).createUserProfile(newUser);

      if (mounted) {
        setState(() => _isLoading = false);
        if (result case Failure(error: final e)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: AppColors.red),
          );
        } else {
          ref.invalidate(currentUserProvider);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent going back to login
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Initialize Profile', style: AppTextStyles.headline),
                  const SizedBox(height: 8),
                  Text('Choose your warrior name and avatar',
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _avatars.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final isSelected = _selectedAvatar == _avatars[index];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAvatar = _avatars[index]),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: isSelected ? AppColors.gold : Colors.transparent, width: 3),
                            ),
                            child: CircleAvatar(radius: 40, backgroundImage: NetworkImage(_avatars[index])),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _usernameController,
                    hintText: 'Enter Unique Username',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 100),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Start Adventure',
                            style: AppTextStyles.bodyLg
                                .copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
