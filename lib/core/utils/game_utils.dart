// WHAT THIS FILE DOES:
// Utility functions for game logic.

import 'dart:math';

class GameUtils {
  // Decodes common HTML entities from the Open Trivia Database
  static String decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&hellip;', '...')
        .replaceAll('&deg;', '°');
  }

  // Generates a random 6-character uppercase alphanumeric code
  static String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed confusing chars like O, 0, I, 1
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  // Emergency Fallback questions in case Cloud Function fails
  static List<Map<String, dynamic>> getFallbackQuestions() {
    return [
      {
        'question': 'Which planet is known as the Red Planet?',
        'correct_answer': 'Mars',
        'incorrect_answers': ['Venus', 'Jupiter', 'Saturn'],
      },
      {
        'question': 'What is the capital of France?',
        'correct_answer': 'Paris',
        'incorrect_answers': ['London', 'Berlin', 'Madrid'],
      },
      {
        'question': 'Which is the largest ocean on Earth?',
        'correct_answer': 'Pacific Ocean',
        'incorrect_answers': ['Atlantic Ocean', 'Indian Ocean', 'Arctic Ocean'],
      },
    ];
  }
}
