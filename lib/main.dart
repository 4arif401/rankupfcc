import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'challenge.dart'; // Import your ChallengePage

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Futuristic Fitness Challenge',
      theme: ThemeData(
        brightness: Brightness.dark, // Dark theme
        primarySwatch: Colors.blue,
      ),
      home: AuthenticationWrapper(), // Wrapper to decide the initial page
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Replace this with real authentication logic
    bool isLoggedIn = false; // Example flag, set it based on actual authentication status

    if (isLoggedIn) {
      return ChallengePage();
    } else {
      return LoginPage();
    }
  }
}

class LoginPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
                  'Login',
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
              SizedBox(height: 20), // Spacing between title and fields
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.tealAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.tealAccent),
                  ),
                  prefixIcon: Icon(Icons.email, color: Colors.tealAccent),
                ),
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20), // Spacing between fields
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.tealAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.tealAccent),
                  ),
                  prefixIcon: Icon(Icons.lock, color: Colors.tealAccent),
                ),
                obscureText: true,
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 30), // Spacing before login button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Implement login logic here
                    // For example, navigate to ChallengePage after successful login
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChallengePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent, // Button color
                    foregroundColor: Colors.black, // Text color
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
