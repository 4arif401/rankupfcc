import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameScreen extends StatefulWidget {
  final String friendId;
  final int stepGoal;
  final int userStepsProgress;
  final int friendStepsProgress;

  const GameScreen({
    Key? key,
    required this.friendId,
    required this.stepGoal,
    required this.userStepsProgress,
    required this.friendStepsProgress,
  }) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double myStepsProgress = 0;
  double friendStepsProgress = 0;
  double stepGoal = 0;
  String myUsername = "You";
  String friendUsername = "Friend";

  late AnimationController _animationController;
  late Animation<double> _myPositionAnimation;
  late Animation<double> _friendPositionAnimation;


  @override
  void initState() {
    super.initState();

    // Initialize default step values
    myStepsProgress = 0;
    friendStepsProgress = 0;

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Initialize animations with default values
    _myPositionAnimation = Tween<double>(
      begin: 0.5,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _friendPositionAnimation = Tween<double>(
      begin: 0.5,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    // Fetch initial data
    _fetchStepProgress();

    // Listen for real-time updates
    _listenForStepUpdates();
  }

  void _fetchStepProgress() async {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Fetch user's `vsOngoing` data
    DocumentSnapshot userDoc =
        await _firestore.collection('Users').doc(userId).get();
    if (userDoc.exists) {
      final Map<String, dynamic>? userData =
          userDoc.data() as Map<String, dynamic>?; // Explicitly cast
      final userOngoing = userData?['vsOngoing'] as Map<String, dynamic>?; // Cast as Map
      if (userOngoing != null) {
        setState(() {
          myStepsProgress = (userOngoing['stepsProgress'] ?? 0).toDouble();
          stepGoal = (userOngoing['stepGoal'] ?? 1).toDouble(); // Avoid division by zero
          myUsername = userData?['username'] ?? "You";
        });
      }
    }

    // Fetch friend's `vsOngoing` data
    DocumentSnapshot friendDoc =
        await _firestore.collection('Users').doc(widget.friendId).get();
    if (friendDoc.exists) {
      final Map<String, dynamic>? friendData =
          friendDoc.data() as Map<String, dynamic>?; // Explicitly cast
      final friendOngoing =
          friendData?['vsOngoing'] as Map<String, dynamic>?; // Cast as Map
      if (friendOngoing != null) {
        setState(() {
          friendStepsProgress =
              (friendOngoing['stepsProgress'] ?? 0).toDouble();
          friendUsername = friendData?['username'] ?? "Friend";
        });
      }
    }
  
    _updatePositions();
  }

  void _checkChallengeCompletion(String winnerId, String loserId, double progress) async {
    if (progress >= stepGoal) {
      // Calculate exp
      int expGained = (stepGoal / 10).toInt();

      // Remove `vsOngoing` from both users
      await _firestore.collection('Users').doc(winnerId).update({
        'vsOngoing': FieldValue.delete(),
      });
      await _firestore.collection('Users').doc(loserId).update({
        'vsOngoing': FieldValue.delete(),
      });

      // Increment exp for the winner
      await _firestore.collection('Users').doc(winnerId).update({
        'exp': FieldValue.increment(expGained),
      });

      // Show dialog to the winner
      if (winnerId == _auth.currentUser?.uid) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("You win!"),
              content: Text(
                "You win the challenge against $friendUsername\n\n$expGained exp gained",
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.popUntil(context, ModalRoute.withName('/ChallengePage'));
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      }
    }
  }


  void _listenForStepUpdates() {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Listen for real-time updates for the current user
    _firestore.collection('Users').doc(userId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final userData = snapshot.data() as Map<String, dynamic>?;
        final userOngoing = userData?['vsOngoing'] as Map<String, dynamic>?;

        if (userOngoing != null && mounted) {
          setState(() {
            myStepsProgress = (userOngoing['stepsProgress'] ?? 0).toDouble();
            stepGoal = (userOngoing['stepGoal'] ?? 1).toDouble(); // Avoid division by zero
            myUsername = userData?['username'] ?? "You";

            _checkChallengeCompletion(userId, widget.friendId, myStepsProgress);
          });
          _updatePositions();
        }
      }
    });

    // Listen for real-time updates for the friend's `vsOngoing`
    _firestore.collection('Users').doc(widget.friendId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final friendData = snapshot.data() as Map<String, dynamic>?;
        final friendOngoing = friendData?['vsOngoing'] as Map<String, dynamic>?;

        if (friendOngoing != null && mounted) {
          setState(() {
            friendStepsProgress = (friendOngoing['stepsProgress'] ?? 0).toDouble();
            friendUsername = friendData?['username'] ?? "Friend";

            _checkChallengeCompletion(widget.friendId, userId, friendStepsProgress);
          });
          _updatePositions();
        }
      }
    });
  }



  void _updatePositions() {
    // Animate the positions based on progress towards the goal
    _myPositionAnimation = Tween<double>(
      begin: _myPositionAnimation.value,
      end: (myStepsProgress / stepGoal).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _friendPositionAnimation = Tween<double>(
      begin: _friendPositionAnimation.value,
      end: (friendStepsProgress / stepGoal).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the dynamic height of the page based on stepGoal
    double dynamicHeight = MediaQuery.of(context).size.height * 2; // Extend height for scrolling

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        title: Text('Ongoing VS Challenge', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Container(
              height: dynamicHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFa8e063), Color(0xFF56ab2f)], // Grass-like gradient
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Stack(
                    children: [
                      // Goal point marker
                      Positioned(
                        top: 50, // Always at the top with some padding
                        left: MediaQuery.of(context).size.width * 0.5 - 50,
                        child: GoalPoint(goalSteps: stepGoal),
                      ),

                      // Friend's character
                      Positioned(
                        top: (dynamicHeight - 100) *
                            (1 - _friendPositionAnimation.value), // Add padding for boundaries
                        left: MediaQuery.of(context).size.width * 0.2,
                        child: CharacterContainer(
                          color: Colors.redAccent,
                          label: friendUsername,
                          steps: friendStepsProgress,
                        ),
                      ),

                      // Current user's character
                      Positioned(
                        top: (dynamicHeight - 100) *
                            (1 - _myPositionAnimation.value), // Add padding for boundaries
                        right: MediaQuery.of(context).size.width * 0.2,
                        child: CharacterContainer(
                          color: Colors.blueAccent,
                          label: myUsername,
                          steps: myStepsProgress,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Vertical progress bar
          Positioned(
            top: 0,
            bottom: 0,
            right: 20,
            child: VerticalProgressBar(
              myProgress: myStepsProgress / stepGoal,
              friendProgress: friendStepsProgress / stepGoal,
              myUsername: myUsername,
              friendUsername: friendUsername,
            ),
          ),
        ],
      ),
    );
  }
}

class VerticalProgressBar extends StatelessWidget {
  final double myProgress;
  final double friendProgress;
  final String myUsername;
  final String friendUsername;

  const VerticalProgressBar({
    Key? key,
    required this.myProgress,
    required this.friendProgress,
    required this.myUsername,
    required this.friendUsername,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double progressBarHeight = MediaQuery.of(context).size.height * 0.8;

    return Container(
      width: 60,
      height: progressBarHeight,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          // My position marker
          Positioned(
            top: (1 - myProgress.clamp(0.0, 1.0)) * progressBarHeight,
            child: Marker(
              label: myUsername,
              color: Colors.blueAccent,
            ),
          ),

          // Friend position marker
          Positioned(
            top: (1 - friendProgress.clamp(0.0, 1.0)) * progressBarHeight,
            child: Marker(
              label: friendUsername,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class Marker extends StatelessWidget {
  final String label;
  final Color color;

  const Marker({Key? key, required this.label, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: color,
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class GoalPoint extends StatelessWidget {
  final double goalSteps;

  const GoalPoint({Key? key, required this.goalSteps}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.flag, size: 50, color: Colors.yellow),
        Text(
          'Goal: ${goalSteps.toInt()} steps',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class CharacterContainer extends StatelessWidget {
  final Color color;
  final String label;
  final double steps;

  const CharacterContainer({
    Key? key,
    required this.color,
    required this.label,
    required this.steps,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),
            Text(
              '${steps.toInt()} steps',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
