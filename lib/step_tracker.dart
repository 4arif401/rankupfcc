import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'variable.dart';

double lastSavedSteps = 0.0; // Tracks the last saved steps from Firebase
double initialDeviceStepCount = 0.0; // Tracks the device's initial step count at app start

class StepTracker {
  Stream<StepCount>? _stepCountStream;

  // Initialize the step tracker
  void initStepTracker() async {
    initialDeviceStepCount = 0.0;
    await fetchFitnessData(); // Fetch the initial data from Firebase
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream?.listen(_onStepCount).onError(_onStepCountError);
  }

  // Handle step count updates
  void _onStepCount(StepCount event) async {
    try {
      double currentPedometerSteps = event.steps.toDouble();

      // First-time setup after app starts or reset
      if (initialDeviceStepCount == 0.0) {
        initialDeviceStepCount = currentPedometerSteps; // Align with device pedometer count
        return;
      }

      // Calculate new steps since last device step count update
      double newSteps = currentPedometerSteps - initialDeviceStepCount;

      // Ensure no negative steps
      if (newSteps < 0) {
        initialDeviceStepCount = currentPedometerSteps; // Reset initialDeviceStepCount
        return;
      }

      // Adjust steps to align with last saved steps in Firestore
      steps.value = lastSavedSteps + newSteps;

      // Update active time and calories burnt
      activeTime.value = steps.value / 100; // Example: 100 steps = 1 minute
      caloriesBurnt.value = steps.value * 0.04; // Example: 0.04 calories per step

      // Save the new values to Firebase periodically
      if (steps.value - lastSavedSteps >= 50) { // Save every 50 steps
        saveFitnessData();
        lastSavedSteps = steps.value; // Update last saved steps
        initialDeviceStepCount = currentPedometerSteps; // Reset initialDeviceStepCount
      }
    } catch (e) {
      print('Error updating step count: $e');
    }
  }

  // Handle errors in step tracking
  void _onStepCountError(dynamic error) {
    debugPrint("Step Count Error: $error");
  }
}

// Save fitness data to Firebase
Future<void> saveFitnessData() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
      'steps': steps.value,
      'activeTime': activeTime.value,
      'caloriesBurnt': caloriesBurnt.value,
      'initialDeviceStepCount': initialDeviceStepCount, // Save device step count
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    debugPrint('Fitness data saved successfully.');
  } catch (e) {
    debugPrint('Error saving fitness data: $e');
  }
}

// Fetch fitness data from Firebase and initialize variables
Future<void> fetchFitnessData() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();

    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      // Fetch the last saved steps from Firestore
      lastSavedSteps = (data['steps'] ?? 0).toDouble();

      // Set initialDeviceStepCount to align with the pedometer
      initialDeviceStepCount = (data['initialDeviceStepCount'] ?? 0).toDouble();

      // Update UI variables
      steps.value = lastSavedSteps;
      activeTime.value = (data['activeTime'] ?? 0).toDouble();
      caloriesBurnt.value = (data['caloriesBurnt'] ?? 0).toDouble();
    } else {
      resetVariables(); // Reset variables if no data exists
      saveFitnessData(); // Initialize data in Firebase
    }
  } catch (e) {
    print('Error fetching initial data: $e');
  }
}

// Check and reset data at midnight
Future<void> checkAndResetData() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('Users').doc(user.uid);
    final snapshot = await userDoc.get();

    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

      // Get last reset date
      DateTime lastResetDate = (data['lastResetDate'] as Timestamp).toDate();
      DateTime today = DateTime.now();

      // Check if the last reset was on a different day
      if (today.day != lastResetDate.day || today.month != lastResetDate.month || today.year != lastResetDate.year) {
        double currentPedometerSteps = await _getCurrentPedometerSteps(); // Fetch device's current step count

        // Reset data in Firebase
        await userDoc.set({
          'steps': 0,
          'activeTime': 0,
          'caloriesBurnt': 0,
          'initialDeviceStepCount': currentPedometerSteps, // Align with the current pedometer count
          'lastResetDate': Timestamp.now(),
        }, SetOptions(merge: true));

        // Reset global variables
        steps.value = 0.0;
        activeTime.value = 0.0;
        caloriesBurnt.value = 0.0;
        initialDeviceStepCount = currentPedometerSteps; // Align local variable with device pedometer
        lastSavedSteps = 0.0;

        print('Data reset for a new day.');
      }
    }
  } catch (e) {
    print('Error checking/resetting data: $e');
  }
}

// Helper to get the current pedometer step count
Future<double> _getCurrentPedometerSteps() async {
  try {
    StepCount? stepCount = await Pedometer.stepCountStream.first;
    return stepCount.steps.toDouble();
  } catch (e) {
    print('Error fetching pedometer step count: $e');
    return 0.0;
  }
}
