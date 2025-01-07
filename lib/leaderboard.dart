import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'custom_bottom_navigation.dart';

class LeaderboardPage extends StatefulWidget {
  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  List<Map<String, dynamic>> users = [];
  String currentUserId = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      // Fetch current user ID
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          currentUserId = user.uid;
        });
      }

      // Fetch users from Firestore and sort by level
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .orderBy('level', descending: true)
          .get();

      setState(() {
        users = snapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'username': data['username'] ?? 'Unknown',
            'level': data['level'] ?? 0,
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching leaderboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B1B1B), Color(0xFF3D5363)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Title at the top
            Center(
              child: Text(
                "Leaderboard",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.tealAccent,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.tealAccent.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.0),

            // Leaderboard list
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isCurrentUser = user['id'] == currentUserId;

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 5.0),
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? Colors.teal.withOpacity(0.3)
                          : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(10.0),
                      border: isCurrentUser
                          ? Border.all(color: Colors.tealAccent, width: 2.0)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Text(
                          "${index + 1}.",
                          style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10.0),
                        Expanded(
                          child: Text(
                            user['username'],
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        Text(
                          "Level ${user['level']}",
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.tealAccent,
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
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 1), // Set Leaderboard as active tab
    );
  }
}
