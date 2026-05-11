import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/screens/location/enter_address_bottom_sheet.dart';

class ConfirmLocationScreen extends StatefulWidget {
  const ConfirmLocationScreen({super.key});

  @override
  State<ConfirmLocationScreen> createState() => _ConfirmLocationScreenState();
}

class _ConfirmLocationScreenState extends State<ConfirmLocationScreen> {
  late GoogleMapController _mapController;
  LatLng _currentLatLng = const LatLng(28.6448, 77.2167); // Default to Delhi area
  String _locationName = "Jasmine Grove";
  String _fullAddress = "Jasmine Grove 959 , NH-9\n( Earlier, NH-24, near Columbia ...";
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    try {
      setState(() => _isSearching = true);
      List<Location> locations = await locationFromAddress(query);
      
      List<Map<String, dynamic>> results = [];
      for (var location in locations.take(5)) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          results.add({
            'name': p.name ?? p.subLocality ?? p.locality ?? query,
            'address': "${p.subLocality ?? ''} ${p.locality ?? ''} ${p.administrativeArea ?? ''}".trim(),
            'latLng': LatLng(location.latitude, location.longitude),
          });
        }
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      debugPrint("Search error: $e");
      setState(() => _isSearching = false);
    }
  }

  void _onSelectSearchResult(Map<String, dynamic> result) {
    final LatLng latLng = result['latLng'];
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: latLng, zoom: 18.0),
      ),
    );
    setState(() {
      _currentLatLng = latLng;
      _searchResults = [];
      _searchController.clear();
      _locationName = result['name'];
      _fullAddress = result['address'];
    });
  }

  static const String _darkMapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
    {"featureType": "road", "elementType": "geometry",
     "stylers": [{"color": "#304a7d"}]},
    {"featureType": "road", "elementType": "labels.text.fill",
     "stylers": [{"color": "#98a5be"}]},
    {"featureType": "water", "elementType": "geometry",
     "stylers": [{"color": "#0e1626"}]},
    {"featureType": "poi", "elementType": "geometry",
     "stylers": [{"color": "#283d6a"}]},
    {"featureType": "transit", "elementType": "geometry",
     "stylers": [{"color": "#2f3948"}]},
    {"featureType": "administrative.locality",
     "elementType": "labels.text.fill",
     "stylers": [{"color": "#c4d4e0"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _locationName = place.subLocality ?? place.locality ?? "Unknown";
          _fullAddress = "${place.street}, ${place.subLocality}, ${place.locality}";
        });
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng newLatLng = LatLng(position.latitude, position.longitude);
      
      _mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newLatLng, zoom: 18.0),
        ),
      );
      
      setState(() => _currentLatLng = newLatLng);
      await _getAddressFromLatLng(newLatLng);
    } catch (e) {
      debugPrint("Error getting current location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        
      ),
      body: Stack(
        children: [
          // Layer 1: Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLatLng,
              zoom: 15.5,
            ),
            mapType: MapType.normal,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _mapController.setMapStyle(_darkMapStyle);
            },
            onCameraMove: (CameraPosition position) {
              setState(() => _currentLatLng = position.target);
            },
            onCameraIdle: () {
              _getAddressFromLatLng(_currentLatLng);
            },
          ),

          // Layer 2: Search bar
          Positioned(
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
                    onChanged: (val) => _searchLocation(val),
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search for area, street name...",
                      hintStyle: GoogleFonts.poppins(color: const Color(0xFF757575), fontSize: 15),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF757575)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: _isSearching 
                        ? const SizedBox(width: 20, height: 20, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE53935))))
                        : null,
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF3A3A3A)),
                    ),
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(color: Color(0xFF3A3A3A), height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          onTap: () => _onSelectSearchResult(result),
                          leading: const Icon(Icons.location_on, color: Color(0xFFE53935), size: 20),
                          title: Text(result['name'], style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: Text(result['address'], style: GoogleFonts.poppins(color: const Color(0xFF9E9E9E), fontSize: 12)),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Layer 3: Center pin + tooltip
          Align(
            alignment: Alignment.center,
            child: FractionalTranslation(
              translation: const Offset(0, -0.5), // Moves the tip to the exact center
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tooltip card
                  
                  // Triangle pointer
                  CustomPaint(
                    painter: TrianglePointerPainter(),
                    size: const Size(20, 10),
                  ),
                  const SizedBox(height: 4),
                  // Red map pin icon
                  const Icon(Icons.location_on, color: Color(0xFFE53935), size: 48),
                ],
              ),
            ),
          ),

          // Layer 4: "Use current location" button
          Positioned(
            bottom: 210,
            left: 0,
            right: 0,
            child: Center(
              child: OutlinedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.gps_fixed, color: Color(0xFFE53935), size: 18),
                label: Text(
                  "Use current location",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFE53935),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  backgroundColor: const Color(0xFF1C1C1C).withOpacity(0.85),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ),

          // Layer 5: Bottom sheet panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [
                  BoxShadow(blurRadius: 12, color: Colors.black45, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFE53935), size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "CHANGE",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFFE53935),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: Text(
                      _fullAddress,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF9E9E9E),
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                            address: _fullAddress,
                            latitude: _currentLatLng.latitude,
                            longitude: _currentLatLng.longitude,
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePointerPainter extends CustomPainter {
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
  bool shouldRepaint(_) => false;
}
