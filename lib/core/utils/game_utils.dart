// WHAT THIS FILE DOES:
// Utility functions for game logic.

import 'dart:math';

class GameUtils {
  // Generates a random 6-character uppercase alphanumeric code
  static String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed confusing chars like O, 0, I, 1
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }
}
