import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/user_providers.dart';
import '../../../data/models/user_model.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _usernameController =
  TextEditingController();

  String selectedAvatar =
      'https://api.dicebear.com/7.x/avataaars/png?seed=Felix';

  final List<String> avatars = [
    'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Aneka',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Buddy',
    'https://api.dicebear.com/7.x/avataaars/png?seed=Max',
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_usernameController.text.isEmpty) {
      _usernameController.text = user.username;
    }
    if (selectedAvatar.isEmpty) {
      selectedAvatar = user.avatarUrl ?? avatars.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:
              NetworkImage(selectedAvatar),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final avatar = avatars[index];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAvatar = avatar;
                      });
                    },
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 8),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundImage:
                        NetworkImage(avatar),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final updatedUser = UserModel(
                    uid: user.uid,
                    username: _usernameController.text.trim(),
                    email: user.email,
                    avatarUrl: selectedAvatar,
                    level: user.level,
                    xp: user.xp,
                    xpToNextLevel: user.xpToNextLevel,
                    coins: user.coins,
                    totalWins: user.totalWins,
                    totalLosses: user.totalLosses,
                    rank: user.rank,
                    achievements: user.achievements,
                  );

                  await ref
                      .read(userRepositoryProvider)
                      .updateUserProfile(updatedUser);

                  ref.invalidate(currentUserProvider);

                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'SAVE CHANGES',
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}