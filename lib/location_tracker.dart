import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; 
import 'challenge.dart';

class LocationTracker {
  double totalDistance = 0.0; // Total distance in meters
  double lastLatitude = 0.0; // Last recorded latitude
  double lastLongitude = 0.0; // Last recorded longitude
  StreamSubscription<Position>? positionStream;

  // Initialize geolocation and request permission
  Future<void> initLocationTracker() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
  }

  // Start tracking distance
  void startTracking() {
    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Minimum distance (in meters) before receiving updates
      ),
    ).listen((Position position) {
      if (lastLatitude != 0.0 && lastLongitude != 0.0) {
        double distance = Geolocator.distanceBetween(
          lastLatitude,
          lastLongitude,
          position.latitude,
          position.longitude,
        );
        totalDistance += distance;
      }

      lastLatitude = position.latitude;
      lastLongitude = position.longitude;

      print('Total Distance: ${totalDistance / 1000} km'); // Distance in kilometers
    });
  }

  void startTrackingProgress(Map<String, dynamic>? acceptedChallenge, Function updateChallengeProgress) {
    if (acceptedChallenge == null) return; // Do nothing if no challenge is accepted

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Minimum distance in meters before updates
      ),
    ).listen((Position position) {
      if (lastLatitude != 0.0 && lastLongitude != 0.0) {
        double distance = Geolocator.distanceBetween(
          lastLatitude,
          lastLongitude,
          position.latitude,
          position.longitude,
        );
        totalDistance += distance;

        // Update progress only for the accepted challenge
        updateChallengeProgress();
      }

      lastLatitude = position.latitude;
      lastLongitude = position.longitude;
    });
  }

  // Stop tracking
  void stopTracking() {
    positionStream?.cancel();
    positionStream = null;
  }

  void saveDistanceToFirebase() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await FirebaseFirestore.instance.collection('Users').doc(user.uid).set({
    'totalDistance': totalDistance / 1000, // Save distance in kilometers
    'lastUpdated': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

}
