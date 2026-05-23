import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeerah/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/models/service_list_model.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class ProfessionalAssignedScreen extends StatefulWidget {
  final dynamic service;
  final BookingStatusModel bookingStatus;
  final dynamic bookingData;
  final LatLng? initialUserLocation;
  final LatLng? initialRiderLocation;
  final String? price;

  const ProfessionalAssignedScreen({
    required this.service,
    required this.bookingStatus,
    this.bookingData,
    this.initialUserLocation,
    this.initialRiderLocation,
    this.price,
    super.key,
  });

  @override
  State<ProfessionalAssignedScreen> createState() =>
      _ProfessionalAssignedScreenState();
}

class _ProfessionalAssignedScreenState
    extends State<ProfessionalAssignedScreen> {
  late GoogleMapController mapController;
  Timer? _movementTimer;
  LatLng _userLocation = const LatLng(28.6139, 77.2090); // Default Delhi
  LatLng _currentRiderPos = const LatLng(28.6155, 77.2150);
  late int _remainingMins;
  late BookingState _simulatedState;
  BitmapDescriptor? _carIcon;
  List<LatLng> _routePoints = [];
  LatLng? _lastPolylineFetchPosition;
  int _currentStep = 0;
  bool _isLoadingLocation = true;
  bool _isWaitingForBackendArrival = false;
  String _backendStatus = "On the Way";
  dynamic _currentBookingData;
  String? _bookingId;

  final Map<String, double> _dummyRatingsCache = {};
  @override
  void initState() {
    super.initState();
    _currentBookingData = widget.bookingData;

    // Use passed locations if available for instant update
    if (widget.initialUserLocation != null) {
      _userLocation = widget.initialUserLocation!;
      _isLoadingLocation = false;
    }

    if (widget.initialRiderLocation != null) {
      _currentRiderPos = widget.initialRiderLocation!;
    } else {
      _currentRiderPos = const LatLng(28.6155, 77.2150); // Fallback
    }

    _remainingMins = 12;
    _simulatedState = widget.bookingStatus.currentState;
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    _loadCustomIcons();

    // Check if we can do real-time tracking
    if (widget.bookingData != null) {
      final bData = widget.bookingData is List
          ? (widget.bookingData as List).first
          : widget.bookingData;
      _bookingId =
          bData['booking_detail']?['id']?.toString() ?? bData['id']?.toString();
    }

    _setBookingLocation();
    if (_bookingId != null) {
      _startRealTimeTracking(_bookingId!);
      _fetchAndRedirect(); // CRITICAL: Start polling status
    } else {
      _generateRoadSnappedRoute();
      _startMovementSimulation();
    }
  }

  void _setBookingLocation() {
    try {
      final bData = widget.bookingData is List
          ? (widget.bookingData as List).first
          : widget.bookingData;

      final bookingDetail = bData['booking_detail'];

      final lat = double.tryParse(bookingDetail?['latitude']?.toString() ?? '');

      final lng = double.tryParse(
        bookingDetail?['longitude']?.toString() ?? '',
      );

      if (lat != null && lng != null) {
        _userLocation = LatLng(lat, lng);

        debugPrint("BOOKING LOCATION => $lat , $lng");
      }
    } catch (e) {
      debugPrint("Booking location error: $e");
    }
  }

  Map<String, dynamic> getChatTarget() {
    final bData = widget.bookingData is List
        ? (widget.bookingData as List).first
        : widget.bookingData;

    // =====================================================
    // PROVIDER
    // =====================================================

    final rawProvider = bData?['provider_data'];

    final provider = rawProvider is List
        ? (rawProvider.isNotEmpty ? rawProvider.first : {})
        : (rawProvider ?? {});

    // =====================================================
    // HANDYMAN
    // =====================================================

    final rawHandyman = bData?['handyman_data'];

    final handyman = rawHandyman is List
        ? (rawHandyman.isNotEmpty ? rawHandyman.first : {})
        : (rawHandyman ?? {});

    debugPrint("========== RAW DATA ==========");

    debugPrint("HANDYMAN => $handyman");

    debugPrint("PROVIDER => $provider");

    debugPrint("==============================");

    final handymanUserType = handyman['user_type']
        ?.toString()
        .toLowerCase()
        .trim();

    final isRealHandyman =
        handyman.isNotEmpty &&
        handyman['id'] != null &&
        handymanUserType != null &&
        handymanUserType == 'handyman';

    // =====================================================
    // REAL HANDYMAN
    // =====================================================

    if (isRealHandyman) {
      final handymanId = handyman['id'].toString();

      return {
        'uid': 'handyman_$handymanId',

        'name': handyman['display_name'] ?? handyman['name'] ?? 'Handyman',

        'image': handyman['profile_image'] ?? '',

        'isHandyman': true,
      };
    }

    // =====================================================
    // PROVIDER SELF ASSIGNED
    // =====================================================

    if (provider.isNotEmpty && provider['id'] != null) {
      final providerId = provider['id'].toString();

      return {
        'uid': 'provider_$providerId',

        'name':
            provider['company_name'] ?? provider['display_name'] ?? 'Provider',

        'image': provider['profile_image'] ?? '',

        'isHandyman': false,
      };
    }

    // =====================================================
    // FALLBACK
    // =====================================================

    return {
      'uid': 'unknown',

      'name': 'Professional',

      'image': '',

      'isHandyman': false,
    };
  }

  double _getRatingWithFallback(dynamic handyman, dynamic provider) {
    final rating =
        (handyman?['handyman_rating'] ??
        provider?['providers_service_rating'] ??
        provider?['handyman_rating'] ??
        0);

    if (rating != 0) {
      return rating.toDouble();
    }

    // Generate a unique ID for this professional
    final id =
        handyman?['id']?.toString() ??
        handyman?['uid']?.toString() ??
        provider?['id']?.toString() ??
        provider?['uid']?.toString() ??
        'default';

    // Get cached rating or generate new one
    return _dummyRatingsCache.putIfAbsent(
      id,
      () => 4.2 + (4.9 - 4.2) * Random().nextDouble(),
    );
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLoadingLocation = false);
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        // _userLocation = LatLng(position.latitude, position.longitude);
        if (_bookingId == null) {
          _generateRoadSnappedRoute();
        }
        _isLoadingLocation = false;
      });
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation, 15),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _generateRoadSnappedRoute() {
    // 1. Defining major road grid turns
    final List<LatLng> majorPoints = [
      LatLng(
        _userLocation.latitude + 0.005,
        _userLocation.longitude + 0.005,
      ), // Start far
      LatLng(
        _userLocation.latitude + 0.005,
        _userLocation.longitude + 0.002,
      ), // First Turn
      LatLng(
        _userLocation.latitude + 0.002,
        _userLocation.longitude + 0.002,
      ), // Second Turn
      LatLng(
        _userLocation.latitude + 0.001,
        _userLocation.longitude + 0.001,
      ), // Near Turn
      _userLocation, // Home
    ];

    // 2. Interpolate hundreds of small points between major turns for smoothness
    final List<LatLng> smoothPoints = [];
    for (int i = 0; i < majorPoints.length - 1; i++) {
      final start = majorPoints[i];
      final end = majorPoints[i + 1];
      const int stepsPerSegment = 50;

      for (int s = 0; s <= stepsPerSegment; s++) {
        final lat =
            start.latitude +
            (end.latitude - start.latitude) * (s / stepsPerSegment);
        final lng =
            start.longitude +
            (end.longitude - start.longitude) * (s / stepsPerSegment);
        smoothPoints.add(LatLng(lat, lng));
      }
    }

    _routePoints = smoothPoints;
    _currentRiderPos = _routePoints[0];
    _currentStep = 0;
  }

  Future<void> _getRoadPolyline(LatLng start, LatLng end) async {
    try {
      PolylinePoints polylinePoints = PolylinePoints();

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: "AIzaSyAW3nH7YUQnZVx09h1wB9fBbwE6CpT8iRE",

        request: PolylineRequest(
          origin: PointLatLng(start.latitude, start.longitude),
          destination: PointLatLng(end.latitude, end.longitude),
          mode: TravelMode.driving,
        ),
      );

      debugPrint("Polyline points => ${result.points.length}");

      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];

        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        if (mounted) {
          setState(() {
            _routePoints.clear();
            _routePoints.addAll(polylineCoordinates);
          });
        }
      }
    } catch (e) {
      debugPrint("Road polyline error => $e");
    }
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<void> _loadCustomIcons() async {
    try {
      final Uint8List markerIcon = await _getBytesFromAsset(
        'lib/assets/images/rider_car.png',
        130,
      );

      debugPrint("Rider icon loaded successfully");

      if (mounted) {
        setState(() {
          _carIcon = BitmapDescriptor.fromBytes(markerIcon);
        });
      }
    } catch (e) {
      debugPrint("Rider icon loading failed: $e");

      if (mounted) {
        setState(() {
          _carIcon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          );
        });
      }
    }
  }

  void _startRealTimeTracking(String bookingId) {
    _movementTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      // Faster updates (3s)
      if (mounted && !_isWaitingForBackendArrival) {
        _fetchRiderLocation(bookingId);
      }
    });

    // Initial fetch
    _fetchRiderLocation(bookingId);
  }

  Future<void> _fetchRiderLocation(String bookingId) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.apiToken;
      final url = Uri.parse(
        '${ApiConfig.apiBaseUrl}/get-location?booking_id=$bookingId',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final locData = result['data'];
        if (locData != null) {
          final lat = double.tryParse(locData['latitude'].toString());
          final lng = double.tryParse(locData['longitude'].toString());

          if (lat != null && lng != null) {
            final newPos = LatLng(lat, lng);

            // Calculate distance to user
            double distance = Geolocator.distanceBetween(
              lat,
              lng,
              _userLocation.latitude,
              _userLocation.longitude,
            );

            if (mounted) {
              setState(() {
                _currentRiderPos = newPos;

                // User request: 1km = 3 minutes
                double distanceInKm = distance / 1000;
                _remainingMins = (distanceInKm * 3).toInt().clamp(1, 999);

                // Update simulated state based on distance (less than 100m = arrived/started)
                if (distance < 100) {
                  _simulatedState = BookingState.started;
                  _movementTimer?.cancel();
                  _fetchAndRedirect(); // Status reached arrived
                } else {
                  _simulatedState = BookingState.onTheWay;
                }
              });
              bool shouldRefreshRoute = false;

              if (_lastPolylineFetchPosition == null) {
                shouldRefreshRoute = true;
              } else {
                double movedDistance = Geolocator.distanceBetween(
                  _lastPolylineFetchPosition!.latitude,
                  _lastPolylineFetchPosition!.longitude,
                  newPos.latitude,
                  newPos.longitude,
                );

                if (movedDistance > 80) {
                  shouldRefreshRoute = true;
                }
              }

              if (shouldRefreshRoute) {
                _lastPolylineFetchPosition = newPos;

                await _getRoadPolyline(newPos, _userLocation);
              }
              if (distance > 50) {
                LatLngBounds bounds = LatLngBounds(
                  southwest: LatLng(
                    min(newPos.latitude, _userLocation.latitude),
                    min(newPos.longitude, _userLocation.longitude),
                  ),
                  northeast: LatLng(
                    max(newPos.latitude, _userLocation.latitude),
                    max(newPos.longitude, _userLocation.longitude),
                  ),
                );

                mapController.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 80),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching rider location: $e");
    }
  }

  void _startMovementSimulation() {
    if (_routePoints.isEmpty) _generateRoadSnappedRoute();

    // Smooth Timer: Update every 100ms for fluid movement
    _movementTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_currentStep < _routePoints.length - 1) {
        if (mounted) {
          setState(() {
            _currentStep++;
            _currentRiderPos = _routePoints[_currentStep];

            // ETA Calculation (Simulated total time 20 seconds / 200 ticks)
            double progress = _currentStep / _routePoints.length;
            _remainingMins = (12 - (progress * 11)).toInt().clamp(1, 12);

            // Update progress state based on movement
            if (_currentStep > 0 && _currentStep < _routePoints.length * 0.9) {
              _simulatedState = BookingState.onTheWay;
            } else if (_currentStep >= _routePoints.length * 0.9 &&
                _currentStep < _routePoints.length - 1) {
              _simulatedState = BookingState.started;
            } else if (_currentStep == _routePoints.length - 1) {
              _simulatedState = BookingState.completed;
            }
          });

          // If reached final destination
          if (_currentStep == _routePoints.length - 1) {
            _movementTimer?.cancel();

            // Arrival Pause before redirect
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _fetchAndRedirect();
              }
            });
          }
        }
      } else {
        _movementTimer?.cancel();
      }
    });
  }

  Future<void> _fetchAndRedirect() async {
    // 1. Get booking ID
    String? bookingId;
    if (widget.bookingData != null) {
      final bData = widget.bookingData is List
          ? (widget.bookingData as List).first
          : widget.bookingData;
      bookingId =
          bData['booking_detail']?['id']?.toString() ??
          bData['id']?.toString() ??
          bData['booking_id']?.toString();
    }

    debugPrint("--- Status Polling DEBUG ---");
    debugPrint("Raw BookingData: ${widget.bookingData}");
    debugPrint("Extracted Booking ID: $bookingId");

    if (bookingId == null || bookingId == "null") {
      debugPrint("ERROR: No Booking ID found for status polling!");
      // Don't redirect immediately to avoid loops, just stop or retry
      return;
    }

    // Status polling starts in the background
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.apiToken;
      final url = Uri.parse(
        '${ApiConfig.apiBaseUrl}/booking-detail?booking_id=$bookingId',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $apiToken',
          'Accept': 'application/json',
        },
      );

      debugPrint("API Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final rawData = json.decode(response.body);
        final data = rawData is List ? (rawData as List).first : rawData;
        final rawStatus =
            (data['booking_detail']?['status'] ?? data['status'])?.toString() ??
            "";
        final currentStatus = rawStatus.trim().toLowerCase();

        debugPrint("Current Status (Normalized): '$currentStatus'");

        if (mounted) {
          setState(() {
            _currentBookingData = data;
            if (currentStatus == 'accept')
              _backendStatus = "Accepted";
            else if (currentStatus == 'ongoing' || currentStatus == 'on_going')
              _backendStatus = "On the Way";
            else if (currentStatus == 'arrived')
              _backendStatus = "Arrived";
            else
              _backendStatus = currentStatus;
          });
        }

        // Only redirect if status is 'arrived', 'started', 'in_progress', 'pending_approval' or 'completed'
        if (currentStatus == 'arrived' ||
            currentStatus == 'started' ||
            currentStatus == 'in_progress' ||
            currentStatus == 'pending_approval' ||
            currentStatus == 'completed') {
          debugPrint(
            "MATCH FOUND! Redirecting to progress/verification screen...",
          );
          _performRedirect(data);
        } else {
          // Wait and try again in 5 seconds
          debugPrint("No match for status '$currentStatus'. Retrying in 5s...");
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) _fetchAndRedirect();
          });
        }
      } else {
        debugPrint("API Error during polling: ${response.body}");
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) _fetchAndRedirect();
        });
      }
    } catch (e) {
      debugPrint("Polling error: $e");
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) _fetchAndRedirect();
      });
    }
  }

  void _performRedirect(dynamic updatedData) {
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.serviceVerification,
        arguments: {
          'service': widget.service,
          'status': widget.bookingStatus,
          'price': widget.price,
          'booking_data': updatedData ?? widget.bookingData,
        },
      );
    }
  }

  String _formatRemainingTime(int totalMins) {
    if (totalMins < 60) {
      return "$totalMins mins";
    } else {
      int hours = totalMins ~/ 60;
      int mins = totalMins % 60;
      if (mins == 0) return "${hours}h";
      return "${hours}h ${mins}m";
    }
  }

  // Silver Map Style for a premium look
  static const String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "elementType": "labels.icon",
    "stylers": [
      {
        "visibility": "off"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#f5f5f5"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#bdbdbd"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#ffffff"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#757575"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dadada"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#616161"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#e5e5e5"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#eeeeee"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#c9c9c9"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9e9e9e"
      }
    ]
  }
]
''';

  @override
  Widget build(BuildContext context) {
    // ── Always build pro from live API data — never use dummy ──
    final _bData = _currentBookingData is List
        ? (_currentBookingData as List).first
        : _currentBookingData;
    final _rawProv = _bData?['provider_data'];
    final _provider = _rawProv is List
        ? (_rawProv.isNotEmpty ? _rawProv.first : {})
        : (_rawProv ?? {});
    final _rawSvc = _bData?['service'];
    final _service = _rawSvc is List
        ? (_rawSvc.isNotEmpty ? _rawSvc.first : {})
        : (_rawSvc ?? {});
    final _rawDet = _bData?['booking_detail'];
    final _detail = _rawDet is List
        ? (_rawDet.isNotEmpty ? _rawDet.first : {})
        : (_rawDet ?? {});
    final _rawHandy = _bData?['handyman_data'];
    final _handy = _rawHandy is List
        ? (_rawHandy.isNotEmpty ? _rawHandy.first : {})
        : (_rawHandy ?? {});

    final pro = ProfessionalMatch(
      name:
          _handy['display_name']?.toString() ??
          _provider['display_name']?.toString() ??
          _detail['provider_name']?.toString() ??
          "Professional",
      rating:
          (_handy['handyman_rating'] ??
                  _provider['providers_service_rating'] ??
                  _provider['handyman_rating'] ??
                  0)
              .toDouble(),
      jobsDone:
          (_handy['total_services_booked'] ??
                  _provider['total_services_booked'] ??
                  0)
              as int,
      avatarUrl:
          _handy['profile_image']?.toString() ??
          _service['provider_image']?.toString() ??
          _provider['profile_image']?.toString() ??
          "lib/assets/images/rider_image.png",
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildMapHeader(context, _formatRemainingTime(_remainingMins)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildProProfile(pro),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildContactActions(),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildServiceProgress(),
                ),
                const Divider(
                  thickness: 4,
                  color: Color(0xFFEEEEEE),
                  height: 80,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildServiceDetails(),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildActionFooter(),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          if (_isWaitingForBackendArrival)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.green,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Handyman Arriving...",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Waiting for the professional to confirm their arrival on the system.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapHeader(BuildContext context, String time) {
    debugPrint("MAP POLYLINE POINTS => ${_routePoints.length}");
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: GoogleMap(
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            initialCameraPosition: CameraPosition(
              target: _userLocation,
              zoom: 15.0,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              mapController.setMapStyle(_mapStyle);
            },
            polylines: _routePoints.isEmpty
                ? {}
                : {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      color: Colors.blue,
                      width: 6,
                      geodesic: false,
                      jointType: JointType.round,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                      points: _routePoints,
                    ),
                  },

            markers: {
              // Rider Marker (Custom Car)
              Marker(
                markerId: const MarkerId('rider'),
                rotation: 180,
                position: _currentRiderPos,
                icon:
                    _carIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                infoWindow: const InfoWindow(title: 'Rider On the Way'),
              ),
              // User Marker (Orange/Red)
              Marker(
                markerId: const MarkerId('user'),
                position: _userLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
                infoWindow: const InfoWindow(title: 'Home'),
              ),
            },
            circles: {
              Circle(
                circleId: const CircleId('test'),
                center: _userLocation,
                radius: 150,
                fillColor: Colors.blue.withOpacity(0.3),
                strokeColor: Colors.blue,
                strokeWidth: 2,
              ),
            },
          ),
        ),
        Positioned(
          bottom: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              "Arriving in $time",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProProfile(ProfessionalMatch pro) {
    final bData = _currentBookingData is List
        ? (_currentBookingData as List).first
        : _currentBookingData;
    final rawProvider = bData?['provider_data'];
    final provider = rawProvider is List
        ? (rawProvider.isNotEmpty ? rawProvider.first : null)
        : rawProvider;

    final rawService = bData?['service'];
    final service = rawService is List
        ? (rawService.isNotEmpty ? rawService.first : {})
        : rawService;

    final rawHandyman = bData?['handyman_data'];
    final handyman = rawHandyman is List
        ? (rawHandyman.isNotEmpty ? rawHandyman.first : {})
        : rawHandyman;

    final String name =
        handyman?['display_name']?.toString() ??
        provider?['display_name']?.toString() ??
        bData?['booking_detail']?['provider_name']?.toString() ??
        "Professional";
    final double rating = _getRatingWithFallback(handyman, provider);
    final int jobsDone =
        (handyman?['total_services_booked'] ??
                provider?['total_services_booked'] ??
                0)
            as int;

    String? profileImageUrl;
    if (handyman != null && handyman['profile_image'] != null) {
      profileImageUrl = handyman['profile_image'];
    } else if (service != null && service['provider_image'] != null) {
      profileImageUrl = service['provider_image'];
    } else if (provider != null) {
      profileImageUrl = provider['profile_image'];
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage:
              (profileImageUrl != null && profileImageUrl.startsWith('http'))
              ? CachedNetworkImageProvider(profileImageUrl, headers: const {})
                    as ImageProvider
              : const AssetImage('lib/assets/images/rider_image.png')
                    as ImageProvider,
          backgroundColor: const Color(0xFFFFF3E0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _backendStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFB300), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "($jobsDone jobs done)",
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _backendStatus == "Arrived"
                    ? "Professional is at your door"
                    : "On their way to your location",
                style: TextStyle(
                  color: _backendStatus == "Arrived"
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactActions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final bData = _currentBookingData is List
                  ? (_currentBookingData as List).first
                  : _currentBookingData;

              final rawHandyman = bData?['handyman_data'];
              final handyman = rawHandyman is List
                  ? (rawHandyman.isNotEmpty ? rawHandyman.first : {})
                  : rawHandyman;

              final rawProvider = bData?['provider_data'];
              final provider = rawProvider is List
                  ? (rawProvider.isNotEmpty ? rawProvider.first : {})
                  : rawProvider;

              final phone =
                  (handyman?['contact_number'] ?? provider?['contact_number'])
                      ?.toString()
                      ?.replaceAll(' ', '');

              if (phone != null && phone.isNotEmpty) {
                try {
                  final url = Uri.parse('tel:$phone');
                  await launchUrl(url, mode: LaunchMode.platformDefault);
                } catch (e) {
                  debugPrint('Could not launch call: $e');
                }
              }
            },
            child: _buildActionButton(
              icon: Icons.call,
              label: "Call",
              color: const Color(0xFFFFB300),
              textColor: Colors.black,
              isOutlined: false,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              final bData = _currentBookingData is List
                  ? (_currentBookingData as List).first
                  : _currentBookingData;
              final rawHandyman = bData?['handyman_data'];
              final handyman = rawHandyman is List
                  ? (rawHandyman.isNotEmpty ? rawHandyman.first : {})
                  : rawHandyman;
              final rawProvider = bData?['provider_data'];
              final provider = rawProvider is List
                  ? (rawProvider.isNotEmpty ? rawProvider.first : {})
                  : rawProvider;
              final rawDetail = bData?['booking_detail'];
              final detail = rawDetail is List
                  ? (rawDetail.isNotEmpty ? rawDetail.first : {})
                  : rawDetail;
              final rawService = bData?['service'];
              final service = rawService is List
                  ? (rawService.isNotEmpty ? rawService.first : {})
                  : rawService;

              bool hasHandyman =
                  handyman != null &&
                  (handyman['id'] != null || handyman['uid'] != null);
              bool hasProvider =
                  provider != null &&
                  (provider['id'] != null || provider['uid'] != null);

              Future<void> navigateToChat() async {
                final prefs = await SharedPreferences.getInstance();

                final backendUserId = prefs.getString('backend_user_id') ?? '';

                final target = getChatTarget();

                debugPrint("========== OPEN CHAT ==========");
                debugPrint("MY CHAT ID => user_$backendUserId");
                debugPrint("TARGET UID => ${target['uid']}");
                debugPrint("================================");
                debugPrint("=========== CHAT DEBUG ===========");

                debugPrint("BOOKING ID => $_bookingId");

                debugPrint("TARGET => $target");

                debugPrint("MY ID => user_$backendUserId");

                debugPrint("==================================");

                Navigator.pushNamed(
                  context,
                  AppRoutes.chatHomeScreen,
                  arguments: {
                    'booking_id': _bookingId,

                    // sender
                    'my_chat_id': 'user_$backendUserId',

                    // receiver
                    'provider_uid': target['uid'],

                    'name': target['name'],
                    'image': target['image'],

                    'is_handyman_chat': target['isHandyman'],
                  },
                );
              }

              navigateToChat();
            },
            child: _buildActionButton(
              icon: Icons.chat_bubble_outline,
              label: "Chat",
              color: Colors.black,
              textColor: Colors.black,
              isOutlined: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required bool isOutlined,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.white : color,
        borderRadius: BorderRadius.circular(12),
        border: isOutlined ? Border.all(color: color) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceProgress() {
    final steps =
        widget.bookingStatus.steps ??
        [
          const ProgressStepModel(
            title: "Booking confirmed",
            subtitle: "",
            state: BookingState.assigned,
          ),
          const ProgressStepModel(
            title: "Professional Assigned",
            subtitle: "",
            state: BookingState.assigned,
          ),
          const ProgressStepModel(
            title: "On the Way",
            subtitle: "On thier way to your location",
            state: BookingState.onTheWay,
          ),
          const ProgressStepModel(
            title: "Service Started",
            subtitle: "",
            state: BookingState.started,
          ),
          const ProgressStepModel(
            title: "Service Completed",
            subtitle: "",
            state: BookingState.completed,
          ),
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Service Progress",
          style: TextStyle(
            color: Color(0xFFD90000),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(steps.length, (index) {
          final int currentIndex = _getStepIndex(_simulatedState);
          bool isCompleted = index < currentIndex;

          // User request: On the Way (index 2) turns green as soon as movement starts
          if (index == 2 && _currentStep > 0) {
            isCompleted = true;
          }

          final bool isActive = !isCompleted && index == currentIndex;

          return _buildProgressStep(
            steps[index].title,
            subtitle: steps[index].subtitle,
            isCompleted: isCompleted,
            isActive: isActive,
            isLast: index == steps.length - 1,
          );
        }),
      ],
    );
  }

  int _getStepIndex(BookingState state) {
    switch (state) {
      case BookingState.searching:
        return -1;
      case BookingState.assigned:
        return 1;
      case BookingState.onTheWay:
        return 2;
      case BookingState.started:
        return 3;
      case BookingState.completed:
        return 4;
      default:
        return 0;
    }
  }

  Widget _buildProgressStep(
    String title, {
    required String subtitle,
    required bool isCompleted,
    bool isActive = false,
    required bool isLast,
  }) {
    Color bgColor = Colors.white;
    if (isCompleted) {
      bgColor = const Color(0xFFE8F5E9); // Light Green
    } else if (isActive) {
      bgColor = const Color(0xFFFEDC85); // Light Yellow
    }

    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFFC8E6C9)
                    : (isActive ? const Color(0xFFFEDC85) : Colors.white),
                border: Border.all(
                  color: (isCompleted || isActive)
                      ? Colors.transparent
                      : Colors.black26,
                ),
              ),
              child: Icon(
                isCompleted ? Icons.check : (isActive ? Icons.sensors : null),
                size: 14,
                color: isCompleted
                    ? Colors.green[800]
                    : (isActive ? Colors.orange[800] : Colors.transparent),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted ? Colors.green[200] : Colors.black12,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              width: 280,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: (isCompleted || isActive)
                                ? Colors.black
                                : Colors.black54,
                          ),
                        ),
                        if (isActive && subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isActive)
                    const Icon(
                      Icons.sensors,
                      color: Color(0xFFD90000),
                      size: 16,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceDetails() {
    String title = "Service";
    String image = UserMessages.serviceBookingDummy1;
    bool isNetworkImage = false;

    if (widget.bookingData != null) {
      final bData = widget.bookingData is List
          ? (widget.bookingData as List).first
          : widget.bookingData;
      title = bData['booking_detail']?['service_name'] ?? "Service";
      final rawService = bData['service'];
      final service = rawService is List
          ? (rawService.isNotEmpty ? rawService.first : null)
          : rawService;
      final attch = service?['attchments_array'];
      if (attch != null && attch is List && attch.isNotEmpty) {
        image = attch[0]['url'];
        isNetworkImage = true;
      }
    } else if (widget.service is ServiceData) {
      title = (widget.service as ServiceData).name ?? "Service";
      image =
          (widget.service as ServiceData).providerImage ??
          UserMessages.serviceBookingDummy1;
    } else if (widget.service != null) {
      try {
        title = widget.service.title;
        image = widget.service.image;
      } catch (_) {
        title = "Service";
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Service Details",
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${widget.bookingStatus.appointmentDate} ~ ${widget.bookingStatus.appointmentTime}",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isNetworkImage
                  ? CachedNetworkImage(
                      imageUrl: image,
                      width: 100,
                      height: 70,
                      fit: BoxFit.cover,
                      httpHeaders: const {},
                    )
                  : Image.asset(
                      image,
                      width: 100,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionFooter() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.helpDesk),
            child: _buildFooterButton(
              Icons.support_agent,
              "Support",
              Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButton(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class MapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.4)
      ..lineTo(size.width * 0.5, size.height * 0.3)
      ..lineTo(size.width * 0.7, size.height * 0.2);

    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.4),
      6,
      Paint()..color = Colors.orange,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.2),
      8,
      Paint()..color = Colors.green,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
