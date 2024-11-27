import 'package:flutter/material.dart';
import 'dart:async'; // For Timer
import 'profile.dart';
import 'variable.dart'; // Import the global variables
import 'custom_bottom_navigation.dart';

class ChallengePage extends StatefulWidget {
  @override
  _ChallengePageState createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  int _selectedIndex = 0;
  Timer? _countdownTimer; // Timer variable

  final double _totalSteps = 6000;
  final double _totalActiveTime = 90;
  final double _totalCaloriesBurnt = 400;

  Duration _timeLeft = Duration();

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          DateTime now = DateTime.now();

          // Adjust for GMT+8
          DateTime gmtPlus8Now = now.toUtc().add(Duration(hours: 8));

          // Calculate next midnight in GMT+8
          DateTime midnight = DateTime(gmtPlus8Now.year, gmtPlus8Now.month, gmtPlus8Now.day + 1, 0, 0, 0);

          _timeLeft = midnight.difference(gmtPlus8Now);
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

  String _formatTimeLeft(Duration duration) {
    return '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  double _getProgress(double current, double total) {
    return (current / total).clamp(0.0, 1.0); // Ensure progress doesn't go above 1.0
  }

  double _getOverflowProgress(double current, double total) {
    return (current > total ? (current - total) / total : 0).clamp(0.0, 1.0).toDouble(); // Ensure result is a double
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // Navigate to Profile Page when Profile is selected
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
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
                width: screenWidth * 0.95, // 85% of the screen width
                height: 2.0,
                color: Colors.tealAccent.withOpacity(0.5), // Glowing line
              ),
            ),
            SizedBox(height: 20), // Spacing between line and list
            _buildListItem('1. Steps', '${steps.toInt()}/6000', steps, _totalSteps, screenWidth),
            SizedBox(height: 20), // Gap between items
            _buildListItem('2. Active Time', '${activeTime.toInt()}/90 min', activeTime, _totalActiveTime, screenWidth),
            SizedBox(height: 20), // Gap between items
            _buildListItem('3. Calories burnt', '${caloriesBurnt.toInt()}/400 kcal', caloriesBurnt, _totalCaloriesBurnt, screenWidth),
            SizedBox(height: 27), // Space below the last challenge item
            Center(
              child: Text(
                'Reward: Sample Reward', // Reward text
                style: TextStyle(
                  fontSize: 20,
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildListItem(String title, String value, double currentValue, double maxValue, double screenWidth) {
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
              value,
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
        SizedBox(height: 10), // Spacing between text and progress bar
        Stack(
          children: [
            LinearProgressIndicator(
              value: _getProgress(currentValue, maxValue),
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
              minHeight: 8.0,
            ),
            LinearProgressIndicator(
              value: _getOverflowProgress(currentValue, maxValue),
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
              minHeight: 8.0,
            ),
          ],
        ),
      ],
    );
  }
}
