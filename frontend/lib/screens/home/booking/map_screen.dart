import 'dart:async';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../config/app_colors.dart';
import '../../../widgets/primary_button.dart';

class MapScreen extends StatefulWidget {
  final String? selectedService;
  
  const MapScreen({super.key, this.selectedService});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  LatLng _center = LatLng(19.0760, 72.8777); // Default Mumbai
  final String openCageKey = dotenv.env['OPENCAGE_API_KEY'] ?? "";

  String _selectedAddress = "";
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _getCurrentLocation();
  }

  /// 📍 Most Accurate GPS Fetch
  Future<Position?> _getPreciseLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permissions are permanently denied. Please search manually or enable them in settings."),
            backgroundColor: AppColors.dangerRed,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return null;
    }

    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: const Duration(seconds: 8),
      );

      if (pos.accuracy > 25) {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );
      }
      return pos;
    } catch (e) {
      debugPrint("GPS Error: $e");
      return null;
    }
  }

  Future<void> _getCurrentLocation() async {
    final pos = await _getPreciseLocation();
    if (pos == null) return;

    final newCenter = LatLng(pos.latitude, pos.longitude);
    setState(() => _center = newCenter);
    _mapController.move(newCenter, 17.5);
    _reverseGeocode(newCenter);
  }

  /// 🔍 Search by text
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);

    final url =
        'https://api.opencagedata.com/geocode/v1/json?q=$query&key=$openCageKey';

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data['results'] != null && data['results'].isNotEmpty) {
        final double lat = double.tryParse(data['results'][0]['geometry']['lat'].toString()) ?? 0.0;
        final double lng = double.tryParse(data['results'][0]['geometry']['lng'].toString()) ?? 0.0;
        final newCenter = LatLng(lat, lng);

        _mapController.move(newCenter, 16);
        setState(() => _center = newCenter);

        _reverseGeocode(newCenter);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location not found")),
        );
      }
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  /// 📡 Triggered when map moves
  void _onMapMoved(MapEvent event) {
    setState(() => _center = _mapController.camera.center);

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _reverseGeocode(_center);
    });
  }

  /// 🌟 SMART Reverse Geocode – Extracts landmarks, building, hospital, shop names
  Future<void> _reverseGeocode(LatLng position) async {
    final url =
        'https://api.opencagedata.com/geocode/v1/json?q=${position.latitude}+${position.longitude}&key=$openCageKey';

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["results"] != null && data["results"].isNotEmpty) {
        final comp = data["results"][0]["components"];

        String placeName = (comp["point_of_interest"] ??
            comp["hospital"] ??
            comp["clinic"] ??
            comp["building"] ??
            comp["amenity"] ??
            comp["shop"] ??
            comp["office"] ??
            comp["tourism"] ??
            comp["leisure"] ??
            "").toString();

        String houseNumber = (comp["house_number"] ?? "").toString();
        String road = (comp["road"] ??
            comp["residential"] ??
            comp["neighbourhood"] ??
            comp["suburb"] ??
            "").toString();
        String city = (comp["city"] ?? comp["town"] ?? comp["village"] ?? "").toString();
        String state = (comp["state"] ?? "").toString();
        String postcode = (comp["postcode"] ?? "").toString();
        String country = (comp["country"] ?? "").toString();

        if (road.toLowerCase().contains("unnamed")) road = "";

        String cleanedAddress = [
          if (placeName.isNotEmpty) placeName,
          if (houseNumber.isNotEmpty) houseNumber,
          if (road.isNotEmpty) road,
          if (city.isNotEmpty) city,
          if (state.isNotEmpty) state,
          if (postcode.isNotEmpty) postcode,
          if (country.isNotEmpty) country,
        ].join(", ");

        if (cleanedAddress.trim().isEmpty) {
          cleanedAddress = (data["results"][0]["formatted"] ?? "").toString();
        }

        setState(() {
          _selectedAddress = cleanedAddress;
          addressController.text = cleanedAddress;
        });
      }
    } catch (e) {
      debugPrint("Reverse geocode error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16,
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() => _center = position.center);
                }
              },
              onMapEvent: _onMapMoved,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.convenz.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 50,
                    height: 50,
                    alignment: Alignment.topCenter,
                    child: Transform.translate(
                      offset: const Offset(0, -10),
                      child: const Icon(
                        Icons.location_pin,
                        size: 50,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          /// 🔍 Search Bar
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: _buildSearchBar(),
          ),

          /// 📡 GPS Button
          Positioned(
            bottom: 310,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: AppColors.primaryTeal),
              onPressed: _getCurrentLocation,
            ),
          ),

          /// 📄 Address Confirmation Panel
          _buildBottomAddressPanel(),
        ],
      ),
    );
  }

  /// 📍 UI Extracted — unchanged
  Widget _buildSearchBar() => Row(
    children: [
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColors.primaryTeal.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryTeal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: AppColors.primaryTeal.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))
            ],
          ),
    child: TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: _searchLocation,
      decoration: InputDecoration(
        hintText: "Search city, area...",
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        suffixIcon: IconButton(
          icon: _isSearching
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.search, color: AppColors.primaryTeal),
          onPressed: () => _searchLocation(_searchController.text),
        ),
      ),
    ),
        ),
      ),
    ],
  );

  Widget _buildBottomAddressPanel() => Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 55),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: AppColors.primaryTeal.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text("Confirm Location",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal)),
            const SizedBox(height: 8),
            TextField(
              controller: addressController,
              maxLines: 2,
              onChanged: (value) => _selectedAddress = value,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.primaryTeal.withOpacity(0.04),
                hintText: "Fetching address...",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                text: "Confirm Location",
                onPressed: () {
                  if (_selectedAddress.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please wait for address to load")),
                    );
                    return;
                  }
                  context.push(
                    '/serviceDetails',
                    extra: {
                      'address': _selectedAddress,
                      'selectedService': widget.selectedService,
                      'latitude': _center.latitude,
                      'longitude': _center.longitude,
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
