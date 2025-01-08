import 'package:flutter/material.dart';
import 'turn_based_game.dart';

class VictoryOverlay extends StatelessWidget {
  final TurnBasedGame game;

  const VictoryOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.black54,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Victory!',
              style: TextStyle(fontSize: 32, color: Colors.tealAccent),
            ),
            ElevatedButton(
              onPressed: () {
                game.overlays.remove('VictoryOverlay');
                Navigator.pop(context); // Exit the game
              },
              child: Text('Back to Menu'),
            ),
          ],
        ),
      ),
    );
  }
}
