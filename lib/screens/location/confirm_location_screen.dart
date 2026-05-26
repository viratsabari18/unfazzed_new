import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:zeerah/screens/location/enter_address_bottom_sheet.dart';
import 'package:zeerah/screens/location/map_view_widget.dart';


class ConfirmLocationScreen extends StatefulWidget {
  const ConfirmLocationScreen({super.key});

  @override
  State<ConfirmLocationScreen> createState() => _ConfirmLocationScreenState();
}

class _ConfirmLocationScreenState extends State<ConfirmLocationScreen> {
  // Keys and Controllers
  final GlobalKey<MapViewWidgetState> _mapWidgetKey = GlobalKey<MapViewWidgetState>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  GoogleMapController? _mapController;

  // Location Data
  LatLng _currentLocation = const LatLng(28.6139, 77.2090); // Default: Delhi
  LatLng? _lastFetchedLocation;
  String _selectedAddressType = "Home";

  // UI State
  bool _isFetchingAddress = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  // Value Notifiers for UI updates
  final ValueNotifier<String> _locationNameNotifier = ValueNotifier("Getting your location...");
  final ValueNotifier<String> _fullAddressNotifier = ValueNotifier("");
  bool _isInitialized = false;

  // Dark Map Style
  static const String _darkMapStyle = '''
    [{
      "elementType": "geometry",
      "stylers": [{"color": "#1d2c4d"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#8ec3b9"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#1a3646"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#304a7d"}]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#98a5be"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#0e1626"}]
    },
    {
      "featureType": "poi",
      "elementType": "geometry",
      "stylers": [{"color": "#283d6a"}]
    },
    {
      "featureType": "transit",
      "elementType": "geometry",
      "stylers": [{"color": "#2f3948"}]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#c4d4e0"}]
    }]
  ''';

  @override
  void initState() {
    super.initState();
    _setupSystemUI();
    _initializeLocation();
  }



@override
void didChangeDependencies() {
  super.didChangeDependencies();

  if (!_isInitialized) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null && args is String) {
      _selectedAddressType = args;
    }

    _isInitialized = true;
  }
}
  void _setupSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _initializeLocation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  // ==================== LOCATION METHODS ====================

  Future<void> _getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      // Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng newLocation = LatLng(position.latitude, position.longitude);

      // Animate map to location
      await _mapWidgetKey.currentState?.animateTo(newLocation);
      _currentLocation = newLocation;

      // Get address
      await _getAddressFromCoordinates(newLocation);

      // Update location name
      _locationNameNotifier.value = "Your Location";
    } catch (e) {
      debugPrint("Error getting location: $e");
      _locationNameNotifier.value = "Location unavailable";
    }
  }

  Future<void> _getAddressFromCoordinates(LatLng location) async {
    if (_isFetchingAddress) return;

    // Check if we recently fetched this location
    if (_lastFetchedLocation != null) {
      final distance = Geolocator.distanceBetween(
        _lastFetchedLocation!.latitude,
        _lastFetchedLocation!.longitude,
        location.latitude,
        location.longitude,
      );
      if (distance < 20) return; // Skip if less than 20 meters
    }

    _isFetchingAddress = true;
    _lastFetchedLocation = location;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;

        // Get area name
        final areaName = place.subLocality?.isNotEmpty == true
            ? place.subLocality
            : place.locality;

        // Build full address
        final addressParts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
        ];
        final fullAddress = addressParts
            .where((e) => e != null && e.toString().isNotEmpty)
            .join(", ");

        _locationNameNotifier.value = areaName ?? "Selected Location";
        _fullAddressNotifier.value = fullAddress.isNotEmpty ? fullAddress : "Address not available";
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
      if (mounted) {
        _fullAddressNotifier.value = "Unable to fetch address";
      }
    } finally {
      _isFetchingAddress = false;
    }
  }

  // ==================== SEARCH METHODS ====================

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      List<Location> locations = await locationFromAddress(query);
      List<Map<String, dynamic>> results = [];

      for (var location in locations.take(5)) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final name = p.name ?? p.subLocality ?? p.locality ?? query;
          final address = [
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((e) => e != null && e.isNotEmpty).join(", ");

          results.add({
            'name': name,
            'address': address,
            'latLng': LatLng(location.latitude, location.longitude),
          });
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _onSelectSearchResult(Map<String, dynamic> result) async {
    final LatLng selectedLocation = result['latLng'];

    // Animate map to selected location
    await _mapWidgetKey.currentState?.animateTo(selectedLocation);
    _currentLocation = selectedLocation;

    // Get address for selected location
    await _getAddressFromCoordinates(selectedLocation);

    // Clear search
    if (mounted) {
      setState(() {
        _searchResults = [];
        _searchController.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  // ==================== UI BUILD METHODS ====================

  Widget _buildSearchBar() {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3A3A3A)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  _searchLocation(value);
                });
              },
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: "Search for area, street name...",
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF757575),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF757575)),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_searchResults.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3A3A3A)),
              ),
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                separatorBuilder: (context, __) => const Divider(
                  color: Color(0xFF3A3A3A),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    onTap: () => _onSelectSearchResult(result),
                    leading: const Icon(
                      Icons.location_on,
                      color: Color(0xFFE53935),
                      size: 20,
                    ),
                    title: Text(
                      result['name'],
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      result['address'],
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF9E9E9E),
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCenterPin() {
    return Align(
      alignment: Alignment.center,
      child: AbsorbPointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(
              painter: _TrianglePointerPainter(),
              size: const Size(20, 10),
            ),
            const SizedBox(height: 4),
            const Icon(
              Icons.location_on,
              color: Color(0xFFE53935),
              size: 48,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black45,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: Color(0xFFE53935),
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _locationNameNotifier,
                    builder: (context, value, __) => Text(
                      value,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _getCurrentLocation,
                  child: Text(
                    "CHANGE",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFE53935),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: ValueListenableBuilder<String>(
                valueListenable: _fullAddressNotifier,
                builder: (context, value, __) => Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF9E9E9E),
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => EnterAddressBottomSheet(
                      address: _fullAddressNotifier.value,
                      latitude: _currentLocation.latitude,
                      longitude: _currentLocation.longitude,
                      addressType: _selectedAddressType,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Add more address details",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Google Map
            MapViewWidget(
              key: _mapWidgetKey,
              initialLocation: _currentLocation,
              onMapCreated: (controller) async {
                _mapController = controller;
                await _mapWidgetKey.currentState?.setMapStyle(_darkMapStyle);
              },
              onCameraMove: (position) {
                _currentLocation = position.target;
              },
              onCameraIdle: () async {
                await _getAddressFromCoordinates(_currentLocation);
              },
            ),
            // Search Bar
            _buildSearchBar(),
            // Center Pin
            _buildCenterPin(),
            // GPS Button
            Positioned(
              bottom: 210,
              left: 0,
              right: 0,
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(
                    Icons.gps_fixed,
                    color: Color(0xFFE53935),
                    size: 18,
                  ),
                  label: Text(
                    "Use current location",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFE53935),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFE53935),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    backgroundColor: const Color(0xFF1C1C1C).withOpacity(0.85),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            // Bottom Panel
            _buildBottomPanel(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _locationNameNotifier.dispose();
    _fullAddressNotifier.dispose();
    super.dispose();
  }
}

// Custom painter for triangle pointer
class _TrianglePointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}