import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/config/api_config.dart';
import 'package:zeerah/core/models/booking_model.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/services/booking_service.dart';
import 'package:zeerah/screens/handyman%20services/bookings/bookig_sevice_progress_home.dart';
import 'package:zeerah/widgets/custom/fade_animation_text.dart';

class BookingHistory extends StatefulWidget {
  BookingHistory({super.key});

  @override
  State<BookingHistory> createState() => _BookingHistoryState();
}

class _BookingHistoryState extends State<BookingHistory> {
  final BookingService _bookingService = BookingService();
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final response = await _bookingService.fetchBookingList(
      token: userProvider.apiToken,
    );

    if (mounted) {
      setState(() {
        final List<dynamic> rawBookings = response['data'] ?? [];
        // Show all bookings including active ones so users can resume them
        _bookings = rawBookings.toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToPayment(BuildContext context, Map item) async {
    final bookingId = item['id']?.toString();

    if (bookingId == null) return;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final url = Uri.parse(
        '${ApiConfig.apiBaseUrl}/booking-detail?booking_id=$bookingId',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${userProvider.apiToken}',
        },
      );

      Map<dynamic, dynamic> data = item;

      if (response.statusCode == 200) {
        final raw = json.decode(response.body);

        data = raw is List
            ? Map<String, dynamic>.from(raw.first)
            : Map<String, dynamic>.from(raw);
      }

      Navigator.pushNamed(
        context,
        AppRoutes.paymentsHome,
        arguments: {
          'booking_data': data,
          'price':
              item['total_amount']?.toString() ?? item['price']?.toString(),
        },
      );
    } catch (e) {
      debugPrint("Payment navigation error: $e");
    }
  }

  Future<void> _navigateToRatingScreen(BuildContext context, Map item) async {
    final bookingId = item['id']?.toString();

    if (bookingId == null) return;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final url = Uri.parse(
        '${ApiConfig.apiBaseUrl}/booking-detail?booking_id=$bookingId',
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${userProvider.apiToken}',
        },
      );

      Map<dynamic, dynamic> data = item;

      if (response.statusCode == 200) {
        final raw = json.decode(response.body);

        data = raw is List
            ? Map<String, dynamic>.from(raw.first)
            : Map<String, dynamic>.from(raw);
      }

      // Extract booking detail
      final rawDetail = data['booking_detail'];
      final detail = rawDetail is List
          ? (rawDetail.isNotEmpty ? rawDetail.first : {})
          : (rawDetail ?? {});

      // Extract handyman
      final rawHandyman = data['handyman_data'];
      final handyman = rawHandyman is List
          ? (rawHandyman.isNotEmpty ? rawHandyman.first : {})
          : (rawHandyman ?? {});

      // Extract provider
      final rawProvider = data['provider_data'];
      final provider = rawProvider is List
          ? (rawProvider.isNotEmpty ? rawProvider.first : {})
          : (rawProvider ?? {});

      // Extract service
      final rawService = data['service'];
      final service = rawService is List
          ? (rawService.isNotEmpty ? rawService.first : {})
          : (rawService ?? {});

      Navigator.pushNamed(
        context,
        AppRoutes.ratingsAndReview,
        arguments: {
          'booking_data': data,
          'booking_id': bookingId,
          'detail': detail,
          'handyman': handyman,
          'provider': provider,
          'service': service,
          'service_name':
              detail['service_name'] ?? service['name'] ?? item['service_name'],
          'handyman_id': handyman['id'] ?? provider['id'],
          'handyman_name':
              handyman['display_name'] ??
              handyman['first_name'] ??
              provider['display_name'] ??
              'Service Provider',
          'handyman_image':
              handyman['profile_image'] ?? provider['profile_image'],
          'handyman_rating':
              handyman['providers_service_rating'] ??
              provider['providers_service_rating'] ??
              0.0,
          'handyman_jobs':
              handyman['total_services_booked'] ??
              provider['total_services_booked'] ??
              0,
          'service_id': detail['service_id'] ?? service['id'],
        },
      );
    } catch (e) {
      debugPrint("Rating navigation error: $e");
    }
  }

  Color getOuterColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.onHold:
        return AppColors.outerInProgress;
      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
      case BookingStatus.arrived:
        return AppColors.outerAccepted;
      case BookingStatus.inProgress:
        return AppColors.outerInProgress;
      case BookingStatus.completed:
        return AppColors.outerCompleted;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return AppColors.outerRejected;
    }
  }

  Color getInnerColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.onHold:
        return AppColors.innerInProgress;
      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
      case BookingStatus.arrived:
        return AppColors.innerAccepted;
      case BookingStatus.inProgress:
        return AppColors.innerInProgress;
      case BookingStatus.completed:
        return AppColors.innerCompleted;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return AppColors.innerRejected;
    }
  }

  Color getBorderColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.onHold:
        return AppColors.borderInProgress;
      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
      case BookingStatus.arrived:
        return AppColors.pauseBlue;
      case BookingStatus.inProgress:
        return AppColors.borderInProgress;
      case BookingStatus.completed:
        return AppColors.neonGreen;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return AppColors.borderRejected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.naturalWhite,
      appBar: AppBar(
        toolbarHeight: AppSizes.h(context, 70),
        backgroundColor: AppColors.naturalWhite,
        automaticallyImplyLeading: false,
        title: Text(
          UserMessages.bookingHistory,
          style: TextStyle(
            color: AppColors.naturalBlack,
            fontSize: AppSizes.w(context, 20),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryRed,
                    ),
                  )
                : _bookings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No bookings found",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchBookings,
                    color: AppColors.primaryRed,
                    child: ListView.builder(
                      padding: EdgeInsets.all(Insets.sm),
                      itemCount: _bookings.length,
                      itemBuilder: (_, i) {
                        final item = _bookings[i];
                        final statusStr =
                            item['status']?.toString() ?? "pending";
                        final status = BookingStatusExt.fromString(statusStr);
                        final statusLabel =
                            item['status_label']?.toString() ?? status.value;

                        final rawHandyman = item['handyman_data'];
                        final handyman = rawHandyman is List
                            ? (rawHandyman.isNotEmpty
                                  ? rawHandyman.first
                                  : null)
                            : rawHandyman;

                        final attachments = item['service_attchments'] as List?;
                        final imageUrl = (handyman?['profile_image'] != null)
                            ? handyman!['profile_image'].toString()
                            : (attachments != null && attachments.isNotEmpty)
                            ? attachments[0].toString()
                            : item['provider_image']?.toString() ??
                                  UserMessages.serviceBookingDummy1;

                        return InkWell(
                          onTap: () {
                            final bookingId = item['id']?.toString();
                            if (bookingId == null) return;
                            final statusStr =
                                item['status']?.toString().toLowerCase() ?? '';
                            // Final statuses → detail screen (read-only)
                            if (statusStr == 'completed') {
                              final paymentId = item['payment_id'];

                              // PAYMENT PENDING
                              if (paymentId == null) {
                                _navigateToPayment(context, item);
                              } else {
                                // PAYMENT COMPLETED
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.bookingDetail,
                                  arguments: bookingId,
                                );
                              }
                            } else if (statusStr == 'cancelled' ||
                                statusStr == 'canceled' ||
                                statusStr == 'rejected') {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.bookingDetail,
                                arguments: bookingId,
                              );
                            } else {
                              // Active booking
                              _navigateToActiveBooking(context, item);
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: Insets.sm),
                            padding: EdgeInsets.all(Insets.xsm),
                            decoration: BoxDecoration(
                              color: getOuterColor(status),
                              borderRadius: BorderRadius.circular(Insets.sm),
                              border: Border.all(color: getBorderColor(status)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: AppSizes.h(context, 8)),
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(
                                        Insets.xs,
                                      ),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        height: AppSizes.h(context, 80),
                                        width: AppSizes.w(context, 70),
                                        fit: BoxFit.cover,
                                        httpHeaders: const {},
                                        errorWidget: (_, __, ___) => Container(
                                          height: AppSizes.h(context, 80),
                                          width: AppSizes.w(context, 70),
                                          color: Colors.grey.shade300,
                                          child: const Icon(Icons.image),
                                        ),
                                        placeholder: (_, __) => Container(
                                          height: AppSizes.h(context, 80),
                                          width: AppSizes.w(context, 70),
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: Insets.xs),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: Insets.xs,
                                                  vertical: Insets.xxs,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: getInnerColor(status),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Insets.md,
                                                      ),
                                                ),
                                                child: Text(
                                                  "#${item['id']}",
                                                  style: TextStyle(
                                                    fontSize: AppSizes.w(
                                                      context,
                                                      11,
                                                    ),
                                                    color: getBorderColor(
                                                      status,
                                                    ),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: Insets.xs,
                                                  vertical: Insets.xxs,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: getInnerColor(status),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        Insets.md,
                                                      ),
                                                ),
                                                child: Text(
                                                  () {
                                                    final paymentId =
                                                        item['payment_id'];

                                                    if (status ==
                                                        BookingStatus
                                                            .completed) {
                                                      return paymentId == null
                                                          ? "Payment Pending"
                                                          : "Completed";
                                                    }

                                                    return statusLabel
                                                            .isNotEmpty
                                                        ? statusLabel
                                                        : status.value;
                                                  }(),
                                                  style: TextStyle(
                                                    fontSize: AppSizes.w(
                                                      context,
                                                      11,
                                                    ),
                                                    color: getBorderColor(
                                                      status,
                                                    ),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children:
                                                [
                                                  Text(
                                                    item['service_name']
                                                            ?.toString() ??
                                                        "Service",
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (status ==
                                                      BookingStatus.accepted)
                                                    BlinkingText(
                                                      text: UserMessages
                                                          .currentlyAtYourService,
                                                      style: TextStyle(
                                                        fontSize: AppSizes.w(
                                                          context,
                                                          11,
                                                        ),
                                                        color: AppColors
                                                            .blinkingRed,
                                                      ),
                                                    ),
                                                  // if (status ==
                                                  //     BookingStatus.inProgress)
                                                  //   BlinkingText(
                                                  //     text: UserMessages
                                                  //         .timeRemaining,
                                                  //     style: TextStyle(
                                                  //       fontSize: AppSizes.w(
                                                  //         context,
                                                  //         11,
                                                  //       ),
                                                  //       color: AppColors
                                                  //           .blinkingGreen,
                                                  //     ),
                                                  //   ),
                                                  Builder(
                                                    builder: (context) {
                                                      final double price =
                                                          double.tryParse(
                                                            item['total_amount']
                                                                    ?.toString() ??
                                                                item['price']
                                                                    ?.toString() ??
                                                                "0",
                                                          ) ??
                                                          0;
                                                      return Row(
                                                        children: [
                                                          const Text(
                                                            "Service Fee: ",
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                          Text(
                                                            "₹${price.toStringAsFixed(0)}",
                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .priceOrange,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  ),
                                                ].withSpaceBetween(
                                                  height: AppSizes.h(
                                                    context,
                                                    2,
                                                  ),
                                                ),
                                          ),
                                        ].withSpaceBetween(height: AppSizes.h(context, 6)),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: AppSizes.h(context, 10)),
                                Container(
                                  padding: EdgeInsets.all(Insets.xsm),
                                  decoration: BoxDecoration(
                                    color: getInnerColor(status),
                                    borderRadius: BorderRadius.circular(
                                      Insets.sm,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      rowText(
                                        UserMessages.addressLabel,
                                        item['address']?.toString() ?? "N/A",
                                      ),
                                      SizedBox(height: AppSizes.h(context, 12)),
                                      rowText(
                                        UserMessages.dateLabel,
                                        item['booking_date']?.toString() ??
                                            "N/A",
                                      ),
                                      // API doesn't seem to have separate 'time' field in the way original dummy used it,
                                      // it's likely included in booking_date.
                                      // If needed we can extract it or use another field.
                                    ],
                                  ),
                                ),
                                SizedBox(height: AppSizes.h(context, 17)),
                                if (status != BookingStatus.rejected &&
                                    status != BookingStatus.cancelled)
                                  const Divider(color: Colors.black12),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: AppSizes.w(context, 18),
                                      backgroundColor: Colors.grey.shade200,
                                      child: ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl:
                                              (handyman?['profile_image'] !=
                                                  null)
                                              ? handyman!['profile_image']
                                                    .toString()
                                              : item['provider_image']
                                                        ?.toString() ??
                                                    "",
                                          height: AppSizes.h(context, 36),
                                          width: AppSizes.w(context, 36),
                                          fit: BoxFit.cover,
                                          httpHeaders: const {},
                                          errorWidget: (_, __, ___) =>
                                              Image.asset(
                                                UserMessages.riderImage,
                                                height: AppSizes.h(context, 36),
                                                width: AppSizes.w(context, 36),
                                                fit: BoxFit.cover,
                                              ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: Insets.xs),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                     
                                 Text(
  (status == BookingStatus.cancelled ||
          status == BookingStatus.rejected)
      ? "Cancelled"
      : handyman != null
          ? (handyman['display_name']?.toString() ??
              handyman['first_name']?.toString() ??
              "Handyman")
          : "Finding...",
),
                                          SizedBox(
                                            height: AppSizes.h(context, 4),
                                          ),
                                          if (status !=
                                                  BookingStatus.cancelled &&
                                              status != BookingStatus.rejected)
                                            Text(
                                              UserMessages.handyman,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (status == BookingStatus.completed)
                                      // In the _BookingHistoryState class, update the TextButton onPressed:
                                      TextButton(
                                        // Prepare all data needed for rating and review
                                        onPressed: () {
                                          _navigateToRatingScreen(
                                            context,
                                            item,
                                          );
                                        },
                                        child: const Text(
                                          "Rate & Review",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primaryRed,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          // Loading overlay while fetching live booking status
          if (_isNavigating)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              ),
            ),
        ],
      ),
    );
  }

  /// Fetches the live booking status and routes to the exact screen the user left.
  Future<void> _navigateToActiveBooking(BuildContext context, Map item) async {
    final bookingId = item['id']?.toString();
    if (bookingId == null || _isNavigating) return;

    // Use a state flag instead of a dialog to avoid Navigator context issues
    setState(() => _isNavigating = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.apiToken;

      final url = Uri.parse(
        '${ApiConfig.apiBaseUrl}/booking-detail?booking_id=$bookingId',
      );
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          if (apiToken != null && apiToken.isNotEmpty)
            'Authorization': 'Bearer $apiToken',
        },
      );

      if (!mounted) return;

      // Safely parse response
      Map<String, dynamic> data = {};
      Map<String, dynamic> detail = {};
      Map<String, dynamic>? handyman;
      dynamic service;

      if (response.statusCode == 200) {
        final rawBody = json.decode(response.body);
        data = rawBody is List
            ? (rawBody.isNotEmpty
                  ? Map<String, dynamic>.from(rawBody.first)
                  : {})
            : Map<String, dynamic>.from(rawBody as Map);

        final rawDetail = data['booking_detail'];
        if (rawDetail is List && rawDetail.isNotEmpty) {
          detail = Map<String, dynamic>.from(rawDetail.first);
        } else if (rawDetail is Map) {
          detail = Map<String, dynamic>.from(rawDetail);
        }

        final rawHandyman = data['handyman_data'] ?? item['handyman_data'];
        if (rawHandyman is List && rawHandyman.isNotEmpty) {
          handyman = Map<String, dynamic>.from(rawHandyman.first);
        } else if (rawHandyman is Map) {
          handyman = Map<String, dynamic>.from(rawHandyman);
        }

        final rawSvc = data['service'] ?? item['service'];
        service = rawSvc is List
            ? (rawSvc.isNotEmpty ? rawSvc.first : {})
            : rawSvc;
      } else {
        // API failed — use list item data as fallback
        detail = {'status': item['status']};
        final rawHandyman = item['handyman_data'];
        if (rawHandyman is List && rawHandyman.isNotEmpty) {
          handyman = Map<String, dynamic>.from(rawHandyman.first);
        } else if (rawHandyman is Map) {
          handyman = Map<String, dynamic>.from(rawHandyman);
        }
        final rawSvc = item['service'];
        service = rawSvc is List
            ? (rawSvc.isNotEmpty ? rawSvc.first : {})
            : rawSvc;
        data = item as Map<String, dynamic>;
      }

      service ??= <String, dynamic>{};
      final price =
          item['total_amount']?.toString() ?? item['price']?.toString();
      final currentStatus = (detail['status'] ?? item['status'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      debugPrint(
        '📋 BookingResume: ID=$bookingId | Status="$currentStatus" | Handyman=${handyman != null}',
      );

      // ── Route based on live status ──────────────────────────────────────────
      if (currentStatus == 'pending' && handyman == null) {
        // Still searching for a professional
        Navigator.pushNamed(
          context,
          AppRoutes.bookingStatus,
          arguments: {
            'service': service,
            'booking_id': bookingId,
            'date': detail['booking_date'] ?? item['booking_date'],
            'time': detail['booking_slot'] ?? item['booking_slot'],
            'price': price,
          },
        );
      } else if (currentStatus == 'pending' ||
          currentStatus == 'ongoing' ||
          currentStatus == 'on_going' ||
          currentStatus == 'assigned') {
        // Professional assigned — show map/tracking screen
        Navigator.pushNamed(
          context,
          AppRoutes.professionalAssigned,
          arguments: {
            'service': service,
            'booking_data': data,
            'price': price,
            'status': BookingStatusModel(
              currentState: BookingState.onTheWay,
              professional: ProfessionalMatch(
                name:
                    handyman?['display_name'] ??
                    handyman?['first_name'] ??
                    'Handyman',
                rating:
                    double.tryParse(
                      handyman?['handyman_rating']?.toString() ?? '4.5',
                    ) ??
                    4.5,
                jobsDone:
                    int.tryParse(
                      handyman?['handyman_job_completed']?.toString() ?? '10',
                    ) ??
                    10,
                avatarUrl: handyman?['profile_image'] ?? '',
              ),
              appointmentDate:
                  detail['booking_date'] ?? item['booking_date'] ?? '',
              appointmentTime:
                  detail['booking_slot'] ?? item['booking_slot'] ?? '',
            ),
          },
        );
      } else if (currentStatus == 'pending_approval' ||
          currentStatus == 'pending approval') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingServiceProgressHome(
              serviceDurationInSeconds: 3600,
              bookingData: data,
              startTime: DateTime.now(),
              price: price,
            ),
          ),
        );
      } else if (currentStatus == 'accepted' ||
          currentStatus == 'arrived' ||
          currentStatus == 'reached') {
        // Handyman arrived — OTP verification
        Navigator.pushNamed(
          context,
          AppRoutes.serviceVerification,
          arguments: {
            'service': service,
            'booking_data': data,
            'price': price,
            'status': BookingStatusModel(
              currentState: BookingState.assigned,
              professional: ProfessionalMatch(
                name:
                    handyman?['display_name'] ??
                    handyman?['first_name'] ??
                    'Handyman',
                rating:
                    double.tryParse(
                      handyman?['handyman_rating']?.toString() ?? '4.5',
                    ) ??
                    4.5,
                jobsDone:
                    int.tryParse(
                      handyman?['handyman_job_completed']?.toString() ?? '10',
                    ) ??
                    10,
                avatarUrl: handyman?['profile_image'] ?? '',
              ),
              appointmentDate:
                  detail['booking_date'] ?? item['booking_date'] ?? '',
              appointmentTime:
                  detail['booking_slot'] ?? item['booking_slot'] ?? '',
            ),
          },
        );
      } else if (currentStatus == 'in_progress' ||
          currentStatus == 'inprogress' ||
          currentStatus == 'started' ||
          currentStatus == 'work_started' ||
          currentStatus == 'pending_approval' ||
          currentStatus == 'pending approval') {
        // Service in progress — timer screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingServiceProgressHome(
              serviceDurationInSeconds: 3600,
              bookingData: data,
              startTime: DateTime.now(),
              price: price,
            ),
          ),
        );
      } else {
        // Unknown active status — fall back to searching screen
        debugPrint(
          '⚠️ Unknown status "$currentStatus" — defaulting to BookingStatusScreen',
        );
        Navigator.pushNamed(
          context,
          AppRoutes.bookingStatus,
          arguments: {
            'service': service,
            'booking_id': bookingId,
            'date': detail['booking_date'] ?? item['booking_date'],
            'time': detail['booking_slot'] ?? item['booking_slot'],
            'price': price,
          },
        );
      }
    } catch (e) {
      debugPrint('❌ BookingResume error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load booking. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  Widget rowText(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppSizes.w(context, 70),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

