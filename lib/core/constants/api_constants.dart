// WHAT THIS FILE DOES:
// Centralizes all external API endpoints and constants.
// Keep this file secure and avoid committing sensitive variations if possible.

class ApiConstants {
  ApiConstants._();

  // Open Trivia Database
  static const String triviaBaseUrl = "https://opentdb.com/api.php";
  static const String triviaQuestionsPath = "?amount=10&type=multiple";
  static const String triviaUrl = "$triviaBaseUrl$triviaQuestionsPath";

  // Firebase Configuration (Centralized for easier management)
  // Note: Firebase API keys are technically public identifiers for client-side apps,
  // but we centralize them here to make the codebase cleaner.
  static const String firebaseProjectId = "questarena-35867";
}
