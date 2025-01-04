import 'package:flutter/material.dart';
import 'dart:async'; // For Timer
import 'profile.dart';
import 'variable.dart'; // Import the global variables
import 'custom_bottom_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'step_tracker.dart';
import 'challenge1.dart';
import 'location_tracker.dart';

class ChallengePage extends StatefulWidget {
  @override
  _ChallengePageState createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  int _selectedIndex = 0;
  Timer? _countdownTimer;

  final double _totalSteps = 6000;
  final double _totalActiveTime = 90;
  final double _totalCaloriesBurnt = 400;

  Duration _timeLeft = Duration();

  Map<String, dynamic>? acceptedChallenge; // Store the single accepted challenge
  Map<String, dynamic>? challengeDetails; // Cache for challenge details
  Map<String, dynamic>? acceptedCoopChallenge;
  Map<String, dynamic>? coopChallengeDetails;


  final LocationTracker locationTracker = LocationTracker(); // Instantiate LocationTracker
  double initialDistance = 0.0; // Tracks the starting distance when a challenge is accepted

  @override
  void initState() {
    super.initState();
    _fetchAcceptedChallenge();
    _startCountdown();
    _syncDataWithFirebase();
    fetchFitnessData();
    checkAndResetData();
    // Listen to step changes to update progress
    steps.addListener(() {
      _updateChallengeProgress();
    });
  }

  /// Sync the local ValueNotifier data with Firebase whenever it changes.
  void _syncDataWithFirebase() {
    steps.addListener(() => saveFitnessData());
    activeTime.addListener(() => saveFitnessData());
    caloriesBurnt.addListener(() => saveFitnessData());
  }

  /// Countdown logic to reset variables at midnight
  void _startCountdown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        DateTime now = DateTime.now().toLocal(); // Get current time in device's local time zone
        setState(() {
          
          DateTime midnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0); // Calculate next midnight

          _timeLeft = midnight.difference(now); // Time left until midnight

          // Check if countdown has reached 0 or gone negative
          if (_timeLeft.isNegative || _timeLeft.inSeconds == 0) {
            resetVariables(); // Reset global variables
            saveFitnessData(); // Save data to Firestore
            timer.cancel(); // Stop the current timer
            _startCountdown(); // Restart the countdown for the next day
          }

          
        });

      } else {
        timer.cancel(); // Cancel the timer if the widget is no longer mounted
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  /// Format time left in HH:MM:SS
  String _formatTimeLeft(Duration duration) {
    return '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  /// Calculate progress for LinearProgressIndicator
  double _getProgress(double current, double total) {
    return (current / total).clamp(0.0, 1.0); // Ensure progress doesn't exceed 1.0
  }

  /// Fetch the accepted challenge and its details
  Future<void> _fetchAcceptedChallenge() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      setState(() {
        acceptedChallenge = data['acceptedChallenge'];
        acceptedCoopChallenge = data['acceptedChallenge2'];
      });

      // Fetch challenge details
      if (acceptedChallenge != null) {
        String id = acceptedChallenge!['id'];
        challengeDetails = await _fetchChallengeDetails(id);
      }

      if (acceptedCoopChallenge != null) {
        String coopId = acceptedCoopChallenge!['id'];
        coopChallengeDetails = await _fetchChallengeDetails(coopId);
      }
    }
  }

  Future<Map<String, dynamic>> _fetchChallengeDetails(String challengeId) async {
    DocumentSnapshot challengeSnapshot =
        await FirebaseFirestore.instance.collection('Challenges').doc(challengeId).get();
    return challengeSnapshot.exists ? challengeSnapshot.data() as Map<String, dynamic> : {};
  }


  /// Save accepted challenge to Firebase
  Future<void> _saveAcceptedChallenge() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
      'acceptedChallenge': acceptedChallenge,
    }, SetOptions(merge: true));
  }

  // Friend Selection Modal
  Future<String?> _selectFriend() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('Users').doc(userId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

            List<dynamic> friendsList = snapshot.data!['friendsList'] ?? [];

            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              padding: EdgeInsets.all(16.0),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchFriendsUsernames(friendsList),
                builder: (context, friendsSnapshot) {
                  if (!friendsSnapshot.hasData) return Center(child: CircularProgressIndicator());

                  final friendsData = friendsSnapshot.data!;
                  return ListView.builder(
                    itemCount: friendsData.length,
                    itemBuilder: (context, index) {
                      final friend = friendsData[index];
                      return ListTile(
                        leading: Icon(Icons.account_circle, color: Colors.tealAccent),
                        title: Text(
                          friend['username'] ?? 'Unknown',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(friend['email'] ?? 'No email'),
                        trailing: ElevatedButton(
                          onPressed: () => Navigator.pop(context, friend['id']),
                          child: Text('Select'),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // Fetch friend usernames
  Future<List<Map<String, dynamic>>> _fetchFriendsUsernames(List<dynamic> friendIds) async {
    List<Map<String, dynamic>> friendsData = [];

    for (String id in friendIds) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('Users').doc(id).get();
      if (snapshot.exists) {
        friendsData.add({
          'id': id,
          ...snapshot.data() as Map<String, dynamic>, // Add username, email, etc.
        });
      }
    }

    return friendsData;
  }


  // Save Co-op Challenge to Firestore
  Future<void> _saveCoopChallenge(String friendId, Map<String, dynamic> challenge) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Map<String, dynamic> coopChallenge = {
      'id': challenge['id'],
      'progress': 0.0,
      'friendid': friendId,
      'startStepsKm': stepsToKm(steps.value.toInt()), // Save current steps converted to km
    };

    // Save to current user's document
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .set({'acceptedChallenge2': coopChallenge}, SetOptions(merge: true));

    // Save to friend's document with user's ID as `friendid`
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(friendId)
        .set({
          'acceptedChallenge2': {
            'id': challenge['id'],
            'progress': 0.0,
            'friendid': user.uid,
          },
        }, SetOptions(merge: true));

    setState(() {
      acceptedCoopChallenge = coopChallenge;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Co-op challenge accepted with your friend!')),
    );
  }

  Future<void> _fetchAcceptedCoopChallenge() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
    if (snapshot.exists) {
      setState(() {
        acceptedCoopChallenge = snapshot['acceptedChallenge2'];
      });
    }
  }

  double stepsToKm(int steps) {
    return steps * 0.0008; // 1 step = 0.0008 km
  }

  /// Update progress for all accepted challenges
  void _updateChallengeProgress() {
    if (acceptedChallenge != null) {
      setState(() {
        double currentKm = stepsToKm(steps.value.toInt()); // Convert steps to km
        double startKm = acceptedChallenge!['startStepsKm'] ?? 0.0; // Use stored start steps converted to km
        acceptedChallenge!['progress'] = currentKm - startKm; // Calculate progress

        if (acceptedChallenge!['progress'] < 0) {
          acceptedChallenge!['progress'] = 0.0; // Ensure progress is not negative
        }
      });
      _saveAcceptedChallenge(); // Save updated progress to Firebase
    }

    if (acceptedCoopChallenge != null) {
      setState(() {
        double currentKm = stepsToKm(steps.value.toInt()); // Convert steps to km
        double startKm = acceptedCoopChallenge!['startStepsKm'] ?? 0.0; // Use stored start steps converted to km
        acceptedCoopChallenge!['progress'] = currentKm - startKm; // Calculate progress

        if (acceptedCoopChallenge!['progress'] < 0) {
          acceptedCoopChallenge!['progress'] = 0.0; // Ensure progress is not negative
        }
      });
      _saveAcceptedChallenge(); // Save updated co-op progress to Firebase
    }
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: screenWidth,
        padding: EdgeInsets.all(26.0),
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
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Challenge',
                  style: TextStyle(
                    fontSize: 24,
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
                Text(
                  _formatTimeLeft(_timeLeft),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                    shadows: [
                      Shadow(
                        blurRadius: 15.0,
                        color: Colors.redAccent.withOpacity(0.8),
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10), // Spacing between row and line
            Center(
              child: Container(
                width: screenWidth * 0.95,
                height: 2.0,
                color: Colors.tealAccent.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 20), // Spacing between line and list
            _buildListItem('1. Steps', steps, _totalSteps, screenWidth),
            SizedBox(height: 20), // Gap between items
            _buildListItem('2. Active Time', activeTime, _totalActiveTime, screenWidth),
            SizedBox(height: 20), // Gap between items
            _buildListItem('3. Calories burnt', caloriesBurnt, _totalCaloriesBurnt, screenWidth),
            SizedBox(height: 30), // Space below the Daily Challenge list

            // Accepted Challenge Title and Horizontal Line
            Text(
              'Solo Challenge',
              style: TextStyle(
                fontSize: 24,
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
            SizedBox(height: 10), // Spacing between title and line
            Center(
              child: Container(
                width: screenWidth * 0.95,
                height: 2.0,
                color: Colors.tealAccent.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 10),

            //Accepted Challenge
            acceptedChallenge == null
                ? GestureDetector(
                    onTap: () async {
                      final selectedChallenge = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Challenge1Page(),
                        ),
                      );

                      if (selectedChallenge != null) {
                        setState(() {
                          acceptedChallenge = {
                            'id': selectedChallenge['id'],
                            'progress': 0.0,
                            'startStepsKm': stepsToKm(steps.value.toInt()), // Save current steps converted to km
                          };
                          challengeDetails = selectedChallenge;
                        });
                        _saveAcceptedChallenge();
                      }
                    },
                    child: _buildGreyContainer(),
                  )
                : _buildChallengeDetailCard(),
            //_buildCoopChallengeSection(),
            SizedBox(height: 15),
            // Co-op Challenge Section
            Text(
              'Co-op Challenge',
              style: TextStyle(
                fontSize: 24,
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
            SizedBox(height: 10),
            Center(
              child: Container(
                width: screenWidth * 0.95,
                height: 2.0,
                color: Colors.tealAccent.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 10),

            acceptedCoopChallenge == null
                ? GestureDetector(
                    onTap: () async {
                      final selectedFriendId = await _selectFriend();
                      if (selectedFriendId != null) {
                        final selectedChallenge = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Challenge1Page()),
                        );

                        if (selectedChallenge != null) {
                          await _saveCoopChallenge(selectedFriendId, selectedChallenge);
                        }
                      }
                    },
                    child: _buildGreyContainer(),
                  )
                : _buildCoopChallengeDetailCard(),

          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 0),
    );
  }
  
  // Inside the ChallengePage Widget
  Widget _buildCoopChallengeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20), // Spacing
        Text(
          'Co-op Challenge',
          style: TextStyle(
            fontSize: 24,
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
        SizedBox(height: 10),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: 2.0,
            color: Colors.tealAccent.withOpacity(0.5),
          ),
        ),
        SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            final selectedFriendId = await _selectFriend(); // Show friend selection
            if (selectedFriendId != null) {
              final selectedChallenge = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Challenge1Page()),
              );

              if (selectedChallenge != null) {
                await _saveCoopChallenge(selectedFriendId, selectedChallenge);
              }
            }
          },
          child: _buildGreyContainer(),
        ),
      ],
    );
  }
  
  /// Build the container for the accepted challenge
  Widget _buildChallengeDetailCard() {
    double progress = acceptedChallenge!['progress'] as double;
    String title = challengeDetails?['title'] ?? 'Unknown Challenge';
    double requirement = challengeDetails?['requirement']?.toDouble() ?? 0.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade500, Colors.teal.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 10),
          Text(
            'Progress: ${progress.toStringAsFixed(2)} / ${requirement.toStringAsFixed(2)} km',
            style: TextStyle(fontSize: 16, color: Colors.tealAccent),
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress / requirement,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildCoopChallengeDetailCard() {
    double progress = acceptedCoopChallenge!['progress'] as double;
    String title = coopChallengeDetails?['title'] ?? 'Unknown Challenge';
    double requirement = coopChallengeDetails?['requirement']?.toDouble() ?? 0.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade500, Colors.blueGrey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 10),
          Text(
            'Progress: ${progress.toStringAsFixed(2)} / ${requirement.toStringAsFixed(2)} km',
            style: TextStyle(fontSize: 16, color: Colors.tealAccent),
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress / requirement,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
          ),
        ],
      ),
    );
  }

  
  /// Build list item with ValueNotifier support
  Widget _buildListItem(String title, ValueNotifier<double> valueNotifier, double maxValue, double screenWidth) {
    return ValueListenableBuilder<double>(
      valueListenable: valueNotifier,
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${value.toInt()} / ${maxValue.toInt()}',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.tealAccent,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 8.0,
                        color: Colors.tealAccent.withOpacity(0.7),
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            LinearProgressIndicator(
              value: _getProgress(value, maxValue),
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
              minHeight: 8.0,
            ),
          ],
        );
      },
    );
  }

  // Helper method to create a grey container with a "+" icon
  /// Build the grey container with "+" icon for selecting a challenge
  Widget _buildGreyContainer() {
    return Container(
      height: 100.0,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Center(
        child: Icon(
          Icons.add,
          size: 50.0,
          color: Colors.tealAccent,
        ),
      ),
    );
  }
}

