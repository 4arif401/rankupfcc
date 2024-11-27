import 'package:flutter/material.dart';
import 'challenge.dart'; // Import your ChallengePage
import 'profile.dart'; // Import your ProfilePage
import 'friends.dart'; // Import your FriendsPage (create this page if it doesn't exist)

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex; // To highlight the current tab

  CustomBottomNavigationBar({required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ChallengePage()),
        (route) => false,
      );
    } else if (index == 1) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => FriendsPage()), // Navigate to FriendsPage
        (route) => false,
      );
    } else if (index == 2) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.black87,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center, color: Colors.tealAccent),
          label: 'Challenge',
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
      currentIndex: currentIndex,
      selectedItemColor: Colors.tealAccent,
      unselectedItemColor: Colors.white70,
      onTap: (index) => _onItemTapped(context, index),
    );
  }
}
