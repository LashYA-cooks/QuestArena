// WHAT THIS FILE DOES:
// Handles the creation and joining of private matches via 6-digit codes.
//
// KEY CONCEPTS IN THIS FILE:
// • Custom Logic: Generating a 6-digit alphanumeric code for private matches.
// • Querying: Finding a room in Firestore based on a 'roomCode' rather than a 'docId'.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:questarena/core/constants/colors.dart';
import 'package:questarena/core/constants/text_styles.dart';
import 'package:questarena/core/utils/game_utils.dart';
import 'package:questarena/providers/game_providers.dart';
import 'package:questarena/providers/user_providers.dart';
import 'package:questarena/ui/widgets/custom_text_field.dart';
import 'lobby_screen.dart';

class PrivateRoomScreen extends ConsumerStatefulWidget {
  const PrivateRoomScreen({super.key});

  @override
  ConsumerState<PrivateRoomScreen> createState() => _PrivateRoomScreenState();
}

class _PrivateRoomScreenState extends ConsumerState<PrivateRoomScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  void _createRoom() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);
    
    // Generate a unique 6-digit code (e.g., A7B2X9)
    final code = GameUtils.generateRoomCode();
    
    // Create the room in Firestore
    // Note: We use ref.read(gameRepositoryProvider) which returns a GameRepository
    final roomId = await ref.read(gameRepositoryProvider).createPrivateRoom(user.toJson(), code);
    
    if (mounted) {
      setState(() => _isLoading = false);
      // Navigate to Lobby and wait for friend to enter the code
      Navigator.push(context, MaterialPageRoute(builder: (_) => LobbyScreen(roomId: roomId)));
    }
  }

  void _joinRoom() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit code'), backgroundColor: AppColors.red),
      );
      return;
    }

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);
    
    // Attempt to find a room with this code
    final roomId = await ref.read(gameRepositoryProvider).joinPrivateRoom(user.toJson(), code);

    if (mounted) {
      setState(() => _isLoading = false);
      if (roomId != null) {
        // Success! Navigate to Lobby
        Navigator.push(context, MaterialPageRoute(builder: (_) => LobbyScreen(roomId: roomId)));
      } else {
        // Code was invalid, expired, or room is full
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or full room code'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('PRIVATE DUEL', style: AppTextStyles.display),
              const SizedBox(height: 8),
              Text('Challenge a specific friend', style: AppTextStyles.label),
              const SizedBox(height: 40),
              
              // Create Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBg, 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surface),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.add_box_rounded, color: AppColors.gold, size: 40),
                    const SizedBox(height: 16),
                    const Text('Host a new match'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold, 
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('CREATE ROOM CODE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              const Center(child: Text('OR', style: TextStyle(color: AppColors.textMuted))),
              const SizedBox(height: 32),
              
              // Join Section
              CustomTextField(
                controller: _codeController, 
                hintText: 'ENTER 6-DIGIT CODE', 
                icon: Icons.vpn_key_rounded
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _joinRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('JOIN FRIEND', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
