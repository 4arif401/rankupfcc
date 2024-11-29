import 'package:flutter/material.dart';
import 'dart:async'; // For Timer
import 'profile.dart';
import 'variable.dart'; // Import the global variables
import 'custom_bottom_navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'step_tracker.dart';
import 'challenge1.dart';

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

  List<Map<String, dynamic>> acceptedChallenges = []; // List of maps to store challenge IDs and progress
  Map<String, Map<String, dynamic>> challengesDetails = {}; // Cache for challenge details

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _syncDataWithFirebase();
    fetchFitnessData();
    checkAndResetData();
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

  /// Fetch accepted challenges and their details
  Future<void> _fetchAcceptedChallenges() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      List<Map<String, dynamic>> challenges = List<Map<String, dynamic>>.from(data['acceptedChallenges'] ?? []);
      setState(() {
        acceptedChallenges = challenges;
      });

      // Fetch challenge details for accepted challenges
      for (var challenge in challenges) {
        String id = challenge['id'];
        if (!challengesDetails.containsKey(id)) {
          DocumentSnapshot challengeSnapshot = await FirebaseFirestore.instance.collection('Challenges').doc(id).get();
          if (challengeSnapshot.exists) {
            setState(() {
              challengesDetails[id] = challengeSnapshot.data() as Map<String, dynamic>;
            });
          }
        }
      }
    }
  }

  /// Save accepted challenges to Firebase
  Future<void> _saveAcceptedChallenges() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
      'acceptedChallenges': acceptedChallenges,
    }, SetOptions(merge: true));
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
            SizedBox(height: 50),
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
              'Accepted Challenge',
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
            SizedBox(height: 20), // Spacing between line and list

            // Accepted Challenges
            Expanded(
              child: ListView.builder(
                itemCount: 3, // Display 3 slots
                itemBuilder: (context, index) {
                  if (index < acceptedChallenges.length) {
                    var challenge = acceptedChallenges[index];
                    String id = challenge['id'];
                    double progress = challenge['progress'];
                    Map<String, dynamic>? details = challengesDetails[id];

                    return Container(
                      margin: EdgeInsets.only(bottom: 20.0),
                      height: 80.0,
                      decoration: BoxDecoration(
                        color: Colors.tealAccent,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Center(
                        child: details != null
                            ? Text(
                                '${details['title']} - ${progress.toStringAsFixed(2)} / ${details['requirement']} km',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : CircularProgressIndicator(),
                      ),
                    );
                  } else {
                    return GestureDetector(
                      onTap: () async {
                        final selectedChallenge = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Challenge1Page(),
                          ),
                        );

                        if (selectedChallenge != null) {
                          setState(() {
                            acceptedChallenges.add({
                              'id': selectedChallenge['id'],
                              'progress': 0.0,
                            });
                            challengesDetails[selectedChallenge['id']] = selectedChallenge;
                          });
                          _saveAcceptedChallenges();
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 20.0),
                        height: 80.0,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add,
                            size: 40.0,
                            color: Colors.tealAccent,
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 0),
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
  Widget _buildGreyContainer() {
    return Container(
      height: 80.0, // Set the height of the container
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Center(
        child: Icon(
          Icons.add,
          size: 40.0,
          color: Colors.tealAccent,
        ),
      ),
    );
  }
}
