import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Global variables for user statistics
ValueNotifier<double> steps = ValueNotifier<double>(0.0);
ValueNotifier<double> activeTime = ValueNotifier<double>(0.0);
ValueNotifier<double> caloriesBurnt = ValueNotifier<double>(0.0);

// Function to reset all variables
void resetVariables() {
  steps.value = 0.0; // Reset step count
  activeTime.value = 0.0; // Reset active time
  caloriesBurnt.value = 0.0; // Reset calories burnt
}

// Save fitness data to Firestore
Future<void> saveFitnessData() async {
  try {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user == null) return; // Ensure user is logged in

    // Save data only if steps, activeTime, and caloriesBurnt are non-zero
    if (steps.value > 0 || activeTime.value > 0 || caloriesBurnt.value > 0) {
      await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
        'steps': steps.value,
        'activeTime': activeTime.value,
        'caloriesBurnt': caloriesBurnt.value,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge updates with existing data
    }
  } catch (e) {
    print('Error saving fitness data: $e');
  }
}

// Retrieve fitness data from Firestore
Future<void> fetchFitnessData() async {
  try {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user == null) return; // Ensure user is logged in

    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();

    if (snapshot.exists) {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      steps.value = (data['steps'] ?? 0).toDouble();
      activeTime.value = (data['activeTime'] ?? 0).toDouble();
      caloriesBurnt.value = (data['caloriesBurnt'] ?? 0).toDouble();
    } else {
      // Initialize values in Firebase if the document does not exist
      resetVariables();
      saveFitnessData();
    }
  } catch (e) {
    print('Error fetching fitness data: $e');
  }
}

