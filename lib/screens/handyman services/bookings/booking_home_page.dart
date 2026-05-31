import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/config/api_config.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/screens/handyman%20services/bookings/select_date.dart';
import 'package:zeerah/screens/handyman%20services/bookings/service_type.dart';
import 'package:zeerah/screens/handyman%20services/bookings/price_details.dart';
import 'package:zeerah/screens/handyman%20services/bookings/service_progress_widget.dart';

class BookingHomePage extends StatefulWidget {
  final dynamic service;
  final double totalAmount;
  final double discountAmount;
  final double discountPercent;
  final double fullAmount;
  final Map<String, dynamic>? selectedOption;
  final List<Map<String, dynamic>> selectedAddOns;

  const BookingHomePage({
    required this.service,
    this.totalAmount = 0.0,
    this.discountAmount = 0.0,
    this.fullAmount = 0.0,
    this.discountPercent = 0.0,
    this.selectedOption,
    this.selectedAddOns = const [],
    super.key,
  });

  @override
  State<BookingHomePage> createState() => _BookingHomePageState();
}

class _BookingHomePageState extends State<BookingHomePage> {
  bool _isSubmitting = false;
  DateTime? _selectedDate;
  String? _selectedTime;

  Map<String, dynamic>? _activeBooking;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _fetchLatestStatus();
    });
    _fetchLatestStatus();
  }

  Future<void> _fetchLatestStatus() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.apiToken;
      if (apiToken == null) return;

      // For demo purposes, we are using ID 18 from your JSON example if no other ID is known.
      // In a real flow, this would be passed from the previous screen or fetched from an 'active-bookings' list.
      String bookingId = "18";

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

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && mounted) {
          final rawData = data is List
              ? (data.isNotEmpty ? data.first : {})
              : data;
          setState(() {
            _activeBooking = rawData;
          });

          final detail = rawData['booking_detail'];
          final bookingDetail = detail is List
              ? (detail.isNotEmpty ? detail.first : {})
              : detail;
          final status = bookingDetail?['status']?.toString().toLowerCase();

          // Auto-navigate if status is in progress or pending approval
          if (status == 'in_progress' ||
              status == 'pending_approval' ||
              status == 'arrived') {
            _navigateToProgress(data);
          }
        }
      }
    } catch (e) {
      debugPrint("Error polling status on home: $e");
    }
  }

  void _navigateToProgress(dynamic data) {
    if (mounted) {
      // Stop polling here to prevent multiple navigations
      _statusTimer?.cancel();

      final now = DateTime.now();
      final bData = data is List ? (data.isNotEmpty ? data.first : {}) : data;
      final rawDetail = bData['booking_detail'];
      final bookingDetail = rawDetail is List
          ? (rawDetail.isNotEmpty ? rawDetail.first : {})
          : rawDetail;
      final status = bookingDetail?['status']?.toString().toLowerCase();
      if (status == 'pending_approval' || status == 'completed') {
        Provider.of<UserProvider>(
          context,
          listen: false,
        ).setServiceEndTime(now);
      }

      Navigator.pushNamed(
        context,
        AppRoutes.serviceInProgress,
        arguments: {
          'booking_data': data,
          'duration': 0,
          'completion_time': now,
        },
      );
    }
  }

  String _getServiceName() {
    try {
      if (widget.service.runtimeType.toString() == 'ServiceData') {
        return widget.service.name ?? 'Service';
      }
      return widget.service.title ?? 'Service';
    } catch (_) {
      try {
        return widget.service.name ?? 'Service';
      } catch (_) {
        return 'Service';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.naturalWhite,
      appBar: AppBar(
        titleSpacing: 0,
        toolbarHeight: AppSizes.h(context, 80),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Padding(
          padding: EdgeInsets.only(top: AppSizes.h(context, 10)),
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.naturalBlack,
            ),
          ),
        ),
        backgroundColor: AppColors.naturalWhite,
        title: Padding(
          padding: EdgeInsets.only(top: AppSizes.h(context, 10)),
          child: Text(
            "${_getServiceName()}",
            style: TextStyle(
              color: AppColors.naturalBlack,
              fontWeight: FontWeight.w600,
              fontSize: AppSizes.w(context, 19),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ServiceType(
                      service: widget.service,
                      selectedOption: widget.selectedOption,
                      selectedAddOns: widget.selectedAddOns,
                    ),
                    SelectDate(
                      onDateSelected: (date) {
                        setState(() => _selectedDate = date);
                      },
                      onTimeSelected: (slot, time) {
                        setState(() => _selectedTime = time);
                      },
                    ),
                    PriceDetails(
                      totalAmount: widget.totalAmount,
                      discountAmount: widget.discountAmount,
                      discountPercent: widget.discountPercent,
                      fullAmount: widget.fullAmount,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: AppColors.naturalWhite,
              padding: EdgeInsets.fromLTRB(
                Insets.sm,
                Insets.xsm,
                Insets.sm,
                Insets.sm,
              ),
              child: SizedBox(
                width: double.infinity,
                height: AppSizes.h(context, 52),
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          setState(() => _isSubmitting = true);

                          try {
                            final addressProvider = context
                                .read<AddressProvider>();

                            // FETCH ADDRESS LIST
                            await addressProvider.fetchAddressesFromBackend();

                            // CHECK IF ADDRESS EMPTY
                            if (addressProvider.savedAddresses.isEmpty) {
                              setState(() => _isSubmitting = false);

                              showDialog(
                                context: context,
                                barrierDismissible:
                                    false, // Prevents dismissing by tapping outside
                                builder: (context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).scaffoldBackgroundColor,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Top decorative element
                                          Container(
                                            height: 4,
                                            width: 60,
                                            margin: const EdgeInsets.only(
                                              top: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),

                                          // Icon
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 24,
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryRed
                                                  .withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.location_on_outlined,
                                              color: AppColors.primaryRed,
                                              size: 40,
                                            ),
                                          ),

                                          // Title
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              24,
                                              20,
                                              24,
                                              8,
                                            ),
                                            child: Text(
                                              "Address Required",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                                color: Theme.of(
                                                  context,
                                                ).textTheme.titleLarge?.color,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),

                                          // Message
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              24,
                                              0,
                                              24,
                                              24,
                                            ),
                                            child: Text(
                                              "Please add your address before proceeding with the booking.",
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color
                                                    ?.withOpacity(0.7),
                                                height: 1.4,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),

                                          // Buttons
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              20,
                                              0,
                                              20,
                                              20,
                                            ),
                                            child: Row(
                                              children: [
                                                // Cancel Button
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.grey[600],
                                                      side: BorderSide(
                                                        color:
                                                            Colors.grey[300]!,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      "Cancel",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),

                                                // Add Address Button
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      Navigator.pushNamed(
                                                        context,
                                                        AppRoutes
                                                            .selectLocation,
                                                      );
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          AppColors.primaryRed,
                                                      foregroundColor:
                                                          Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                      elevation: 0,
                                                    ),
                                                    child: const Text(
                                                      "Add Address",
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );

                              return;
                            }

                            // CONTINUE BOOKING
                            final location = addressProvider.selectedLocation;

                            // Using user-provided example coordinates as defaults if location is null
                            final double lat = location?['latitude'] != null
                                ? double.parse(location!['latitude'].toString())
                                : 28.6155;
                            final double lng = location?['longitude'] != null
                                ? double.parse(
                                    location!['longitude'].toString(),
                                  )
                                : 77.2150;
                            final String addressText =
                                location?['address'] ?? "test address";

                            debugPrint(
                              "📍 Booking Flow: Using coordinates from selected address",
                            );
                            debugPrint("📍 Address: $addressText");
                            debugPrint("📍 Latitude: $lat");
                            debugPrint("📍 Longitude: $lng");

                            final userProvider = context.read<UserProvider>();
                            final apiToken = userProvider.apiToken;

                            String dateStr = "2026-05-01";
                            String formattedDisplayDate = "01 May, 2026";
                            if (_selectedDate != null) {
                              dateStr =
                                  "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
                              final monthNames = [
                                "Jan",
                                "Feb",
                                "Mar",
                                "Apr",
                                "May",
                                "Jun",
                                "Jul",
                                "Aug",
                                "Sep",
                                "Oct",
                                "Nov",
                                "Dec",
                              ];
                              formattedDisplayDate =
                                  "${_selectedDate!.day} ${monthNames[_selectedDate!.month - 1]}, ${_selectedDate!.year}";
                            }

                            // Convert display time (e.g. "8:00 AM") to 24-hour API format "HH:mm:ss"
                            String _convertTo24Hour(String displayTime) {
                              try {
                                final parts = displayTime.split(' ');
                                final timeParts = parts[0].split(':');
                                int hour = int.parse(timeParts[0]);
                                final minute = timeParts.length > 1
                                    ? timeParts[1]
                                    : '00';
                                final period = parts.length > 1
                                    ? parts[1].toUpperCase()
                                    : 'AM';
                                if (period == 'PM' && hour != 12) hour += 12;
                                if (period == 'AM' && hour == 12) hour = 0;
                                return '${hour.toString().padLeft(2, '0')}:${minute.padLeft(2, '0')}:00';
                              } catch (_) {
                                return '10:30:00';
                              }
                            }

                            final displayTime = _selectedTime ?? "10:30 AM";
                            final timeStr = _convertTo24Hour(displayTime);
                 final latestDisplayTime =
    DateFormat('h:mm a').format(DateTime.now());

final latestTime =
    _convertTo24Hour(latestDisplayTime);

                            final url = Uri.parse(
                              '${ApiConfig.apiBaseUrl}/booking-save',
                            );
                            final requestBody = {
                              "service_id": widget.service is Map
                                  ? widget.service['id']
                                  : widget.service.id,
                              "date": dateStr,
                              "booking_slot": latestTime,
                              "address": addressText,
                              "latitude": lat,
                              "longitude": lng,
                              "status": "pending",
                              "price": widget.totalAmount,
                              "total_amount": widget.totalAmount,
                              "service_addon_id": widget.selectedAddOns
                                  .map((e) => e['id'])
                                  .toList(),
                              "service_option_id": widget.selectedOption != null
                                  ? [widget.selectedOption!['id']]
                                  : [],
                            };

                            debugPrint("🚀 OUTGOING BOOKING PAYLOAD:");
                            debugPrint(
                              const JsonEncoder.withIndent(
                                '  ',
                              ).convert(requestBody),
                            );

                            final response = await http.post(
                              url,
                              headers: {
                                'Content-Type': 'application/json',
                                'Accept': 'application/json',

                                if (apiToken != null && apiToken.isNotEmpty)
                                  'Authorization': 'Bearer $apiToken',
                              },
                              body: json.encode(requestBody),
                            );

                            if (response.statusCode == 200) {
                              final data = json.decode(response.body);
                              final bookingId =
                                  data['booking_id']?.toString() ?? "#UC876-67";

                              if (mounted) {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.bookingConfirmed,
                                  arguments: {
                                    'service': widget.service,
                                    'booking_id': bookingId,
                                    'date': formattedDisplayDate,
                                    'time': timeStr,
                                    'price': widget.totalAmount.toStringAsFixed(
                                      2,
                                    ),
                                  },
                                );
                              }
                            } else {
                              debugPrint("Booking failed: ${response.body}");
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "API Error: ${response.statusCode} - ${response.body}",
                                    ),
                                    duration: const Duration(seconds: 5),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            debugPrint("Error confirming booking: $e");
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "An error occurred. Please check your connection.",
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isSubmitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSubmitting
                        ? Colors.grey
                        : AppColors.primaryRed,
                    foregroundColor: AppColors.naturalWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Insets.sm),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: AppSizes.w(context, 16),
                            fontWeight: FontWeight.w600,
                            color: AppColors.naturalWhite,
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

  Widget _buildActiveBookingCard() {
    final bData = _activeBooking is List
        ? (_activeBooking as List).first
        : _activeBooking;
    final rawDetail = bData?['booking_detail'];
    final detail = rawDetail is List
        ? (rawDetail.isNotEmpty ? rawDetail.first : {})
        : rawDetail;

    final rawProvider = bData?['provider_data'];
    final provider = rawProvider is List
        ? (rawProvider.isNotEmpty ? rawProvider.first : {})
        : rawProvider;

    final rawService = bData?['service'];
    final service = rawService is List
        ? (rawService.isNotEmpty ? rawService.first : {})
        : rawService;

    final status =
        (detail?['status'] ?? bData?['status'])?.toString().toUpperCase() ??
        "PENDING";
    final providerName = provider?['display_name'] ?? "Handyman";
    final providerImage =
        service?['provider_image'] ?? provider?['profile_image'];

    return Container(
      margin: EdgeInsets.all(Insets.sm),
      padding: EdgeInsets.all(Insets.sm),
      decoration: BoxDecoration(
        color: AppColors.naturalWhite,
        borderRadius: BorderRadius.circular(Insets.sm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage:
                    (providerImage != null &&
                        providerImage.toString().startsWith('http'))
                    ? NetworkImage(providerImage, headers: const {})
                    : null,
                child: (providerImage == null)
                    ? const Icon(Icons.person)
                    : null,
              ),
              SizedBox(width: Insets.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      providerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFB300),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (provider?['providers_service_rating'] ??
                                  provider?['handyman_rating'] ??
                                  0)
                              .toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "(${provider?['total_services_booked'] ?? 0} jobs done)",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Status: ${status == 'PENDING_APPROVAL'
                          ? 'Pending Approval'
                          : status == 'IN_PROGRESS'
                          ? 'In Progress'
                          : status == 'COMPLETED'
                          ? 'Completed'
                          : status.isNotEmpty
                          ? status[0].toUpperCase() + status.substring(1).toLowerCase()
                          : status}",
                      style: TextStyle(
                        color:
                            (status == 'PENDING_APPROVAL' ||
                                status == 'IN_PROGRESS' ||
                                status == 'COMPLETED')
                            ? AppColors.completedBlue
                            : AppColors.primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    if (status == 'IN_PROGRESS' || status == 'STARTED')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Consumer<UserProvider>(
                          builder: (context, userProvider, _) {
                            final startTime = userProvider.serviceStartTime;
                            final elapsed = userProvider.elapsedSeconds;
                            final isPaused = userProvider.isServicePaused;

                            if (startTime == null) return const SizedBox();

                            String formatDuration(int seconds) {
                              int h = seconds ~/ 3600;
                              int m = (seconds % 3600) ~/ 60;
                              int s = seconds % 60;
                              return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPaused
                                      ? "Paused"
                                      : "In Progress: ${formatDuration(elapsed)}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isPaused
                                        ? Colors.orange
                                        : AppColors.primaryRed,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Started at ${DateFormat('hh:mm a').format(startTime)}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          ServiceProgressWidget(
            currentStep: () {
              switch (status) {
                case 'COMPLETED':
                  return 5;
                case 'PENDING_APPROVAL':
                  return 4;
                case 'IN_PROGRESS':
                  return 3;
                case 'STARTED':
                  return 3;
                case 'ARRIVED':
                  return 2;
                case 'ONGOING':
                  return 2;
                case 'ACCEPT':
                  return 1;
                default:
                  return 0;
              }
            }(),
          ),
          if (status == 'PENDING_APPROVAL' ||
              status == 'IN_PROGRESS' ||
              status == 'COMPLETED')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final bData = _activeBooking is List
                            ? (_activeBooking as List).first
                            : _activeBooking;

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
                            final Uri url = Uri(scheme: 'tel', path: phone);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              // Fallback if canLaunchUrl fails but we still want to try
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          } catch (e) {
                            debugPrint('Could not launch call: $e');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.call, color: Colors.black, size: 16),
                          SizedBox(width: 4),
                          Text(
                            "Call",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final now = DateTime.now();
                        if (status == 'COMPLETED' ||
                            status == 'PENDING_APPROVAL') {
                          Provider.of<UserProvider>(
                            context,
                            listen: false,
                          ).setServiceEndTime(now);
                        }
                        Navigator.pushNamed(
                          context,
                          AppRoutes.serviceInProgress,
                          arguments: {
                            'booking_data': _activeBooking,
                            'duration': 0,
                            'completion_time': now,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.completedBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        "View Progress",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
