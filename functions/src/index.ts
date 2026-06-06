import {onDocumentCreated, onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import axios from "axios";

admin.initializeApp();

/**
 * Automatically populates a game room with questions from an external API
 * when the room is created.
 */
export const onRoomCreated = onDocumentCreated("gameRooms/{roomId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    try {
      // Fetch 10 multiple-choice questions from Open Trivia DB
      const response = await axios.get(
        "https://opentdb.com/api.php?amount=10&type=multiple"
      );

      // Define a type for the result to avoid 'any'
      interface TriviaQuestion {
        question: string;
        correct_answer: string;
        incorrect_answers: string[];
      }

      const questions = response.data.results.map((q: TriviaQuestion) => ({
        question: q.question,
        correct_answer: q.correct_answer,
        incorrect_answers: q.incorrect_answers,
      }));

      // Update the room with real questions
      await snap.ref.update({
        questions: questions,
        status: "waiting", // Ensure it's ready for players
      });
      console.log(`Populated questions for room: ${event.params.roomId}`);
    } catch (error) {
      console.error("Error fetching questions:", error);
    }
  });

/**
 * Handles rewards and stats updates when a game finishes.
 */
export const onGameFinished = onDocumentUpdated("gameRooms/{roomId}",
  async (event) => {
    const newData = event.data?.after.data();
    const oldData = event.data?.before.data();

    if (!newData || !oldData) return;

    // Only trigger if status changed to 'finished'
    if (newData.status === "finished" && oldData.status !== "finished") {
      const winnerId = newData.winnerId;
      const p1Uid = newData.player1.uid;
      const p2Uid = newData.player2.uid;

      const players = [
        {uid: p1Uid, isWinner: winnerId === p1Uid},
        {uid: p2Uid, isWinner: winnerId === p2Uid},
      ];

      for (const p of players) {
        const userRef = admin.firestore().collection("users").doc(p.uid);

        await admin.firestore().runTransaction(async (transaction) => {
          const userDoc = await transaction.get(userRef);
          if (!userDoc.exists) return;

          const data = userDoc.data()!;
          let xp = data.xp || 0;
          let level = data.level || 1;
          let coins = data.coins || 0;
          let wins = data.totalWins || 0;
          let losses = data.totalLosses || 0;

          // Reward amounts
          const xpGained = p.isWinner ? 50 : 15;
          const coinsGained = p.isWinner ? 20 : 5;

          xp += xpGained;
          coins += coinsGained;
          if (p.isWinner) wins++;
          else losses++;

          // Leveling Logic (100 * level XP required)
          let xpToNext = 100 * level;
          while (xp >= xpToNext) {
            xp -= xpToNext;
            level++;
            xpToNext = 100 * level;
          }

          // Rank Logic
          let rank = "Bronze";
          const totalPoints = xp + (level * 1000);
          if (totalPoints >= 10000) rank = "Diamond";
          else if (totalPoints >= 4000) rank = "Platinum";
          else if (totalPoints >= 1500) rank = "Gold";
          else if (totalPoints >= 500) rank = "Silver";

          transaction.update(userRef, {
            xp,
            level,
            xpToNextLevel: xpToNext,
            coins,
            totalWins: wins,
            totalLosses: losses,
            rank,
          });
        });
      }
      console.log(`Rewards processed for room: ${event.params.roomId}`);
    }
  });
