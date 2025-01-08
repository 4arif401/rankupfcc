import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TurnBasedGame extends FlameGame {
  late int playerHealth;
  late int playerAttack;
  late int enemyHealth;
  late int enemyAttack;

  bool isPlayerTurn = true;

  void initializeGame() {
    // Set default values
    playerHealth = 100;
    playerAttack = 20; // Add default value
    enemyHealth = 100;
    enemyAttack = 15;
    isPlayerTurn = true;
  }

  @override
  Future<void> onLoad() async {
    print("Game is loading...");
    await super.onLoad();
    print("Game loaded successfully");

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await loadPlayerStats(userId);
    }

    enemyHealth = 80; // Optional: Adjust enemy stats here
    enemyAttack = 15;
  }

  Future<void> loadPlayerStats(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('Users').doc(userId).get();

      // Use defaults if Firestore fields are missing
      playerHealth = userDoc['health'] ?? 100;
      playerAttack = userDoc['attack'] ?? 20;
    } catch (e) {
      print('Error loading player stats: $e');
      // Fallback to default values in case of error
      playerHealth = 100;
      playerAttack = 20;
    }
  }

  void playerAttackEnemy() {
    if (isPlayerTurn && enemyHealth > 0) {
      enemyHealth -= playerAttack;
      isPlayerTurn = false;

      if (enemyHealth <= 0) {
        showVictoryMessage();
      } else {
        Future.delayed(Duration(seconds: 1), enemyAttackPlayer);
      }
    }
  }

  void enemyAttackPlayer() {
    if (!isPlayerTurn && playerHealth > 0) {
      playerHealth -= enemyAttack;
      isPlayerTurn = true;

      if (playerHealth <= 0) {
        showDefeatMessage();
      }
    }
  }

  void showVictoryMessage() {
    overlays.add('VictoryOverlay');
  }

  void showDefeatMessage() {
    overlays.add('DefeatOverlay');
  }
}
