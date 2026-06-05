// WHAT THIS FILE DOES:
// Utility functions for game logic.

import 'dart:math';

class GameUtils {
  // Generates a random 6-character uppercase alphanumeric code
  static String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed confusing chars like O, 0, I, 1
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  static List<Map<String, dynamic>> getMockQuestions() {
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
      {
        'question': 'How many continents are there?',
        'correct_answer': '7',
        'incorrect_answers': ['5', '6', '8'],
      },
      {
        'question': 'What is the square root of 64?',
        'correct_answer': '8',
        'incorrect_answers': ['6', '7', '9'],
      },
      {
        'question': 'Who wrote "Romeo and Juliet"?',
        'correct_answer': 'William Shakespeare',
        'incorrect_answers': ['Charles Dickens', 'Mark Twain', 'Jane Austen'],
      },
      {
        'question': 'What is the chemical symbol for gold?',
        'correct_answer': 'Au',
        'incorrect_answers': ['Ag', 'Fe', 'Cu'],
      },
      {
        'question': 'Which is the fastest land animal?',
        'correct_answer': 'Cheetah',
        'incorrect_answers': ['Lion', 'Gazelle', 'Leopard'],
      },
      {
        'question': 'What is the largest planet in our solar system?',
        'correct_answer': 'Jupiter',
        'incorrect_answers': ['Saturn', 'Neptune', 'Earth'],
      },
      {
        'question': 'Which element does "O" represent on the periodic table?',
        'correct_answer': 'Oxygen',
        'incorrect_answers': ['Osmium', 'Oganesson', 'Gold'],
      },
    ];
  }
}
