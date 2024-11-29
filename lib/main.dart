import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'challenge.dart'; // Import ChallengePage
import 'register.dart'; // Import RegisterPage
import 'variable.dart'; // Import global variables for steps, activeTime, and caloriesBurnt
import 'step_tracker.dart'; // Import StepTracker for step tracking
import 'location_tracker.dart'; // Import LocationTracker for distance tracking

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(); // Initialize Firebase
    StepTracker stepTracker = StepTracker(); // Instantiate StepTracker
    stepTracker.initStepTracker(); // Initialize step tracking
    runApp(MyApp());
  } catch (e) {
    print("Error during app initialization: $e");
    runApp(ErrorApp()); // Optional: Show an error page if initialization fails
  }
}

class ErrorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Error initializing app. Please try again later.'),
        ),
      ),
    );
  }
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

// Auto-login wrapper for Firebase Authentication
class AuthenticationWrapper extends StatefulWidget {
  @override
  _AuthenticationWrapperState createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  final LocationTracker locationTracker = LocationTracker();
  double currentDistance = 0.0; // Distance in kilometers

  @override
  void initState() {
    super.initState();
    fetchFitnessData(); // Load data from Firestore
    checkAndResetData(); // Check for reset at midnight

    // Initialize location tracking
    locationTracker.initLocationTracker().then((_) {
      locationTracker.startTracking();
    }).catchError((e) {
      print('Error initializing location tracker: $e');
    });
  }

  @override
  void dispose() {
    locationTracker.stopTracking(); // Stop location tracking
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

    if (isLoggedIn) {
      return StreamBuilder(
        stream: Stream.periodic(Duration(seconds: 1)), // Periodic updates
        builder: (context, snapshot) {
          currentDistance = locationTracker.totalDistance / 1000; // Convert meters to km
          return ChallengePage();
        },
      );
    } else {
      return LoginPage();
    }
  }
}

class LoginPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChallengePage()),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Login Failed'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B1B1B), Color(0xFF1F4E5A), Color(0xFF3D5363)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'RANK-UP FITNESS',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.tealAccent,
                      shadows: [
                        Shadow(
                          blurRadius: 15.0,
                          color: Colors.tealAccent.withOpacity(0.7),
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'FITNESS COMMUNITY PLATFORM',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.tealAccent.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(height: 80),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.tealAccent),
                      filled: true,
                      fillColor: Colors.black45,
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
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.tealAccent),
                      filled: true,
                      fillColor: Colors.black45,
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
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => _login(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent,
                      foregroundColor: Colors.black,
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
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterPage()),
                      );
                    },
                    child: Text(
                      'Don\'t have an account? Register here',
                      style: TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
