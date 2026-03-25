import 'dart:convert';
import 'package:http/http.dart' as http;

class AddressFormatter {
  /// Reverse geocode coordinates and return a clean, formatted address
  /// Uses the same logic as MapScreen to filter out "Unnamed Road" etc.
  static Future<String> getCleanAddress(double lat, double lng) async {
    try {
      final url = Uri.parse(
          "https://api.opencagedata.com/geocode/v1/json?q=$lat,$lng&key=9a08437326c04ca486e1566500a3bc0a&language=en");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["results"] != null && data["results"].isNotEmpty) {
          final comp = data["results"][0]["components"];

          // Extract address components in priority order
          String placeName = comp["building"] ??
              comp["shop"] ??
              comp["amenity"] ??
              comp["office"] ??
              comp["tourism"] ??
              comp["leisure"] ??
              "";

          String houseNumber = comp["house_number"] ?? "";
          
          String road = comp["road"] ??
              comp["residential"] ??
              comp["neighbourhood"] ??
              comp["suburb"] ??
              "";
          
          String city = comp["city"] ?? comp["town"] ?? comp["village"] ?? "";
          String state = comp["state"] ?? "";
          String postcode = comp["postcode"] ?? "";
          String country = comp["country"] ?? "";

          // 🔥 Filter out "unnamed road" variants
          if (road.toLowerCase().contains("unnamed")) {
            road = "";
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
          ].join(", ");

          // Fallback to formatted address if cleaned is empty
          if (cleanedAddress.trim().isEmpty) {
            cleanedAddress = data["results"][0]["formatted"] ?? "";
          }

          return cleanedAddress;
        }
      }
    } catch (e) {
      print("❌ Address formatting error: $e");
    }

    return ""; // Return empty string on error
  }
}
