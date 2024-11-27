import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'variable.dart'; // Import the global variables
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StepTracker {
  Stream<StepCount>? _stepCountStream;

  // Initialize the step counter
  void initStepTracker() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream?.listen(_onStepCount).onError(_onStepCountError);
  }

  // Update global variables when a step is detected
  void _onStepCount(StepCount event) {
    steps.value += event.steps.toDouble(); // Increment steps
    caloriesBurnt.value = steps.value * 0.04; // Example: 0.04 calories per step
    activeTime.value = steps.value / 100; // Example: 100 steps = 1 minute of activity

    // Save to Firebase
    saveFitnessData(); // Save updated data to Firebase
  }

  // Handle errors in step tracking
  void _onStepCountError(dynamic error) {
    debugPrint("Step Count Error: $error");
  }
}
