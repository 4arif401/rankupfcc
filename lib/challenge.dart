import 'package:flutter/material.dart';
import 'dart:async'; // For Timer
import 'profile.dart';

class ChallengePage extends StatefulWidget {
  @override
  _ChallengePageState createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  int _selectedIndex = 0;
  Timer? _countdownTimer; // Timer variable

  // These are the manually set values for steps, active time, and calories burnt.
  double _currentSteps = 9000.0; // (value) steps out of 6000
  double _currentActiveTime = 45.0; // (value) minutes of active time out of 90
  double _currentCaloriesBurnt = 300.0; // (value) kcal burnt out of 400

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
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          DateTime now = DateTime.now();
          DateTime midnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 0);
          _timeLeft = midnight.difference(now);
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
            _buildListItem('1. Steps', '${_currentSteps.toInt()}/6000', _currentSteps, _totalSteps, screenWidth),
            SizedBox(height: 20), // Gap between items
            _buildListItem('2. Active Time', '${_currentActiveTime.toInt()}/90 min', _currentActiveTime, _totalActiveTime, screenWidth),
            SizedBox(height: 20), // Gap between items
            _buildListItem('3. Calories burnt', '${_currentCaloriesBurnt.toInt()}/400 kcal', _currentCaloriesBurnt, _totalCaloriesBurnt, screenWidth),
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black87,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center, color: Colors.tealAccent),
            label: 'Challenge',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.tealAccent),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.white70,
        onTap: _onItemTapped,
      ),
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
