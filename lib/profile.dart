import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'challenge.dart';
import 'main.dart'; // Import for LoginPage

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (index == 0) {
      // Navigate back to Challenge Page when Challenge is selected
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChallengePage()),
      );
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut(); // Log out from Firebase
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 60.0, 16.0, 16.0), // Added top padding for a gap
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                children: [
                  Icon(Icons.account_circle, color: Colors.tealAccent, size: 40),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Username',
                        style: TextStyle(fontSize: 20, color: Colors.white70),
                      ),
                      Text(
                        'user@example.com',
                        style: TextStyle(fontSize: 16, color: Colors.white54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: Colors.tealAccent.withOpacity(0.5)),
            SizedBox(height: 10),
            Text(
              'My Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
              ),
            ),
            ListTile(
              leading: Icon(Icons.fitness_center, color: Colors.tealAccent, size: 40),
              title: Text(
                'Total Workouts Completed',
                style: TextStyle(fontSize: 20, color: Colors.white70),
              ),
              subtitle: Text(
                '50 completed',
                style: TextStyle(fontSize: 16, color: Colors.white54),
              ),
            ),
            Divider(color: Colors.tealAccent.withOpacity(0.5)),
            ListTile(
              leading: Icon(Icons.stars, color: Colors.tealAccent, size: 40),
              title: Text(
                'Achievements',
                style: TextStyle(fontSize: 20, color: Colors.white70),
              ),
              subtitle: Text(
                '5 badges earned',
                style: TextStyle(fontSize: 16, color: Colors.white54),
              ),
            ),
            Divider(color: Colors.tealAccent.withOpacity(0.5)),
            Spacer(),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black87,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center, color: Colors.tealAccent),
            label: 'Challenge',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.tealAccent),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
      ),
    );
  }
}
