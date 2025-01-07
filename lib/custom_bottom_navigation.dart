import 'package:flutter/material.dart';
import 'challenge.dart'; // Import your ChallengePage
import 'profile.dart'; // Import your ProfilePage
import 'friends.dart'; // Import your FriendsPage
import 'leaderboard.dart'; // Import your LeaderboardPage

class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;

  CustomBottomNavigationBar({required this.currentIndex});

  @override
  _CustomBottomNavigationBarState createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  bool _isLoading = false;

  void _onItemTapped(BuildContext context, int index) async {
    if (index == widget.currentIndex) return; // Prevent navigating to the same page

    setState(() {
      _isLoading = true; // Show loading overlay
    });

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

    // Simulate a delay for loading or processing
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoading = false; // Hide loading overlay
    });

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
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.black87,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center, color: Colors.tealAccent),
                label: 'Challenge',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.leaderboard, color: Colors.tealAccent), // Icon for leaderboard
                label: 'Leaderboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group, color: Colors.tealAccent), // Icon for friends
                label: 'Friends',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person, color: Colors.tealAccent),
                label: 'Profile',
              ),
            ],
            currentIndex: widget.currentIndex,
            selectedItemColor: Colors.tealAccent,
            unselectedItemColor: Colors.white70,
            onTap: (index) => _onItemTapped(context, index),
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black87.withOpacity(0.7), // Semi-transparent background
              child: Center(
                child: SizedBox(
                  height: 80,
                  width: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
