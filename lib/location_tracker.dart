import 'package:geolocator/geolocator.dart';

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

  // Stop tracking
  void stopTracking() {
    positionStream?.cancel();
    positionStream = null;
  }
}
