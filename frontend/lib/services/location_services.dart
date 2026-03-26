import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../utils/shared_prefs.dart';
import 'auth_service.dart';

class LocationService {
  static StreamSubscription<Position>? _positionStreamSubscription;

  static Future<Position?> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // ✅ UPDATED: Tracking logic with User ID check
  static void startLocationTracking() {
    stopLocationTracking();

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 500, // Update every 500 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position currentPosition) async {

      // 1. Get User ID from storage
      String? userId = SharedPrefs.getUserId();
      if (userId == null) {
        print("❌ Tracking Skipped: User ID not found.");
        return;
      }

      final lastLoc = SharedPrefs.getLastSyncedLocation();

      if (lastLoc == null) {
        print("🚀 First Location Sync...");
        _syncLocationToServer(userId, currentPosition);
      } else {
        double distanceInMeters = Geolocator.distanceBetween(
          lastLoc['lat']!, lastLoc['lng']!,
          currentPosition.latitude, currentPosition.longitude,
        );

        print("📏 Moved: ${distanceInMeters.toStringAsFixed(1)}m");

        if (distanceInMeters > 2000) { // 2km threshold
          print("🚀 Moved > 2km. Updating DB...");
          _syncLocationToServer(userId, currentPosition);
        }
      }
    });
  }

  static void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  static Future<void> _syncLocationToServer(String userId, Position position) async {
    try {
      final response = await AuthService.updateUserLocation(
          userId, position.latitude, position.longitude
      );

      if (response['success'] == true) {
        await SharedPrefs.saveLastSyncedLocation(position.latitude, position.longitude);
        print("✅ Location Updated in DB for User $userId");
      } else {
        print("❌ API Error: ${response['message']}");
      }
    } catch (e) {
      print("❌ Sync Error: $e");
    }
  }
}