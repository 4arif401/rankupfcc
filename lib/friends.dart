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

  Future<void> _acceptFriendRequest(String requesterId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Add each other to friendsList
      await _firestore.collection('Users').doc(userId).update({
        'friendsList': FieldValue.arrayUnion([requesterId]),
        'upcomingFriend': FieldValue.arrayRemove([requesterId]),
      });

      await _firestore.collection('Users').doc(requesterId).update({
        'friendsList': FieldValue.arrayUnion([userId]),
        'requestedFriend': FieldValue.arrayRemove([userId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request accepted!')),
      );

      fetchFriends(); // Refresh the friends list
    } catch (e) {
      print('Error accepting friend request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept friend request.')),
      );
    }
  }

  Future<void> _declineFriendRequest(String requesterId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Remove the friend request
      await _firestore.collection('Users').doc(userId).update({
        'upcomingFriend': FieldValue.arrayRemove([requesterId]),
      });

      await _firestore.collection('Users').doc(requesterId).update({
        'requestedFriend': FieldValue.arrayRemove([userId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request declined.')),
      );
    } catch (e) {
      print('Error declining friend request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline friend request.')),
      );
    }
  }

  void _showAddFriendModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return AddFriendModal(onAddFriend: _addFriend);
      },
    );
  }

  void _showIncomingRequestsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return IncomingRequestsModal(
          onAccept: _acceptFriendRequest,
          onDecline: _declineFriendRequest,
        );
      },
    );
  }

  Future<void> _addFriend(String friendId) async {
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Update current user's `requestedFriend` field
      await _firestore.collection('Users').doc(userId).set({
        'requestedFriend': FieldValue.arrayUnion([friendId]),
      }, SetOptions(merge: true));

      // Update friend's `upcomingFriend` field
      await _firestore.collection('Users').doc(friendId).set({
        'upcomingFriend': FieldValue.arrayUnion([userId]),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent!')),
      );
    } catch (e) {
      print('Error sending friend request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send friend request.')),
      );
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "addFriend",
            onPressed: _showAddFriendModal,
            backgroundColor: Colors.tealAccent,
            child: Icon(Icons.person_add, color: Colors.black),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "incomingRequests",
            onPressed: _showIncomingRequestsModal,
            backgroundColor: Colors.redAccent,
            child: Icon(Icons.notifications, color: Colors.black),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 1),
    );
  }
}

class AddFriendModal extends StatefulWidget {
  final Function(String) onAddFriend;

  AddFriendModal({required this.onAddFriend});

  @override
  _AddFriendModalState createState() => _AddFriendModalState();
}

class _AddFriendModalState extends State<AddFriendModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isSearching = false;

  Future<void> _searchUsers() async {
    setState(() {
      isSearching = true;
    });

    String query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('username', isEqualTo: query)
          .get();

      setState(() {
        searchResults = snapshot.docs.map((doc) {
          return {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id, // Include the document ID
          };
        }).toList();
      });
    } catch (e) {
      print('Error searching users: $e');
    } finally {
      setState(() {
        isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search by username',
              prefixIcon: Icon(Icons.search),
              suffixIcon: IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    searchResults = [];
                  });
                },
              ),
            ),
            onChanged: (value) => _searchUsers(),
          ),
          SizedBox(height: 20),
          if (isSearching)
            Center(child: CircularProgressIndicator())
          else
            searchResults.isEmpty
                ? Text('No users found.', style: TextStyle(color: Colors.white))
                : Expanded(
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> user = searchResults[index];
                        return ListTile(
                          title: Text(user['username'] ?? 'Unknown'),
                          subtitle: Text(user['email'] ?? 'No Email'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              widget.onAddFriend(user['id']);
                              Navigator.pop(context); // Close modal
                            },
                            child: Text('Add'),
                          ),
                        );
                      },
                    ),
                  ),
        ],
      ),
    );
  }
}

class IncomingRequestsModal extends StatelessWidget {
  final Function(String) onAccept;
  final Function(String) onDecline;

  IncomingRequestsModal({required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7, // Set modal height to 70% of screen
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !(snapshot.data!.data() as Map<String, dynamic>).containsKey('upcomingFriend')) {
            return Center(
              child: Text(
                'No friend requests.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          List<dynamic> upcomingFriends = (snapshot.data!.data() as Map<String, dynamic>)['upcomingFriend'] ?? [];

          if (upcomingFriends.isEmpty) {
            return Center(
              child: Text(
                'No friend requests.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: upcomingFriends.length,
            itemBuilder: (context, index) {
              String friendId = upcomingFriends[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('Users').doc(friendId).get(),
                builder: (context, friendSnapshot) {
                  if (!friendSnapshot.hasData) {
                    return ListTile(
                      title: Text('Loading...', style: TextStyle(color: Colors.white)),
                    );
                  }

                  Map<String, dynamic> friendData = friendSnapshot.data!.data() as Map<String, dynamic>;

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0), // Add spacing between items
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.account_circle, size: 50, color: Colors.tealAccent),
                        SizedBox(width: 16.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friendData['username'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                friendData['email'] ?? 'No Email',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green, size: 28),
                              onPressed: () => onAccept(friendId),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red, size: 28),
                              onPressed: () => onDecline(friendId),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
