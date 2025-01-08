import 'package:flutter/material.dart';
import 'turn_based_game.dart';

class DefeatOverlay extends StatelessWidget {
  final TurnBasedGame game;

  const DefeatOverlay({required this.game});

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
              'Defeat!',
              style: TextStyle(fontSize: 32, color: Colors.redAccent),
            ),
            ElevatedButton(
              onPressed: () {
                game.overlays.remove('DefeatOverlay');
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
