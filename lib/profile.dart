import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Firestore
import 'challenge.dart';
import 'main.dart'; // Import for LoginPage
import 'custom_bottom_navigation.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 1;

  // Variables to store user data
  String username = "Loading...";
  String email = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Fetch user email from Auth
        setState(() {
          email = user.email ?? "No email";
        });

        // Fetch username from Firestore
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users') // Ensure this matches your Firestore collection name
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            username = userDoc['username'] ?? "No username"; // Fetch 'username' field
          });
        } else {
          setState(() {
            username = "No username found";
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        username = "Error loading username";
        email = "Error loading email";
      });
    }
  }

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
                        username,
                        style: TextStyle(fontSize: 20, color: Colors.white70),
                      ),
                      Text(
                        email,
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
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 2),
    );
  }
}
