import 'package:flutter/material.dart';
import 'challenge.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (index == 0) {
      // Navigate back to Challenge Page when Challenge is selected
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChallengePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: Container(
          width: screenWidth * 0.85, // 85% of screen width
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black87, Colors.black54],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.3),
                blurRadius: 10.0,
                spreadRadius: 5.0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 28,
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
              SizedBox(height: 20), // Spacing between title and content
              ListTile(
                leading: Icon(Icons.account_circle, color: Colors.tealAccent, size: 40),
                title: Text(
                  'Username',
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                ),
                subtitle: Text(
                  'user@example.com',
                  style: TextStyle(fontSize: 16, color: Colors.white54),
                ),
              ),
              Divider(color: Colors.tealAccent.withOpacity(0.5)),
              ListTile(
                leading: Icon(Icons.fitness_center, color: Colors.tealAccent, size: 40),
                title: Text(
                  'Total Workouts',
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                ),
                subtitle: Text(
                  '50 completed',
                  style: TextStyle(fontSize: 16, color: Colors.white54),
                ),
              ),
              Divider(color: Colors.tealAccent.withOpacity(0.5)),
              ListTile(
                leading: Icon(Icons.stars, color: Colors.tealAccent, size: 40),
                title: Text(
                  'Achievements',
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                ),
                subtitle: Text(
                  '5 badges earned',
                  style: TextStyle(fontSize: 16, color: Colors.white54),
                ),
              ),
            ],
          ),
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
}
