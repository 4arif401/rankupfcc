import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'custom_bottom_navigation.dart';

class FriendsPage extends StatefulWidget {
  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> friendsData = []; // List to store friends' data
  bool isLoading = true; // To show a loading indicator

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> fetchFriends() async {
    try {
      // Get current user's UID
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Fetch current user's document
      DocumentSnapshot userDoc =
          await _firestore.collection('Users').doc(userId).get();

      // Get friendsList from user document (Array of IDs)
      List<dynamic> friendsList = userDoc['friendsList'] ?? [];

      // Fetch each friend's data
      List<Map<String, dynamic>> fetchedFriends = [];
      for (String friendId in friendsList) {
        DocumentSnapshot friendDoc =
            await _firestore.collection('Users').doc(friendId).get();
        if (friendDoc.exists) {
          fetchedFriends.add(friendDoc.data() as Map<String, dynamic>);
        }
      }

      // Update state with friends' data
      setState(() {
        friendsData = fetchedFriends;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching friends: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B1B1B), Color.fromARGB(228, 31, 78, 90), Color(0xFF3D5363)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 50), // Gap from the top
            Text(
              'Friends',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.tealAccent,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.tealAccent.withOpacity(0.7),
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
            Divider(
              color: Colors.tealAccent.withOpacity(0.5),
              thickness: 2.0,
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : friendsData.isEmpty
                      ? Center(
                          child: Text(
                            'No Friends Found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                        )
                      : ListView.separated(
                          itemCount: friendsData.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.tealAccent.withOpacity(0.5),
                            thickness: 1.0,
                            height: 12, // Adjusted to control gap between items
                          ),
                          itemBuilder: (context, index) {
                            Map<String, dynamic> friend = friendsData[index];
                            return Container(
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.account_circle, color: Colors.tealAccent, size: 50),
                                  SizedBox(width: 16.0),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        friend['username'] ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        friend['email'] ?? 'No Email',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
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
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 1),
    );
  }
}
