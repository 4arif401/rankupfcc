import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rankupfcc/variable.dart';

class Challenge1Page extends StatefulWidget {
  @override
  _Challenge1PageState createState() => _Challenge1PageState();
}

class _Challenge1PageState extends State<Challenge1Page> {
  List<String> completedChallenges = []; // To store the completed challenge IDs

  @override
  void initState() {
    super.initState();
    _fetchCompletedChallenges();
  }

  // Fetch completed challenges for the current user
  Future<void> _fetchCompletedChallenges() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(loggedInUserId).get();

      if (userDoc.exists) {
        List<dynamic>? completed = userDoc['completedChallenge']; // Get the array
        setState(() {
          completedChallenges = completed?.map((e) => e.toString()).toList() ?? []; // Default to an empty list
        });
      } else {
        setState(() {
          completedChallenges = []; // User document doesn't exist, initialize as empty
        });
      }
    } catch (e) {
      print('Error fetching completed challenges: $e');
      setState(() {
        completedChallenges = []; // On error, treat it as no completed challenges
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchChallenges() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('Challenges').get();

      return snapshot.docs
          .where((doc) => !completedChallenges.contains(doc.id)) // Filter out completed challenges
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id, // Include the document ID
              })
          .toList();
    } catch (e) {
      print('Error fetching challenges: $e');
      return []; // Return an empty list on error
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Available Challenges',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchChallenges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || completedChallenges.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No challenges available.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          final challenges = snapshot.data!;
          return ListView.builder(
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context, challenge); // Pass selected challenge back
                },
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  elevation: 5,
                  shadowColor: Colors.tealAccent.withOpacity(0.3),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade500, Colors.teal.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        CircleAvatar(
                          backgroundColor: Colors.tealAccent,
                          radius: 30,
                          child: Icon(
                            Icons.directions_run,
                            color: Colors.black87,
                            size: 30,
                          ),
                        ),
                        SizedBox(width: 16.0),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge['title'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                challenge['description'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Requirement
                                  Text(
                                    'Goal: ${challenge['requirement']} km',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.tealAccent,
                                    ),
                                  ),
                                  // Reward
                                  Text(
                                    'Reward: ${challenge['reward']} EXP',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.tealAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
