import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/location_services.dart';
import '../utils/shared_prefs.dart';

class UserProvider with ChangeNotifier {
  String _currentAddress = "Loading address...";
  String get currentAddress => _currentAddress;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ProfileService.getProfile();
      if (response['success'] == true) {
        final userData = response['data'] ?? response['user'];
        if (userData != null) {
          String dbAddress = userData['address'] ?? userData['location']?['address'] ?? "Location not set";
          if (dbAddress.isNotEmpty) {
            _currentAddress = dbAddress;
          }
        }
      }
    } catch (e) {
      _currentAddress = "Error loading address";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> syncLocation() async {
    try {
      String? userId = SharedPrefs.getUserId();
      if (userId == null) {
        _currentAddress = "User not logged in";
        notifyListeners();
        return;
      }

      Position? pos = await LocationService.determinePosition();
      if (pos != null) {
        final response = await AuthService.updateUserLocation(
          userId,
          pos.latitude,
          pos.longitude,
        );

        if (response['success'] == true && response['location'] != null) {
          String newAddress = response['location']['address'] ?? "";
          if (newAddress.isNotEmpty) {
            _currentAddress = newAddress;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      // Keep cached address on error
    }
  }
}
