import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:zeerah/core/config/api_config.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/models/service_list_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:zeerah/core/services/booking_service.dart';

class BookingStatusScreen extends StatefulWidget {
  final dynamic service;
  final String? bookingId;
  final String? date;
  final String? time;
  final String? price;

  const BookingStatusScreen({
    required this.service,
    this.bookingId,
    this.date,
    this.time,
    this.price,
    super.key,
  });

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  Timer? _pollingTimer;
  bool _isDisposed = false;
  bool _isAccepted = false;
  bool _isSearchingDone = false;
  bool _isCancelling = false;
  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _startPolling();

    // Simulate searching transition for Step 1
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isDisposed) {
        setState(() {
          _isSearchingDone = true;
        });
      }
    });
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isDisposed) {
        _fetchBookingDetails();
      }
    });
    // Also fetch immediately
    _fetchBookingDetails();
  }

  Future<void> _cancelBooking() async {
    if (widget.bookingId == null) return;
    
    setState(() => _isCancelling = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final success = await _bookingService.updateBookingStatus(
      bookingId: widget.bookingId!,
      status: "cancelled",
      reason: "Cancelled from searching screen",
      token: userProvider.apiToken,
    );

    if (mounted) {
      setState(() => _isCancelling = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking cancelled successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to cancel booking. Please try again.")),
        );
      }
    }
  }

        void _handleBack() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.landingPage,
      (route) => false,
    );
  }
  Future<void> _fetchBookingDetails() async {
    if (widget.bookingId == null || widget.bookingId!.startsWith('#')) {
      debugPrint("Invalid or dummy booking ID: ${widget.bookingId}");
      return;
    }

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.apiToken;

      final url = Uri.parse('${ApiConfig.apiBaseUrl}/booking-detail?booking_id=${widget.bookingId}');
      debugPrint("Polling booking status: $url");
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          
          if (apiToken != null && apiToken.isNotEmpty)
            'Authorization': 'Bearer $apiToken',
        },
      );

      if (response.statusCode == 200) {
        final rawData = json.decode(response.body);
        final data = rawData is List ? (rawData.isNotEmpty ? rawData.first : {}) : (rawData as Map<String, dynamic>);
        
        final rawBookingDetail = data['booking_detail'];
        final bookingDetail = rawBookingDetail is List ? (rawBookingDetail.isNotEmpty ? rawBookingDetail.first : {}) : rawBookingDetail;
        
        final status = bookingDetail?['status']?.toString().toLowerCase();
        
        debugPrint("Booking Status received: $status");

        if ((status == 'ongoing' || status == 'on_going') && !_isDisposed) {
          debugPrint("Status changed to $status. Pre-fetching locations...");
          
          setState(() {
            _isAccepted = true;
          });

          _pollingTimer?.cancel();

          // Pre-fetch locations for instant map update
          LatLng? userLoc;
          LatLng? riderLoc;
          
          try {
            // 1. Get User Location
            bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
            if (serviceEnabled) {
              LocationPermission permission = await Geolocator.checkPermission();
              if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
                Position position = await Geolocator.getCurrentPosition();
                userLoc = LatLng(position.latitude, position.longitude);
              }
            }

            // 2. Get Rider Location
            final bookingId = widget.bookingId;
            final locUrl = Uri.parse('${ApiConfig.apiBaseUrl}/get-location?booking_id=$bookingId');
            final locResponse = await http.get(locUrl, headers: {
              'Authorization': 'Bearer $apiToken',
              'Accept': 'application/json',
              
            });

            if (locResponse.statusCode == 200) {
              final locResult = json.decode(locResponse.body);
              final locData = locResult['data'];
              if (locData != null) {
                final lat = double.tryParse(locData['latitude'].toString());
                final lng = double.tryParse(locData['longitude'].toString());
                if (lat != null && lng != null) {
                  riderLoc = LatLng(lat, lng);
                }
              }
            }
          } catch (e) {
            debugPrint("Pre-fetch location error: $e");
          }
          
          if (mounted && !_isDisposed) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.professionalAssigned,
              arguments: {
                'service': widget.service,
                'booking_data': data,
                'price': widget.price,
                'initial_user_location': userLoc,
                'initial_rider_location': riderLoc,
                'status': BookingStatusModel(
                  currentState: BookingState.onTheWay,
                  professional: ProfessionalMatch(
                    name: (bookingDetail['handyman_name'] ?? bookingDetail['provider_name']) ?? "Professional",
                    rating: (bookingDetail['total_rating'] ?? 4.5).toDouble(),
                    jobsDone: bookingDetail['total_review'] ?? 50,
                    avatarUrl: "lib/assets/images/rider_image.png", // Fallback
                  ),
                  appointmentTime: bookingDetail['booking_slot'] ?? "11:00 AM",
                  appointmentDate: bookingDetail['booking_date'] ?? "26 March, 2026",
                ),
              },
            );
          }
        }
      } else {
        debugPrint("Polling failed with status: ${response.statusCode}");
        debugPrint("Full Error Response: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching booking details: $e");
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _rippleController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
       canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _handleBack,
          ),
          title: const Text(
            "Finding a Professional",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Hero Illustrations (Clipped circles)
              _buildHeroImages(),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "We’re finding the best professional for you",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Searching...",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const Text(
                "Usually within 2~5 minutes",
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 40),
              // Timeline Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimelineIcons(),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTimelineContent()),
                  ],
                ),
              ),
              const Divider(thickness: 4, color: Color(0xFFEEEEEE), height: 80),
              // Service Details Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildServiceInfo(),
              ),
              const SizedBox(height: 48),
              // Action Buttons
              _buildActionButtons(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImages() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildClippedImage("lib/assets/images/worker_1.png"),
        const SizedBox(width: 12),
        _buildClippedImage("lib/assets/images/worker_2.png"),
      ],
    );
  }

  Widget _buildClippedImage(String path) {
    return Container(
      width: 160,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(80),
        image: DecorationImage(
          image: AssetImage(path),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTimelineIcons() {
    return Column(
      children: [
        // Step 1: Searching
        _SearchingRippleIcon(
          controller: _rippleController, 
          isGreen: _isSearchingDone, 
          activeIcon: Icons.sensors
        ),
        Container(
          width: 2,
          height: 60,
          color: Colors.black12,
        ),
        // Step 2: Waiting for acceptance
        _SearchingRippleIcon(
          controller: _rippleController, 
          isGreen: _isAccepted, 
          activeIcon: Icons.sync,
          shouldRotate: !_isAccepted, // Rotate when waiting
        ),
      ],
    );
  }

  Widget _buildTimelineContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step 1: Searching
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isSearchingDone ? const Color(0xFFE8F5E9) : const Color(0xFFFEDC85), 
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Searching for professionals",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              SizedBox(height: 4),
              Text(
                "We are matching you with nearby experts...",
                style: TextStyle(fontSize: 11, color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Step 2: Waiting for acceptance
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isAccepted ? const Color(0xFFE8F5E9) : const Color(0xFFFEDC85), // Green if accepted, else Yellow
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Waiting for acceptance",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                "Live tracking will start automatically, once professional accepts.",
                style: TextStyle(fontSize: 11, color: _isAccepted ? Colors.black87 : Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceInfo() {
    String title = "Service";
    String? imageUrl;
    bool isNetwork = false;

    if (widget.service == null) {
       title = "Service";
    } else if (widget.service is ServiceData) {
      final sd = widget.service as ServiceData;
      title = sd.name ?? "Service";
      
      // Use attachments if available, otherwise fallback to provider image
      if (sd.attachments != null && sd.attachments!.isNotEmpty) {
        imageUrl = sd.attachments!.first;
      } else if (sd.attachmentsArray != null && sd.attachmentsArray!.isNotEmpty) {
        imageUrl = sd.attachmentsArray!.first.url;
      } else {
        imageUrl = sd.providerImage;
      }
    } else if (widget.service is Map) {
      final map = widget.service as Map;
      title = map['name']?.toString() ?? map['title']?.toString() ?? "Service";
      
      // Extract from attachments if available
      final attachments = map['attchments'] as List?;
      if (attachments != null && attachments.isNotEmpty) {
        imageUrl = attachments[0].toString();
      } else {
        imageUrl = map['image']?.toString() ?? map['profile_image']?.toString() ?? map['avatar_url']?.toString();
      }
    } else {
      try {
        // Handle generic objects with dynamic access
        title = (widget.service as dynamic).title?.toString() ?? 
                (widget.service as dynamic).name?.toString() ?? "Service";
        imageUrl = (widget.service as dynamic).image?.toString() ?? 
                   (widget.service as dynamic).profileImage?.toString();
      } catch (_) {
        title = "Service";
      }
    }

    if (imageUrl != null && imageUrl.startsWith('http')) {
      isNetwork = true;
    }

    imageUrl ??= UserMessages.serviceBookingDummy1;

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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${widget.date ?? "26 March, 2026"} ~ ${widget.time ?? "10:30 AM"}",
                    style: const TextStyle(
                      fontSize: 13, 
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isNetwork 
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: 100,
                    height: 70,
                    fit: BoxFit.cover,
                    httpHeaders: const {},
                    placeholder: (context, url) => Container(color: Colors.grey[200], width: 100, height: 70),
                    errorWidget: (context, url, error) => Image.asset(UserMessages.serviceBookingDummy1, width: 100, height: 70, fit: BoxFit.cover),
                  )
                : Image.asset(
                    imageUrl, 
                    width: 100, 
                    height: 75, 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(UserMessages.serviceBookingDummy1, width: 100, height: 75, fit: BoxFit.cover),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: _isCancelling ? null : _cancelBooking,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _isCancelling 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text(
                      "Cancel Booking",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchingRippleIcon extends StatelessWidget {
  final Animation<double> controller;
  final bool isGreen;
  final IconData activeIcon;
  final bool shouldRotate;

  const _SearchingRippleIcon({
    required this.controller, 
    this.isGreen = false,
    required this.activeIcon,
    this.shouldRotate = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isGreen ? Colors.green : Colors.orange;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildRipple(baseColor, 1.0, controller.value),
              _buildRipple(baseColor, 0.6, (controller.value + 0.5) % 1.0),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isGreen ? const Color(0xFFC8E6C9) : const Color(0xFFFEDC85),
                  shape: BoxShape.circle,
                  border: Border.all(color: baseColor.withOpacity(0.5), width: 2),
                ),
                child: Transform.rotate(
                  angle: shouldRotate ? (controller.value * 2 * 3.14159) : 0,
                  child: Icon(
                    isGreen ? Icons.check : activeIcon, 
                    color: isGreen ? Colors.green[800] : Colors.black, 
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRipple(Color color, double opacityFactor, double progress) {
    return Container(
      width: 40 + (30 * progress),
      height: 40 + (30 * progress),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity((1.0 - progress) * 0.4 * opacityFactor),
      ),
    );
  }
}
