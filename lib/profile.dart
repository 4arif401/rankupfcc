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
  int level = 1;
  int exp = 0;
  List<String> completedChallengeIds = []; // List to store IDs of completed challenges
  Map<String, dynamic> challengeDetails = {}; // Cache for challenge details

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

        // Fetch user data from Firestore
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('Users') // Ensure this matches your Firestore collection name
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            username = userDoc['username'] ?? "No username"; // Fetch 'username' field
            level = userDoc['level'] ?? 1; // Fetch 'level' field
            exp = userDoc['exp'] ?? 0; // Fetch 'exp' field
            completedChallengeIds = List<String>.from(userDoc['completedChallenge'] ?? []);
          });

          // Fetch details for completed challenges
          await _fetchCompletedChallengesDetails();
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

  Future<void> _fetchCompletedChallengesDetails() async {
    try {
      Map<String, dynamic> fetchedDetails = {};
      for (String challengeId in completedChallengeIds) {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('Challenges').doc(challengeId).get();
        if (snapshot.exists) {
          fetchedDetails[challengeId] = snapshot.data();
        }
      }
      setState(() {
        challengeDetails = fetchedDetails;
      });
    } catch (e) {
      print("Error fetching completed challenge details: $e");
    }
  }

  void _showCompletedChallengesModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Transparent for custom styling
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6, // 60% height
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Color(0xFF2C2C2E), // Dark gray background (not pitch black)
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, -3), // Shadow towards the top
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Text(
                  'Completed Challenges',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent.shade200,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Divider(color: Colors.tealAccent.withOpacity(0.3), thickness: 1),
              SizedBox(height: 10),

              // List of completed challenges
              Expanded(
                child: ListView.builder(
                  itemCount: challengeDetails.length,
                  itemBuilder: (context, index) {
                    final challenge = challengeDetails.values.elementAt(index);
                    return Container(
                      margin: EdgeInsets.only(bottom: 12.0),
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Color(0xFF3A3A3C), // Slightly lighter dark gray for cards
                        borderRadius: BorderRadius.circular(15.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 2), // Shadow below the card
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Icon(Icons.emoji_events, color: Colors.tealAccent, size: 40),
                          SizedBox(width: 12),
                          // Challenge Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  challenge['title'] ?? 'Untitled Challenge',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.tealAccent.shade100,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  challenge['description'] ?? 'No description available.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
            // User Info Section
            Container(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                children: [
                  Icon(Icons.account_circle, color: Colors.tealAccent, size: 50),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            username,
                            style: TextStyle(fontSize: 20, color: Colors.white70),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Lvl $level',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.tealAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

            // Experience Progress Bar
            Text(
              'Experience Points',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$exp / 1000',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                if (exp >= 1000)
                  ElevatedButton(
                    onPressed: () async {
                      // Level up logic
                      setState(() {
                        level += 1;
                        exp -= 1000;
                      });
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
                          'level': level,
                          'exp': exp,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('Level Up'),
                  ),
              ],
            ),
            LinearProgressIndicator(
              value: (exp / 1000).clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
              minHeight: 8.0,
            ),
            Divider(color: Colors.tealAccent.withOpacity(0.5)),
            SizedBox(height: 20),

            // Completed Challenges Section
            ListTile(
              onTap: _showCompletedChallengesModal, // Open completed challenges modal
              leading: Icon(Icons.check_circle, color: Colors.tealAccent, size: 40),
              title: Text(
                'Total Challenges Completed',
                style: TextStyle(fontSize: 20, color: Colors.white70),
              ),
              subtitle: Text(
                '${completedChallengeIds.length} completed',
                style: TextStyle(fontSize: 16, color: Colors.white54),
              ),
            ),
            Divider(color: Colors.tealAccent.withOpacity(0.5)),
            Spacer(),

            // Logout Button
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
