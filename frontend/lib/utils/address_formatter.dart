import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_logger.dart';

class AddressFormatter {
  /// Reverse geocode coordinates and return a clean, formatted address
  /// Uses the same logic as MapScreen to filter out "Unnamed Road" etc.
  static Future<String> getCleanAddress(double lat, double lng) async {
    try {
      final Uri url = Uri.parse(
          'https://api.opencagedata.com/geocode/v1/json?q=$lat,$lng&key=9a08437326c04ca486e1566500a3bc0a&language=en');

      final http.Response response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final results = data['results'] as List<dynamic>;
          final firstResult = results[0] as Map<String, dynamic>;
          final comp = firstResult['components'] as Map<String, dynamic>;

          // Extract address components in priority order
          final placeName = (comp['building'] ??
              comp['shop'] ??
              comp['amenity'] ??
              comp['office'] ??
              comp['tourism'] ??
              comp['leisure'] ??
              '') as String;

          final houseNumber = (comp['house_number'] ?? '') as String;
          
          var road = (comp['road'] ??
              comp['residential'] ??
              comp['neighbourhood'] ??
              comp['suburb'] ??
              '') as String;
          
          final city = (comp['city'] ?? comp['town'] ?? comp['village'] ?? '') as String;
          final state = (comp['state'] ?? '') as String;
          final postcode = (comp['postcode'] ?? '') as String;
          final country = (comp['country'] ?? '') as String;

          // 🔥 Filter out "unnamed road" variants
          if (road.toLowerCase().contains('unnamed')) {
            road = '';
          }

          // Build clean address from non-empty components
          String cleanedAddress = [
            if (placeName.isNotEmpty) placeName,
            if (houseNumber.isNotEmpty) houseNumber,
            if (road.isNotEmpty) road,
            if (city.isNotEmpty) city,
            if (state.isNotEmpty) state,
            if (postcode.isNotEmpty) postcode,
            if (country.isNotEmpty) country,
          ].join(', ');

          // Fallback to formatted address if cleaned is empty
          if (cleanedAddress.trim().isEmpty) {
            cleanedAddress = (firstResult['formatted'] ?? '') as String;
          }

          return cleanedAddress;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.e('Address formatting error', e, stackTrace);
    }

    return ''; // Return empty string on error
  }
}
