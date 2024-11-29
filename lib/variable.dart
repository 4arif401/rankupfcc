import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Global variables for user statistics
ValueNotifier<double> steps = ValueNotifier<double>(0.0);
ValueNotifier<double> activeTime = ValueNotifier<double>(0.0);
ValueNotifier<double> caloriesBurnt = ValueNotifier<double>(0.0);
ValueNotifier<double> distance = ValueNotifier<double>(0.0);

// Function to reset all variables
Future<void> resetVariables() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in, skipping reset.');
      return;
    }

    // Reset global variables locally
    steps.value = 0.0;
    activeTime.value = 0.0;
    caloriesBurnt.value = 0.0;

    // Reset data in Firebase
    await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
      'steps': 0.0,
      'activeTime': 0.0,
      'caloriesBurnt': 0.0,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    print('Variables and Firebase data reset successfully.');
  } catch (e) {
    if (e is FirebaseException && e.code == 'not-found') {
      // If the document does not exist, create it with reset data
      await _initializeUserData();
      print('User data initialized as the document did not exist.');
    } else {
      print('Error resetting variables: $e');
    }
  }
}

// Function to initialize a new user document in Firebase
Future<void> _initializeUserData() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
      'steps': 0.0,
      'activeTime': 0.0,
      'caloriesBurnt': 0.0,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    print('User data initialized in Firebase.');
  } catch (e) {
    print('Error initializing user data: $e');
  }
}
