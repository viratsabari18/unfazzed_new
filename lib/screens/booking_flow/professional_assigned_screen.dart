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
import 'package:cloud_firestore/cloud_firestore.dart';

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
  // FIX 1: Give default values instead of nullable
  LatLng _userLocation = const LatLng(28.6139, 77.2090);
  LatLng _currentRiderPos = const LatLng(28.6155, 77.2150);
  late int _remainingMins;
  DateTime? _arrivalTime;
  late BookingState _simulatedState;
  BitmapDescriptor? _carIcon;
  List<LatLng> _routePoints = [];
  List<LatLng> _remainingRoute = [];
  LatLng? _lastPolylineFetchPosition;
  int _currentStep = 0;
  double _totalKm = 0;
  int _tickCount = 0;
  bool _isLoadingLocation = true;
  bool _isEtaLoading = true;
  bool _isWaitingForBackendArrival = false;
  String _backendStatus = "On the Way";
  dynamic _currentBookingData;
  String? _bookingId;
  bool _followVehicle = true;
  bool _isMapReady = false;
  bool _hasUserLocationFromWidget = false;
  bool _hasRiderLocationFromWidget = false;

  final Map<String, double> _dummyRatingsCache = {};

  @override
  void initState() {
    super.initState();

    _currentBookingData = widget.bookingData;
    debugPrint("========== SCREEN OPEN ==========");
    debugPrint("BOOKING DATA => ${widget.bookingData}");
    debugPrint("INITIAL USER => ${widget.initialUserLocation}");
    debugPrint("INITIAL RIDER => ${widget.initialRiderLocation}");
    debugPrint("=================================");

    // FIX 1: Use widget values if provided, otherwise keep defaults
    if (widget.initialUserLocation != null) {
      _userLocation = widget.initialUserLocation!;
      _hasUserLocationFromWidget = true;
      _isLoadingLocation = false;
    }

    if (widget.initialRiderLocation != null) {
      _currentRiderPos = widget.initialRiderLocation!;
      _hasRiderLocationFromWidget = true;
      debugPrint("INITIAL RIDER LOCATION FROM WIDGET => ${_currentRiderPos}");
    } else {
      debugPrint("No initial rider location found - will fetch from API");
    }

    _remainingMins = 0;
    _simulatedState = widget.bookingStatus.currentState;

    _initializeTracking();
  }

  Future<void> _initializeSavedEta() async {
    debugPrint("========== INITIALIZE TRACKING ==========");
    debugPrint("BOOKING ID => $_bookingId");
    debugPrint("USER LOCATION => $_userLocation");
    debugPrint("RIDER LOCATION => $_currentRiderPos");
    debugPrint("=========================================");
    if (_bookingId == null) return;

    final prefs = await SharedPreferences.getInstance();

    final savedArrival = prefs.getString('arrival_time_${_bookingId}');

    if (savedArrival != null) {
      _arrivalTime = DateTime.parse(savedArrival);

      final remaining = _arrivalTime!.difference(DateTime.now()).inMinutes;

      if (mounted && _routePoints.isNotEmpty) {
        setState(() {
          _remainingMins = remaining < 0 ? 0 : remaining;

          // Calculate progress and restore position
          if (_totalKm > 0 && _routePoints.isNotEmpty) {
            final totalMinutes = max(1, (_totalKm * 4).ceil());
            final progress = 1 - (_remainingMins / totalMinutes);

            _currentStep = (progress * _routePoints.length).floor();

            if (_currentStep >= _routePoints.length) {
              _currentStep = _routePoints.length - 1;
            }
            if (_currentStep < 0) {
              _currentStep = 0;
            }

            _currentRiderPos = _routePoints[_currentStep];
            _remainingRoute = _routePoints.sublist(_currentStep);
          }

          _isEtaLoading = false;
        });
      }
    }
  }

  Future<void> _initializeTracking() async {
    _loadCustomIcons();

    if (widget.bookingData != null) {
      final bData = widget.bookingData is List
          ? (widget.bookingData as List).first
          : widget.bookingData;
      _bookingId =
          bData['booking_detail']?['id']?.toString() ?? bData['id']?.toString();
    }

    _setBookingLocation();

    if (_bookingId != null) {
      // Fetch rider location from API
      debugPrint("CURRENT BOOKING => $_bookingId");
      await _fetchRiderLocation(_bookingId!);

      // FIX 4: Generate route even when provider location fails
      if (_currentRiderPos == null) {
        _currentRiderPos = _userLocation;
      }

      debugPrint("AFTER API CALL");
      debugPrint("RIDER LOCATION => $_currentRiderPos");

      // FIX 4: Add debug logs to track route generation
      debugPrint(
        "ROUTE START => ${_currentRiderPos!.latitude}, ${_currentRiderPos!.longitude}",
      );
      debugPrint(
        "ROUTE END => ${_userLocation!.latitude}, ${_userLocation!.longitude}",
      );

      await _getRoadPolyline(_currentRiderPos!, _userLocation!);
      debugPrint("ROUTE GENERATED");
      debugPrint("ROUTE POINTS => ${_routePoints.length}");

      // Only initialize ETA and start simulation if route exists
      if (_routePoints.isNotEmpty) {
        await _initializeSavedEta();
        _startMovementSimulation();
      } else {
        debugPrint("WARNING: Route generation failed - skipping simulation");
      }

      _fetchAndRedirect();
    } else if (_hasUserLocationFromWidget) {
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
        _hasUserLocationFromWidget = true;
        debugPrint("BOOKING LOCATION => $lat , $lng");
      } else {
        debugPrint("ERROR: Failed to parse booking location");
      }
    } catch (e) {
      debugPrint("Booking location error: $e");
    }
  }

  Map<String, dynamic> getChatTarget() {
    final bData = _currentBookingData is List
        ? (_currentBookingData as List).first
        : _currentBookingData;

    final rawProvider = bData?['provider_data'];
    final provider = rawProvider is List
        ? (rawProvider.isNotEmpty ? rawProvider.first : {})
        : (rawProvider ?? {});

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

    if (isRealHandyman) {
      final handymanId = handyman['id'].toString();
      return {
        'uid': 'handyman_$handymanId',
        'name': handyman['display_name'] ?? handyman['name'] ?? 'Handyman',
        'image': handyman['profile_image'] ?? '',
        'isHandyman': true,
      };
    }

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

    final id =
        handyman?['id']?.toString() ??
        handyman?['uid']?.toString() ??
        provider?['id']?.toString() ??
        provider?['uid']?.toString() ??
        'default';

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
        if (_bookingId == null && _hasUserLocationFromWidget) {
          _generateRoadSnappedRoute();
        }
        _isLoadingLocation = false;
      });
      if (_hasUserLocationFromWidget && _isMapReady) {
        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(_userLocation, 15),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _generateRoadSnappedRoute() {
    final List<LatLng> majorPoints = [
      LatLng(_userLocation.latitude + 0.005, _userLocation.longitude + 0.005),
      LatLng(_userLocation.latitude + 0.005, _userLocation.longitude + 0.002),
      LatLng(_userLocation.latitude + 0.002, _userLocation.longitude + 0.002),
      LatLng(_userLocation.latitude + 0.001, _userLocation.longitude + 0.001),
      _userLocation,
    ];

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
    _remainingRoute = List.from(smoothPoints);
    _currentRiderPos = _routePoints[0];
    _currentStep = 0;
  }

  Future<void> _getRoadPolyline(LatLng start, LatLng end) async {
    try {
      PolylinePoints polylinePoints = PolylinePoints();

      // Add timeout to prevent hanging
      PolylineResult result = await polylinePoints
          .getRouteBetweenCoordinates(
            googleApiKey: "AIzaSyAW3nH7YUQnZVx09h1wB9fBbwE6CpT8iRE",
            request: PolylineRequest(
              origin: PointLatLng(start.latitude, start.longitude),
              destination: PointLatLng(end.latitude, end.longitude),
              mode: TravelMode.driving,
            ),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint("GOOGLE ROUTE TIMEOUT - Taking too long");
              return PolylineResult(
                points: [],
                errorMessage: "Request timeout",
              );
            },
          );

      debugPrint("Polyline points => ${result.points.length}");

      // Handle empty route response
      if (result.points.isEmpty) {
        debugPrint("GOOGLE ROUTE FAILED - No points returned");

        if (mounted) {
          setState(() {
            // Use direct line as fallback route
            _routePoints = [start, end];
            _remainingRoute = [start, end];
          });
        }

        return;
      }

      if (result.points.isNotEmpty) {
        List<LatLng> polylineCoordinates = [];

        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }

        if (mounted) {
          setState(() {
            _routePoints.clear();
            _routePoints.addAll(polylineCoordinates);
            _remainingRoute = List.from(polylineCoordinates);

            // Only reset position if this is first load and no saved position exists
            if (_currentStep == 0 && _routePoints.isNotEmpty) {
              _currentRiderPos = _routePoints.first;
            } else if (_routePoints.isNotEmpty &&
                _currentStep < _routePoints.length) {
              // Restore saved position
              _currentRiderPos = _routePoints[_currentStep];
              _remainingRoute = _routePoints.sublist(_currentStep);
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Road polyline error => $e");

      // Fallback to direct line on error
      if (mounted) {
        setState(() {
          _routePoints = [start, end];
          _remainingRoute = [start, end];
        });
      }
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
        'lib/assets/images/driver_trial1.png',
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

  // FIX 3: Add fallback when API fails
  Future<void> _fetchRiderLocation(String bookingId) async {
    debugPrint("========== FETCH RIDER LOCATION ==========");
    debugPrint("BOOKING ID => $bookingId");
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
      debugPrint("STATUS CODE => ${response.statusCode}");
      debugPrint("RAW RESPONSE => ${response.body}");
      debugPrint("BOOKING ID => $bookingId");

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final locData = result['data'];
        if (locData != null) {
          final lat = double.tryParse(locData['latitude'].toString());
          final lng = double.tryParse(locData['longitude'].toString());
          debugPrint("API PROVIDER LOCATION => $lat,$lng");
          if (lat != null && lng != null) {
            debugPrint("VALID LOCATION FOUND");
            debugPrint("LAT => $lat");
            debugPrint("LNG => $lng");

            final newPos = LatLng(lat, lng);

            double distance = Geolocator.distanceBetween(
              lat,
              lng,
              _userLocation.latitude,
              _userLocation.longitude,
            );

            double distanceInKm = distance / 1000;

            // Always use latest distance from API
            _totalKm = distanceInKm;

            final totalMinutes = max(1, (distanceInKm * 4).ceil());

            // Only create arrival time if it doesn't exist
            final prefs = await SharedPreferences.getInstance();
            final existingArrival = prefs.getString(
              'arrival_time_${_bookingId}',
            );

            if (existingArrival == null) {
              _arrivalTime = DateTime.now().add(
                Duration(minutes: totalMinutes),
              );
              await prefs.setString(
                'arrival_time_${_bookingId}',
                _arrivalTime!.toIso8601String(),
              );
            } else {
              _arrivalTime = DateTime.parse(existingArrival);
            }

            if (mounted) {
              setState(() {
                _currentRiderPos = newPos;
                final remaining = _arrivalTime!
                    .difference(DateTime.now())
                    .inMinutes;
                _remainingMins = remaining < 0 ? 0 : remaining;
                _isEtaLoading = false;

                if (distance < 100) {
                  _simulatedState = BookingState.started;
                  _movementTimer?.cancel();
                  _fetchAndRedirect();
                } else {
                  _simulatedState = BookingState.onTheWay;
                }
              });

              debugPrint("PROVIDER => ${newPos.latitude}, ${newPos.longitude}");
              debugPrint(
                "USER => ${_userLocation.latitude}, ${_userLocation.longitude}",
              );
              debugPrint("DISTANCE => ${distance / 1000} KM");

              if (distance > 50 && _isMapReady) {
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
          } else {
            debugPrint("❌ LAT LNG NULL");
          }
        } else {
          debugPrint("ERROR: No location data in API response");
        }
      } else {
        // FIX 3: Fallback when API fails
        debugPrint("API ERROR => ${response.statusCode}");
        debugPrint("ERROR: API returned status code ${response.statusCode}");

        if (mounted && _hasUserLocationFromWidget) {
          setState(() {
            _currentRiderPos = _userLocation;
            _isEtaLoading = false;
          });

          debugPrint(
            "FALLBACK RIDER LOCATION => ${_currentRiderPos.latitude}, ${_currentRiderPos.longitude}",
          );
        }
      }
    } catch (e) {
      // FIX 3: Fallback when API fails
      debugPrint("Error fetching rider location: $e");

      if (mounted && _hasUserLocationFromWidget) {
        setState(() {
          _currentRiderPos = _userLocation;
          _isEtaLoading = false;
        });

        debugPrint(
          "FALLBACK FROM CATCH => ${_currentRiderPos.latitude}, ${_currentRiderPos.longitude}",
        );
      }
    }
  }

  void _startMovementSimulation() {
    if (_routePoints.isEmpty) {
      debugPrint("ERROR: Cannot start simulation - route points empty");
      return;
    }

    final int totalRoutePoints = _routePoints.length;
    final int totalMinutes = max(1, (_totalKm * 4).ceil());
    final int totalTicks = totalMinutes * 12;
    final double stepPerTick = totalRoutePoints / totalTicks;
    double currentProgress = _currentStep.toDouble();

    _movementTimer?.cancel();

    _movementTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      currentProgress += stepPerTick;
      _tickCount++;
      _currentStep = currentProgress.floor();

      // Restore progress based on remaining time
      if (_remainingMins > 0) {
        final progress = 1 - (_remainingMins / totalMinutes);
        final savedStep = (progress * totalRoutePoints).floor();

        if (savedStep > _currentStep) {
          _currentStep = savedStep;
        }
      }

      if (_currentStep >= totalRoutePoints) {
        _currentStep = totalRoutePoints - 1;
      }

      if (mounted) {
        setState(() {
          if (_remainingMins > 1) {
            _currentRiderPos = _routePoints[_currentStep];

            if (_followVehicle && _isMapReady) {
              mapController.animateCamera(
                CameraUpdate.newLatLng(_currentRiderPos),
              );
            }

            _remainingRoute = _routePoints.sublist(_currentStep);
          }

          if (_tickCount % 12 == 0) {
            if (_remainingMins > 1) {
              _remainingMins--;
            }
          }
          if (_remainingMins <= 1) {
            timer.cancel();
            return;
          }
        });
      }
    });
  }

  Stream<int> getUnreadCount() async* {
    final prefs = await SharedPreferences.getInstance();
    final backendUserId = prefs.getString('backend_user_id') ?? '';
    final target = getChatTarget();
    final roomId = 'booking_${_bookingId}_${target['uid']}';

    debugPrint("=========== UNREAD DEBUG ===========");
    debugPrint("ROOM ID => $roomId");
    debugPrint("USER ID => user_$backendUserId");
    debugPrint("TARGET => ${target['uid']}");
    debugPrint("====================================");

    yield* FirebaseFirestore.instance
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .where('receiverId', isEqualTo: 'user_$backendUserId')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((e) {
          debugPrint("UNREAD COUNT => ${e.docs.length}");
          return e.docs.length;
        });
  }

  Future<void> _fetchAndRedirect() async {
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
      return;
    }

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

  static const String _mapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#f5f5f5"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#f5f5f5"}]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#bdbdbd"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#eeeeee"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#e5e5e5"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9e9e9e"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#dadada"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9e9e9e"}]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [{"color": "#e5e5e5"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [{"color": "#eeeeee"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#c9c9c9"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#9e9e9e"}]
  }
]
''';

  void _handleBack() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.landingPage,
      (route) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    debugPrint("========== BUILD ==========");
    debugPrint("_userLocation => $_userLocation");
    debugPrint("_currentRiderPos => $_currentRiderPos");
    debugPrint("_routePoints => ${_routePoints.length}");
    debugPrint("_isLoadingLocation => $_isLoadingLocation");
    debugPrint("===========================");

    // FIX 2: Remove infinite loading condition - only show loading for user location
    // Provider location should not block the entire screen
    if (!_hasUserLocationFromWidget && _isLoadingLocation) {
      return PopScope(
        canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF6366F1)),
                SizedBox(height: AppSizes.h(context, 16)),
                Text(
                  "Loading location data...",
                  style: TextStyle(
                    fontSize: AppSizes.w(context, 14),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildMapHeader(context, _formatRemainingTime(_remainingMins)),
                  _buildProfessionalInfoCard(pro),
                  SizedBox(height: AppSizes.h(context, 3)),
                  _buildServiceProgress(),
                  SizedBox(height: AppSizes.h(context, 3)),
                  _buildServiceAndSupportCard(),
                  SizedBox(height: AppSizes.h(context, 3)),
                  _buildFooterButton(
                    Icons.support_agent,
                    "Support",
                    Colors.black,
                  ),
                  SizedBox(height: AppSizes.h(context, 40)),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + AppSizes.h(context, 8),
              left: AppSizes.w(context, 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: AppSizes.w(context, 8),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: Colors.black,
                    size: AppSizes.w(context, 20),
                  ),
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.landingPage,
                  ),
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
                        borderRadius: BorderRadius.circular(
                          AppSizes.w(context, 16),
                        ),
                      ),
                      margin: EdgeInsets.symmetric(
                        horizontal: AppSizes.w(context, 40),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(AppSizes.w(context, 24)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.green,
                              strokeWidth: 3,
                            ),
                            SizedBox(height: AppSizes.h(context, 20)),
                            Text(
                              "Handyman Arriving...",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: AppSizes.w(context, 18),
                              ),
                            ),
                            SizedBox(height: AppSizes.h(context, 8)),
                            Text(
                              "Waiting for the professional to confirm their arrival on the system.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppSizes.w(context, 13),
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
      ),
    );
  }

  Widget _buildMapHeader(BuildContext context, String time) {
    debugPrint("MAP POLYLINE POINTS => ${_routePoints.length}");
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: AppSizes.h(context, 300),
          width: double.infinity,
          child: GoogleMap(
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            onCameraMoveStarted: () {
              _followVehicle = false;
            },
            onTap: (argument) {
              _followVehicle = false;
            },
            initialCameraPosition: CameraPosition(
              target: _userLocation,
              zoom: 15.0,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              mapController.setMapStyle(_mapStyle);
              _isMapReady = true;
            },
            polylines: _remainingRoute.isEmpty
                ? {}
                : {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      color: Colors.red,
                      width: 4,
                      geodesic: false,
                      jointType: JointType.round,
                      startCap: Cap.roundCap,
                      endCap: Cap.roundCap,
                      points: _remainingRoute,
                    ),
                  },
            markers: {
              Marker(
                markerId: const MarkerId('rider'),
                position: _currentRiderPos,
                rotation: 180,
                icon:
                    _carIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                infoWindow: const InfoWindow(title: 'Rider On the Way'),
              ),
              Marker(
                markerId: const MarkerId('user'),
                position: _userLocation,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
                infoWindow: const InfoWindow(title: 'Home'),
              ),
            },
          ),
        ),
        Positioned(
          bottom: AppSizes.h(context, 20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.w(context, 20),
              vertical: AppSizes.h(context, 10),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.w(context, 20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: AppSizes.w(context, 10),
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              _remainingMins <= 0
                  ? "📍 Your professional is nearby"
                  : _remainingMins <= 1
                  ? "📍 Your professional is nearby"
                  : "Arriving in $time",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.w(context, 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Rest of the UI methods remain the same...
  Widget _buildProfessionalInfoCard(ProfessionalMatch pro) {
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

    return Transform.translate(
      offset: Offset(0, -AppSizes.h(context, 5)),
      child: Container(
        margin: EdgeInsets.only(bottom: AppSizes.h(context, 2)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.w(context, 16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: AppSizes.w(context, 12),
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(AppSizes.w(context, 16)),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: AppSizes.w(context, 30),
                    backgroundImage:
                        (profileImageUrl != null &&
                            profileImageUrl.startsWith('http'))
                        ? CachedNetworkImageProvider(profileImageUrl)
                              as ImageProvider
                        : const AssetImage('lib/assets/images/rider_image.png')
                              as ImageProvider,
                    backgroundColor: const Color(0xFFFFF3E0),
                  ),
                  SizedBox(width: AppSizes.w(context, 12)),
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
                                style: TextStyle(
                                  fontSize: AppSizes.w(context, 16),
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: AppSizes.w(context, 8)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSizes.w(context, 10),
                                vertical: AppSizes.h(context, 5),
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.w(context, 8),
                                ),
                              ),
                              child: Text(
                                _backendStatus,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppSizes.w(context, 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSizes.h(context, 4)),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: const Color(0xFFFFB300),
                              size: AppSizes.w(context, 14),
                            ),
                            SizedBox(width: AppSizes.w(context, 4)),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: AppSizes.w(context, 12),
                              ),
                            ),
                            SizedBox(width: AppSizes.w(context, 4)),
                            Text(
                              "($jobsDone jobs done)",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: AppSizes.w(context, 12),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSizes.h(context, 4)),
                        Text(
                          _backendStatus == "Arrived"
                              ? "Professional is at your door"
                              : "On their way to your location",
                          style: TextStyle(
                            color: _backendStatus == "Arrived"
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                            fontSize: AppSizes.w(context, 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.h(context, 20)),
              Row(
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
                            (handyman?['contact_number'] ??
                                    provider?['contact_number'])
                                ?.toString()
                                ?.replaceAll(' ', '');

                        if (phone != null && phone.isNotEmpty) {
                          try {
                            final url = Uri.parse('tel:$phone');
                            await launchUrl(
                              url,
                              mode: LaunchMode.platformDefault,
                            );
                          } catch (e) {
                            debugPrint('Could not launch call: $e');
                          }
                        }
                      },
                      child: _buildActionButton(
                        icon: Icons.call,
                        label: "Call",
                        color: AppColors.discountRed,
                        textColor: AppColors.naturalWhite,
                        isOutlined: false,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.w(context, 16)),
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

                        Future<void> navigateToChat() async {
                          final prefs = await SharedPreferences.getInstance();
                          final backendUserId =
                              prefs.getString('backend_user_id') ?? '';
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
                              'my_chat_id': 'user_$backendUserId',
                              'provider_uid': target['uid'],
                              'name': target['name'],
                              'image': target['image'],
                              'is_handyman_chat': target['isHandyman'],
                            },
                          );
                        }

                        navigateToChat();
                      },
                      child: StreamBuilder<int>(
                        stream: getUnreadCount(),
                        builder: (context, snapshot) {
                          final unread = snapshot.data ?? 0;

                          return Container(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h(context, 8),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppSizes.w(context, 8),
                              ),
                              border: Border.all(
                                color: AppColors.borderRejected,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  color: AppColors.borderRejected,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "Chat",
                                  style: TextStyle(
                                    color: AppColors.borderRejected,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (unread > 0) ...[
                                  SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      unread > 99 ? "99+" : unread.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
      padding: EdgeInsets.symmetric(vertical: AppSizes.h(context, 8)),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.white : color,
        borderRadius: BorderRadius.circular(AppSizes.w(context, 8)),
        border: isOutlined ? Border.all(color: color) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: AppSizes.w(context, 20)),
          SizedBox(width: AppSizes.w(context, 4)),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.w(context, 14),
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
            title: "Booking Confirmed",
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
            subtitle: "Your professional is on the way",
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

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.w(context, 18),
        vertical: AppSizes.h(context, 12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.w(context, 24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: AppSizes.w(context, 18),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Service Progress",
            style: TextStyle(
              fontSize: AppSizes.w(context, 17),
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          SizedBox(height: AppSizes.h(context, 13)),
          ...List.generate(steps.length, (index) {
            final int currentIndex = _getStepIndex(_simulatedState);
            bool isCompleted = index < currentIndex;
            if (index == 2 && _currentStep > 0) {
              isCompleted = true;
            }
            final bool isActive = index == 2;

            return _buildProgressStep(
              steps[index].title,
              subtitle: steps[index].subtitle,
              isCompleted: isCompleted,
              isActive: isActive,
              isLast: index == steps.length - 1,
            );
          }),
        ],
      ),
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
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Container(
                    width: AppSizes.w(context, 28),
                    height: AppSizes.h(context, 35),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFFE9F9EE)
                          : isActive
                          ? const Color(0xFFFFF6E1)
                          : Colors.white,
                    ),
                    child: Center(
                      child: Container(
                        width: AppSizes.w(context, 18),
                        height: AppSizes.w(context, 18),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? const Color(0xFF22C55E)
                              : isActive
                              ? const Color(0xFFFFC107)
                              : Colors.white,
                          border: Border.all(
                            color: isCompleted || isActive
                                ? Colors.transparent
                                : Colors.black45,
                            width: 1.5,
                          ),
                        ),
                        child: isCompleted
                            ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: AppSizes.w(context, 12),
                              )
                            : isActive
                            ? Icon(
                                Icons.sensors,
                                color: Colors.white,
                                size: AppSizes.w(context, 11),
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: AppSizes.h(context, 12),
                      color: isCompleted || isActive
                          ? const Color(0xFFD7F3DF)
                          : Colors.black12,
                    ),
                ],
              ),
              SizedBox(width: AppSizes.w(context, 10)),
              Expanded(
                child: Container(
                  padding: isActive
                      ? EdgeInsets.symmetric(
                          horizontal: AppSizes.w(context, 14),
                          vertical: AppSizes.h(context, 8),
                        )
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFFF6E1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      AppSizes.w(context, 16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: AppSizes.w(context, 14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              SizedBox(height: AppSizes.h(context, 1)),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: AppSizes.w(context, 13),
                                  color: const Color(0xFFB7791F),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: EdgeInsets.only(left: AppSizes.w(context, 40)),
            child: Container(
              height: 1,
              margin: EdgeInsets.symmetric(vertical: AppSizes.h(context, 4)),
              color: Colors.black12,
            ),
          ),
      ],
    );
  }

  Widget _buildServiceAndSupportCard() {
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

    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSizes.h(context, 8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.w(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: AppSizes.w(context, 12),
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSizes.w(context, 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Service Details",
              style: TextStyle(
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.w(context, 16),
              ),
            ),
            SizedBox(height: AppSizes.h(context, 12)),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: AppSizes.w(context, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: AppSizes.h(context, 8)),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: AppSizes.w(context, 15),
                            color: Colors.black54,
                          ),
                          SizedBox(width: AppSizes.w(context, 6)),
                          Text(
                            widget.bookingStatus.appointmentDate,
                            style: TextStyle(
                              fontSize: AppSizes.w(context, 13),
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSizes.h(context, 8)),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: AppSizes.w(context, 15),
                            color: Colors.black54,
                          ),
                          SizedBox(width: AppSizes.w(context, 6)),
                          Text(
                            widget.bookingStatus.appointmentTime,
                            style: TextStyle(
                              fontSize: AppSizes.w(context, 13),
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.w(context, 12)),
                  child: isNetworkImage
                      ? CachedNetworkImage(
                          imageUrl: image,
                          width: AppSizes.w(context, 100),
                          height: AppSizes.h(context, 70),
                          fit: BoxFit.cover,
                          httpHeaders: const {},
                        )
                      : Image.asset(
                          image,
                          width: AppSizes.w(context, 100),
                          height: AppSizes.h(context, 70),
                          fit: BoxFit.cover,
                        ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.h(context, 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButton(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.helpDesk),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: AppSizes.h(context, 3)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.w(context, 16)),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: AppSizes.w(context, 4),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppSizes.w(context, 24)),
            SizedBox(height: AppSizes.h(context, 4)),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: AppSizes.w(context, 12),
              ),
            ),
          ],
        ),
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
