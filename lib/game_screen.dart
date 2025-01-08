import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameScreen extends StatefulWidget {
  final String friendId; // Pass friend's user ID to this page

  const GameScreen({Key? key, required this.friendId}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double mySteps = 0;
  double friendSteps = 0;
  String myUsername = "You";
  String friendUsername = "Friend";

  late AnimationController _animationController;
  late Animation<double> _myPositionAnimation;
  late Animation<double> _friendPositionAnimation;

  final double goalSteps = 25000; // Set a goal point for the race

  @override
  void initState() {
    super.initState();

    // Initialize default step values
    mySteps = 0;
    friendSteps = 0;

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

    // Listen for real-time updates
    _listenForStepUpdates();
  }

  void _listenForStepUpdates() {
    final String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // Listen for real-time updates for the current user and friend
    _firestore.collection('Users').doc(userId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          mySteps = (snapshot.data()?['steps'] ?? 0).toDouble();
          myUsername = snapshot.data()?['username'] ?? "You";
          _updatePositions();
        });
      }
    });

    _firestore.collection('Users').doc(widget.friendId).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          friendSteps = (snapshot.data()?['steps'] ?? 0).toDouble();
          friendUsername = snapshot.data()?['username'] ?? "Friend";
          _updatePositions();
        });
      }
    });
  }

  void _updatePositions() {
    // Animate the positions based on progress towards the goal
    _myPositionAnimation = Tween<double>(
      begin: _myPositionAnimation.value,
      end: (mySteps / goalSteps).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _friendPositionAnimation = Tween<double>(
      begin: _friendPositionAnimation.value,
      end: (friendSteps / goalSteps).clamp(0.0, 1.0),
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
    // Calculate the dynamic height of the page based on goalSteps
    double dynamicHeight = MediaQuery.of(context).size.height * 2; // Extend height for scrolling

    return Scaffold(
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
                        child: GoalPoint(goalSteps: goalSteps),
                      ),

                      // Friend's character
                      Positioned(
                        top: (dynamicHeight - 100) *
                            (1 - _friendPositionAnimation.value), // Add padding for boundaries
                        left: MediaQuery.of(context).size.width * 0.2,
                        child: CharacterContainer(
                          color: Colors.redAccent,
                          label: friendUsername,
                          steps: friendSteps,
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
                          steps: mySteps,
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
              myProgress: mySteps / goalSteps,
              friendProgress: friendSteps / goalSteps,
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
