import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zeerah/core/config/api_config.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zeerah/screens/handyman%20services/bookings/bookig_sevice_progress_home.dart';

class ServiceVerificationScreen extends StatefulWidget {
  final dynamic service;
  final BookingStatusModel bookingStatus;
  final dynamic bookingData;
  final String? price;

  const ServiceVerificationScreen({
    required this.service,
    required this.bookingStatus,
    this.bookingData,
    this.price,
    super.key,
  });

  @override
  State<ServiceVerificationScreen> createState() => _ServiceVerificationScreenState();
}

class _ServiceVerificationScreenState extends State<ServiceVerificationScreen> {
  Timer? _statusPollingTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _statusPollingTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isDisposed) {
        _checkBookingStatus();
      }
    });
  }

  Future<void> _checkBookingStatus() async {
    String? bookingId;
    if (widget.bookingData != null) {
      final bData = widget.bookingData is List ? (widget.bookingData as List).first : widget.bookingData;
      bookingId = bData['booking_detail']?['id']?.toString() ?? 
                  bData['id']?.toString();
    }
    
    if (bookingId == null) return;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.apiToken;
      final url = Uri.parse('${ApiConfig.apiBaseUrl}/booking-detail?booking_id=$bookingId');
      
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $apiToken',
        'Accept': 'application/json',
        
      });

      if (response.statusCode == 200) {
        final rawData = json.decode(response.body);
        final data = rawData is List ? (rawData.isNotEmpty ? rawData.first : {}) : rawData;
        final rawStatus = (data['booking_detail']?['status'] ?? data['status'])?.toString() ?? "";
        final currentStatus = rawStatus.trim().toLowerCase();
        
        debugPrint("ServiceVerification Polling Status: $currentStatus");
        
        // Redirection logic: triggered by 'started' or 'in_progress' status
        if (currentStatus == 'started' || currentStatus == 'in_progress') {
           _statusPollingTimer?.cancel();
           if (mounted) {
             final userProvider = Provider.of<UserProvider>(context, listen: false);
             final now = DateTime.now();
             userProvider.setServiceStartTime(now);
             
             Navigator.pushReplacementNamed(
               context,
               AppRoutes.serviceInProgress,
               arguments: {
                 'service': widget.service,
                 'booking_data': data,
                 'price': widget.price,
                 'duration': 0, // Starts fresh
                 'start_time': now,
               },
             );
           }
        }
      }
    } catch (e) {
      debugPrint("Error in ServiceVerification polling: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Extract all rider data directly from the booking API response ──
    final bData = widget.bookingData is List
        ? (widget.bookingData as List).first
        : widget.bookingData;

    final rawProvider = bData?['provider_data'];
    final provider = rawProvider is List
        ? (rawProvider.isNotEmpty ? rawProvider.first : {})
        : (rawProvider ?? {});

    final rawService = bData?['service'];
    final service = rawService is List
        ? (rawService.isNotEmpty ? rawService.first : {})
        : (rawService ?? {});

    final rawDetail = bData?['booking_detail'];
    final detail = rawDetail is List
        ? (rawDetail.isNotEmpty ? rawDetail.first : {})
        : (rawDetail ?? {});

    final rawHandyman = bData?['handyman_data'];
    final handyman = rawHandyman is List
        ? (rawHandyman.isNotEmpty ? rawHandyman.first : {})
        : (rawHandyman ?? {});

    // Build ProfessionalMatch from live API data only — no dummy fallback
    final ProfessionalMatch pro = ProfessionalMatch(
      name: handyman['display_name']?.toString() ??
            provider['display_name']?.toString() ??
            detail['provider_name']?.toString() ??
            "Professional",
      rating: (handyman['handyman_rating'] ??
               provider['providers_service_rating'] ??
               provider['handyman_rating'] ?? 0).toDouble(),
      jobsDone: (handyman['total_services_booked'] ??
                 provider['total_services_booked'] ?? 0) as int,
      avatarUrl: handyman['profile_image']?.toString() ??
                 service['provider_image']?.toString() ??
                 provider['profile_image']?.toString() ??
                 "lib/assets/images/rider_image.png",
    );
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Arrived",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildOTPSection(),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildProProfile(pro),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildContactActions(),
            ),
            const Divider(thickness: 4, color: Color(0xFFEEEEEE), height: 80),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildServiceDetails(),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildActionButtonRow(),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtonRow() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.helpDesk),
            child: _buildFooterButton(Icons.support_agent, "Contact Support", Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButton(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceProgress() {
    final steps = widget.bookingStatus.steps ?? [
      const ProgressStepModel(title: "Booking confirmed", subtitle: "", state: BookingState.assigned),
      const ProgressStepModel(title: "Professional Assigned", subtitle: "", state: BookingState.assigned),
      const ProgressStepModel(title: "On the Way", subtitle: "", state: BookingState.onTheWay),
      const ProgressStepModel(title: "Professional Arrived", subtitle: "Rider reached its destination", state: BookingState.completed),
      const ProgressStepModel(title: "Service Started", subtitle: "", state: BookingState.started),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Service Progress",
          style: TextStyle(color: Color(0xFFD90000), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 20),
        ...List.generate(steps.length, (index) {
          final step = steps[index];
          // In this screen, we assume reached, so everything up to "Arrived" is done
          final bool isCompleted = index <= 3; 
          final bool isActive = index == 3;
          
          return _buildProgressStep(
            step.title, 
            subtitle: step.subtitle,
            isCompleted: isCompleted, 
            isActive: isActive,
            isLast: index == steps.length - 1
          );
        }),
      ],
    );
  }

  Widget _buildProgressStep(String title, {required String subtitle, required bool isCompleted, bool isActive = false, required bool isLast}) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? const Color(0xFFFFD9CC) : Colors.white,
                border: Border.all(color: isCompleted ? Colors.transparent : Colors.black26),
              ),
              child: Icon(
                isActive ? Icons.sensors : (isCompleted ? Icons.check : null),
                size: 14,
                color: isActive ? Colors.orange : (isCompleted ? Colors.orange : Colors.transparent),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isCompleted ? const Color(0xFFFFD9CC) : Colors.black12,
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
                color: isCompleted ? const Color(0xFFFFE082).withOpacity(0.8) : Colors.white,
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
                            color: isCompleted ? Colors.black : Colors.black54,
                          ),
                        ),
                        if (isActive && subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: const TextStyle(fontSize: 10, color: Colors.black54),
                          ),
                      ],
                    ),
                  ),
                  if (isActive) const Icon(Icons.sensors, color: Color(0xFFD90000), size: 16),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOTPSection() {
    return Column(
      children: [
        Image.asset(
          'lib/assets/images/handsman.png',
          height: 180,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 12),
        const Column(
          children: [
            Text(
              "Handyman has",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54),
            ),
            Text(
              "ARRIVED",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD54F), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                "Service OTP",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            String otpStr = "0000";
            if (widget.bookingData != null) {
              final bData = widget.bookingData is List ? (widget.bookingData as List).first : widget.bookingData;
              final detail = bData['booking_detail'];
              if (detail != null) {
                otpStr = (detail['otp'] ?? detail['service_otp'] ?? detail['booking_otp'])?.toString() ?? "0000";
              } else {
                otpStr = (bData['otp'] ?? bData['service_otp'])?.toString() ?? "0000";
              }
            }
            // If OTP is less than 4 digits, pad it
            otpStr = otpStr.padRight(4, '0');
            final List<String> otpChars = otpStr.split('');
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 54,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD54F).withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                otpChars[index],
                style: const TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFFD90000),
                ),
              ),
            );
          }),
        ),
              const SizedBox(height: 20),
              const Text(
                "Share this OTP with the professional to start the service",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProProfile(ProfessionalMatch pro) {
    // Extract live data from API response
    final bData = widget.bookingData is List
        ? (widget.bookingData as List).first
        : widget.bookingData;
    
    final rawHandyman = bData?['handyman_data'];
    final handyman = rawHandyman is List
        ? (rawHandyman.isNotEmpty ? rawHandyman.first : {})
        : (rawHandyman ?? {});

    final rawProvider = bData?['provider_data'];
    final provider = rawProvider is List
        ? (rawProvider.isNotEmpty ? rawProvider.first : {})
        : (rawProvider ?? {});

    final rawService = bData?['service'];
    final service = rawService is List
        ? (rawService.isNotEmpty ? rawService.first : {})
        : (rawService ?? {});

    final String name = handyman['display_name']?.toString() ??
        provider['display_name']?.toString() ??
        bData?['booking_detail']?['provider_name']?.toString() ??
        pro.name;
    final double rating = (handyman['handyman_rating'] ??
            provider['providers_service_rating'] ??
            provider['handyman_rating'] ??
            pro.rating)
        .toDouble();
    final int jobsDone = (handyman['total_services_booked'] ??
            provider['total_services_booked'] ??
            pro.jobsDone) as int;
    final String? imgUrl =
        handyman['profile_image'] ?? service['provider_image'] ?? provider['profile_image'];

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: (imgUrl != null && imgUrl.startsWith('http'))
              ? CachedNetworkImage(
                  imageUrl: imgUrl,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  httpHeaders: const {},
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => Image.asset(
                      'lib/assets/images/rider_image.png',
                      fit: BoxFit.cover),
                )
              : Image.asset(
                  'lib/assets/images/rider_image.png',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
        ),
        const SizedBox(width: 16),
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
                          fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Arrived",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFB300), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "4.2",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "($jobsDone jobs done)",
                    style: const TextStyle(
                        color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Professional is at your door",
                style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
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
              final bData = widget.bookingData is List ? (widget.bookingData as List).first : widget.bookingData;
              
              final rawHandyman = bData?['handyman_data'];
              final handyman = rawHandyman is List ? (rawHandyman.isNotEmpty ? rawHandyman.first : {}) : rawHandyman;
              
              final rawProvider = bData?['provider_data'];
              final provider = rawProvider is List ? (rawProvider.isNotEmpty ? rawProvider.first : null) : rawProvider;
              
              final phone = (handyman?['contact_number'] ?? provider?['contact_number'])?.toString()?.replaceAll(' ', '');
              
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
              final bData = widget.bookingData is List ? (widget.bookingData as List).first : widget.bookingData;
              
              final rawHandyman = bData?['handyman_data'];
              final handyman = rawHandyman is List ? (rawHandyman.isNotEmpty ? rawHandyman.first : {}) : rawHandyman;
              
              final rawProvider = bData?['provider_data'];
              final provider = rawProvider is List ? (rawProvider.isNotEmpty ? rawProvider.first : null) : rawProvider;
              
              final rawDetail = bData?['booking_detail'];
              final detail = rawDetail is List ? (rawDetail.isNotEmpty ? rawDetail.first : {}) : rawDetail;
              
              final rawService = bData?['service'];
              final service = rawService is List ? (rawService.isNotEmpty ? rawService.first : {}) : rawService;

              Navigator.pushNamed(
                context, 
                AppRoutes.chatHomeScreen,
                arguments: {
                  'name': handyman?['display_name'] ?? provider?['display_name'] ?? detail?['provider_name'] ?? "Professional",
                  'image': handyman?['profile_image'] ?? service?['provider_image'] ?? provider?['profile_image'] ?? "lib/assets/images/rider_image.png",
                  'phone': (handyman?['contact_number'] ?? provider?['contact_number'])?.toString(),
                  'booking_id': detail?['id']?.toString(),
                  'provider_uid': handyman?['uid']?.toString() ?? provider?['uid']?.toString(),
                  'handyman_uid': handyman?['uid']?.toString() ?? provider?['uid']?.toString(),
                  'handyman_id': handyman?['uid']?.toString() ?? 
                                 provider?['uid']?.toString() ??
                                 handyman?['id']?.toString() ?? 
                                 provider?['id']?.toString() ?? 
                                 detail?['provider_id']?.toString(),
                },
              );
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
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetails() {
    String title = "Service";
    String? imageUrl;
    bool isNetwork = false;

    final bData = widget.bookingData is List ? (widget.bookingData as List).first : widget.bookingData;
    if (bData != null && bData['booking_detail'] != null) {
      title = bData['booking_detail']['service_name'] ?? "Service";
      final rawService = bData['service'];
      final service = rawService is List ? (rawService.isNotEmpty ? rawService.first : null) : rawService;
      final attachments = service?['attchments_array'];
      if (attachments != null && attachments is List && attachments.isNotEmpty) {
        imageUrl = attachments[0]['url'];
        isNetwork = true;
      }
    } else if (widget.service is ServiceData) {
      final sd = widget.service as ServiceData;
      title = sd.name ?? "Service";
      imageUrl = sd.providerImage;
      if (imageUrl != null && imageUrl.startsWith('http')) isNetwork = true;
    } else if (widget.service != null) {
      try {
        title = widget.service.title ?? "Service";
        imageUrl = widget.service.image;
        if (imageUrl != null && imageUrl.startsWith('http')) isNetwork = true;
      } catch (_) {}
    }

    imageUrl ??= UserMessages.serviceBookingDummy1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Service Details",
          style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 16),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${widget.bookingStatus.appointmentDate} ~ ${widget.bookingStatus.appointmentTime}",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
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
                    height: 70, 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(UserMessages.serviceBookingDummy1, width: 100, height: 70, fit: BoxFit.cover),
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
