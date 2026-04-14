import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/auth_service.dart';
import '../services/location_services.dart';
import '../services/profile_service.dart';
import '../utils/shared_prefs.dart';

class UserProvider with ChangeNotifier {
  String _currentAddress = 'Loading address...';
  String get currentAddress => _currentAddress;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> response = await ProfileService.getProfile();
      if (response['success'] == true) {
        final userData = (response['data'] ?? response['user']) as Map<String, dynamic>?;
        if (userData != null) {
          final dbAddress = (userData['address'] ?? (userData['location'] as Map<String, dynamic>?)?['address'] ?? 'Location not set') as String;
          if (dbAddress.isNotEmpty) {
            _currentAddress = dbAddress;
          } else {
            _currentAddress = 'Location not set';
          }
        } else {
          _currentAddress = 'Location not set';
        }
      } else {
        _currentAddress = 'Address not found';
      }
    } catch (e) {
      _currentAddress = 'Error loading address';
    }

    // Force UI refresh after failure or success
    if (_currentAddress == 'Loading address...') {
      _currentAddress = 'Location not determined';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> syncLocation() async {
    try {
      final String? userId = SharedPrefs.getUserId();
      if (userId == null) {
        _currentAddress = 'User not logged in';
        notifyListeners();
        return;
      }

      final Position? pos = await LocationService.determinePosition();
      if (pos != null) {
        final Map<String, dynamic> response = await AuthService.updateUserLocation(
          userId,
          pos.latitude,
          pos.longitude,
        );

        if (response['success'] == true && response['location'] != null) {
          final location = response['location'] as Map<String, dynamic>;
          final newAddress = (location['address'] ?? '') as String;
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
