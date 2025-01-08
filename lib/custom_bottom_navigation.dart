import 'package:flutter/material.dart';
import 'challenge.dart'; // Import your ChallengePage
import 'profile.dart'; // Import your ProfilePage
import 'friends.dart'; // Import your FriendsPage
import 'leaderboard.dart'; // Import your LeaderboardPage
import 'game_screen.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  CustomBottomNavigationBar({required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return; // Prevent navigating to the same page

    Widget page;
    if (index == 0) {
      page = ChallengePage();
    } else if (index == 1) {
      page = LeaderboardPage();
    } else if (index == 2) {
      page = FriendsPage();
    } else {
      page = ProfilePage();
    }

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const Curve curve = Curves.easeInOut;

          // Combine scale and fade transitions
          var fadeTransition = Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
          var scaleTransition = Tween(begin: 0.8, end: 1.0).chain(CurveTween(curve: curve));

          return FadeTransition(
            opacity: animation.drive(fadeTransition),
            child: ScaleTransition(
              scale: animation.drive(scaleTransition),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400), // Adjust duration as needed
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BottomNavigationBar(
          backgroundColor: Colors.black87,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center, color: Colors.tealAccent),
              label: 'Challenge',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard, color: Colors.tealAccent),
              label: 'Leaderboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group, color: Colors.tealAccent),
              label: 'Friends',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, color: Colors.tealAccent),
              label: 'Profile',
            ),
          ],
          currentIndex: currentIndex,
          selectedItemColor: Colors.tealAccent,
          unselectedItemColor: Colors.white70,
          onTap: (index) => _onItemTapped(context, index),
        ),
        FloatingActionButton(
          heroTag: "startGame",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GameScreen(
                  friendId: "G1m7sxFkxMeXCmaRgKCTBXba7Jx1"),
              ),
            );
          },
          backgroundColor: Colors.tealAccent,
          child: Icon(Icons.play_arrow, color: Colors.black),
        ),
      ],
    );
  }

}