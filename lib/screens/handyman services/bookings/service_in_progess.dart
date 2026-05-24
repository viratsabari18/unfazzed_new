import 'dart:async';
import 'dart:math';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zeerah/core/config/api_config.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zeerah/screens/handyman%20services/bookings/end_otp_screen.dart';
import 'package:zeerah/screens/handyman%20services/bookings/service_details_card.dart';
import 'package:zeerah/screens/handyman%20services/bookings/service_progress_widget.dart';

class ServiceInProgress extends StatefulWidget {
  final int serviceDuration;
  final dynamic bookingData;
  final DateTime? startTime;
  final DateTime? completionTime;
  final String? price;

  const ServiceInProgress({
    super.key,
    required this.serviceDuration,
    this.bookingData,
    this.startTime,
    this.completionTime,
    this.price,
  });

  @override
  State<ServiceInProgress> createState() => _ServiceInProgressState();
}

class _ServiceInProgressState extends State<ServiceInProgress> {
  Timer? _timer;
  late int totalSeconds;
  bool isCompleted = false;
  dynamic _currentBookingData;

  DateTime? _savedCompletionTime;
  bool _completionAlreadyHandled = false;
  bool _pendingApprovalSaved = false;

  @override
  void initState() {
    super.initState();
    _currentBookingData = widget.bookingData;
    totalSeconds = widget.serviceDuration;

    final bData = _currentBookingData is List
        ? (_currentBookingData as List).first
        : _currentBookingData;

    final rawDetail = bData?['booking_detail'];
    final detail = rawDetail is List
        ? (rawDetail.isNotEmpty ? rawDetail.first : {})
        : rawDetail;

    final status = detail?['status']?.toString().toLowerCase().trim();

    if (status == 'pending_approval' ||
        status == 'pending approval' ||
        status == 'completed') {
      isCompleted = true;
    }

    _startTimer();
    _startStatusPolling();
  }

  String? getBookingId(dynamic data) {
    if (data == null) return null;

    final bData = data is List ? data.first : data;

    final rawDetail = bData?['booking_detail'];

    final detail = rawDetail is List
        ? (rawDetail.isNotEmpty ? rawDetail.first : null)
        : rawDetail;

    final id = detail?['id']?.toString() ?? bData?['id']?.toString();

    debugPrint("EXTRACTED BOOKING ID => $id");

    return id;
  }

  Timer? _statusPollingTimer;
  bool _hasNavigatedToPayments = false;

  void _startStatusPolling() {
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkCompletionStatus();
    });
  }

  Future<void> _checkCompletionStatus() async {
    String? bookingId;
    if (widget.bookingData != null) {
      final bData = widget.bookingData is List
          ? (widget.bookingData as List).first
          : widget.bookingData;
      bookingId = bookingId = getBookingId(_currentBookingData);
    }

    if (bookingId == null) return;

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

      if (response.statusCode == 200) {
        final rawData = json.decode(response.body);
        final data = rawData is List
            ? (rawData.isNotEmpty ? rawData.first : {})
            : rawData;

        final rawDetail = data['booking_detail'];
        final bookingDetail = rawDetail is List
            ? (rawDetail.isNotEmpty ? rawDetail.first : {})
            : rawDetail;
        final rawStatus =
            (bookingDetail?['status'] ?? data['status'])?.toString() ?? "";
        final currentStatus = rawStatus.trim().toLowerCase();

        if (data != null && mounted) {
          setState(() {
            _currentBookingData = data;
          });
        }

     if (currentStatus == 'completed') {
  if (!_completionAlreadyHandled) {
    _completionAlreadyHandled = true;

    _handleServiceCompletion(
      stopPolling: true,
    );
  }
} else if (currentStatus ==
    'pending_approval') {
  if (!_pendingApprovalSaved) {
    _pendingApprovalSaved = true;

    _handleServiceCompletion(
      stopPolling: false,
    );
  }
}
      }
    } catch (_) {}
  }

  void _startTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    debugPrint("============== START TIMER ==============");
    debugPrint("IS COMPLETED => $isCompleted");
    debugPrint("BOOKING DATA => $_currentBookingData");
    String? bookingId;
    debugPrint("BOOKING ID => $bookingId");
    if (_currentBookingData != null) {
      final bData = _currentBookingData is List
          ? (_currentBookingData as List).first
          : _currentBookingData;

      bookingId = getBookingId(widget.bookingData);
      debugPrint("FINAL BOOKING ID USED => $bookingId");
    }

    if (bookingId == null) return;

    final startKey = 'service_start_time_$bookingId';
    final endKey = 'service_end_time_$bookingId';
    final totalKey = 'service_total_time_$bookingId';
    debugPrint("START KEY => $startKey");
    debugPrint("END KEY => $endKey");
    debugPrint("TOTAL KEY => $totalKey");

    String? savedStartTime = prefs.getString(startKey);
    String? savedEndTime = prefs.getString(endKey);

    DateTime startTime;

    if (savedStartTime != null) {
      debugPrint("USING OLD START TIME");
      startTime = DateTime.parse(savedStartTime);
    } else {
      startTime = widget.startTime ?? DateTime.now();
      debugPrint("CREATING NEW START TIME => $startTime");
      await prefs.setString(startKey, startTime.toIso8601String());
    }

    // IF SERVICE ALREADY COMPLETED/PENDING APPROVAL
    if (isCompleted) {
      // use saved total time
      debugPrint("ENTERED COMPLETED BLOCK");
      final rawAllPrefs = prefs.getKeys();

      debugPrint("========= ALL PREFS =========");

      for (final key in rawAllPrefs) {
        debugPrint("$key => ${prefs.get(key)}");
      }

      debugPrint("=============================");

      final dynamic rawTotalValue = prefs.get(totalKey);

      debugPrint("RAW TOTAL VALUE => $rawTotalValue");
      debugPrint("RAW TOTAL TYPE => ${rawTotalValue.runtimeType}");

      final savedTotal = rawTotalValue is int
          ? rawTotalValue
          : int.tryParse(rawTotalValue.toString());

      debugPrint("PARSED TOTAL => $savedTotal");

      if (savedTotal != null && savedTotal > 0) {
        debugPrint("USING SAVED TOTAL => $savedTotal");

        totalSeconds = savedTotal;
      } else {
        DateTime endTime;
        debugPrint("SAVED TOTAL INVALID");
        if (savedEndTime != null) {
          endTime = DateTime.parse(savedEndTime);
        } else {
          endTime = DateTime.now();
          await prefs.setString(endKey, endTime.toIso8601String());
        }

        totalSeconds = endTime.difference(startTime).inSeconds;

        await prefs.setInt(totalKey, totalSeconds);
        debugPrint("NEW TOTAL SAVED => $totalSeconds");
      }

      if (mounted) {
        setState(() {});
      }

      return;
    }

    // RUNNING TIMER
    totalSeconds = DateTime.now().difference(startTime).inSeconds;

    if (mounted) {
      setState(() {});
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || isCompleted) return;

      setState(() {
        totalSeconds = DateTime.now().difference(startTime).inSeconds;
      });
    });
  }

  Future<void> _handleServiceCompletion({bool stopPolling = true}) async {
    // Stop timer
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }

    // Stop polling if needed
    if (stopPolling &&
        _statusPollingTimer != null &&
        _statusPollingTimer!.isActive) {
      _statusPollingTimer?.cancel();
    }

    // REMOVE SAVED TIMER FOR THIS BOOKING
    final prefs = await SharedPreferences.getInstance();

    String? bookingId;

    if (_currentBookingData != null) {
      final bData = _currentBookingData is List
          ? (_currentBookingData as List).first
          : _currentBookingData;

      bookingId =
          bData['booking_detail']?['id']?.toString() ?? bData['id']?.toString();
    }

    if (bookingId != null) {
DateTime endTime;

final existingEndTime =
    prefs.getString(
      'service_end_time_$bookingId',
    );

if (existingEndTime != null) {
  endTime = DateTime.parse(
    existingEndTime,
  );

  debugPrint(
    "USING OLD END TIME => $endTime",
  );
} else {
  endTime = DateTime.now();

  debugPrint(
    "CREATING NEW END TIME => $endTime",
  );
}

      final startTimeString = prefs.getString('service_start_time_$bookingId');

      int finalSeconds = totalSeconds;

      if (startTimeString != null) {
        final startTime = DateTime.parse(startTimeString);

        finalSeconds = endTime.difference(startTime).inSeconds;
      }

      totalSeconds = finalSeconds;

if (existingEndTime == null) {
  await prefs.setString(
    'service_end_time_$bookingId',
    endTime.toIso8601String(),
  );
}

    final alreadySaved =
    prefs.getInt(
      'service_total_time_$bookingId',
    );

if (alreadySaved == null ||
    alreadySaved <= 0) {
  await prefs.setInt(
    'service_total_time_$bookingId',
    finalSeconds,
  );
}
    }
    // Mark completed
    if (mounted && !isCompleted) {
      final now = DateTime.now();

      Provider.of<UserProvider>(context, listen: false).setServiceEndTime(now);

      setState(() {
        isCompleted = true;
      });

      print("Service completed at $now");
    }

    // Navigate only once
    if (stopPolling && mounted) {
      if (!_hasNavigatedToPayments) {
        _hasNavigatedToPayments = true;

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.paymentsHome,
              arguments: {
                'booking_data': _currentBookingData,
                'price': widget.price,
              },
            );
          }
        });
      }
    }
  }

  final Map<String, double> _dummyRatingsCache = {};

  String formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return "${h.toString().padLeft(2, '0')}:"
        "${m.toString().padLeft(2, '0')}:"
        "${s.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    _statusPollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.naturalWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    !isCompleted
                        ? UserMessages.serviceInProgressImage
                        : UserMessages.serviceCompletedImage,
                    height: AppSizes.h(context, 240),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  if (!isCompleted) ...[
                    Padding(
                      padding: EdgeInsets.only(left: AppSizes.w(context, 90)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            UserMessages.liveTimer,
                            style: TextStyle(
                              color: AppColors.primaryRed,
                              fontSize: AppSizes.w(context, 10),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppSizes.h(context, 4)),
                          Text(
                            formatTime(totalSeconds),
                            style: TextStyle(
                              fontSize: AppSizes.w(context, 24),
                              fontWeight: FontWeight.bold,
                              color: AppColors.naturalBlack,
                            ),
                          ),
                          SizedBox(height: AppSizes.h(context, 8)),
                          Text(
                            UserMessages.serviceRunning,
                            style: TextStyle(
                              color: AppColors.primaryRed,
                              fontSize: AppSizes.w(context, 14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: AppSizes.h(context, 4)),
                          // Text(
                          //   () {
                          //     final userProvider = Provider.of<UserProvider>(
                          //       context,
                          //       listen: false,
                          //     );
                          //     final time =
                          //         widget.startTime ??
                          //         userProvider.serviceStartTime;
                          //     if (time != null) {
                          //       return "Started at ${DateFormat('hh:mm a').format(time)}";
                          //     }
                          //     return UserMessages.startedAt;
                          //   }(),
                          //   style: TextStyle(
                          //     fontSize: AppSizes.w(context, 11),
                          //     color: AppColors.primaryRed,
                          //   ),
                          // ),
                          // SizedBox(height: AppSizes.h(context, 3)),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: UserMessages.estimated,
                                  style: TextStyle(
                                    color: AppColors.primaryRed,
                                    fontSize: AppSizes.w(context, 11),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextSpan(
                                  text: () {
                                    final bData = _currentBookingData is List
                                        ? (_currentBookingData as List).first
                                        : _currentBookingData;

                                    final rawService = bData?['service'];

                                    final service = rawService is List
                                        ? (rawService.isNotEmpty
                                              ? rawService.first
                                              : {})
                                        : rawService;

                                    print("========== SERVICE DATA ==========");
                                    print(service);
                                    print("========== DURATION ==========");
                                    print(service?['duration']);

                                    return service?['duration'] != null
                                        ? " ${service['duration']} Hrs"
                                        : UserMessages.estimatedTime;
                                  }(),
                                  style: TextStyle(
                                    color: AppColors.naturalBlack54,
                                    fontSize: AppSizes.w(context, 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Positioned(
                      bottom: AppSizes.h(context, 25),
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            UserMessages.progressClock,
                            width: AppSizes.w(context, 140),
                            height: AppSizes.h(context, 140),
                          ),
                          Text(
                            UserMessages.serviceComplete,
                            style: TextStyle(
                              color: AppColors.completedBlue,
                              fontSize: AppSizes.w(context, 26),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: AppSizes.h(context, 8)),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: UserMessages.handymanHas,
                                  style: TextStyle(
                                    color: AppColors.naturalBlack,
                                    fontSize: AppSizes.w(context, 16),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: UserMessages.finished,
                                  style: TextStyle(
                                    color: AppColors.completedBlue,
                                    fontSize: AppSizes.w(context, 16),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: " the service",
                                  style: TextStyle(
                                    color: AppColors.naturalBlack,
                                    fontSize: AppSizes.w(context, 16),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Transform.translate(
                offset: Offset(0, -Insets.sm),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.naturalWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(Insets.md),
                      topRight: Radius.circular(Insets.md),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(Insets.sm),
                        child: Builder(
                          builder: (context) {
                            final bData = _currentBookingData is List
                                ? (_currentBookingData as List).first
                                : _currentBookingData;
                            final rawHandyman = bData?['handyman_data'];
                            final handyman = rawHandyman is List
                                ? (rawHandyman.isNotEmpty
                                      ? rawHandyman.first
                                      : {})
                                : rawHandyman;
                            final rawProvider = bData?['provider_data'];
                            final provider = rawProvider is List
                                ? (rawProvider.isNotEmpty
                                      ? rawProvider.first
                                      : {})
                                : rawProvider;
                            final rawService = bData?['service'];
                            final service = rawService is List
                                ? (rawService.isNotEmpty
                                      ? rawService.first
                                      : {})
                                : rawService;

                            final providerName =
                                handyman?['display_name']?.toString() ??
                                provider?['display_name']?.toString() ??
                                bData?['booking_detail']?['provider_name']
                                    ?.toString() ??
                                "";
                            final providerImage =
                                handyman?['profile_image'] ??
                                service?['provider_image'] ??
                                provider?['profile_image'] ??
                                provider?['employee_image'] ??
                                provider?['provider_image'] ??
                                bData?['booking_detail']?['provider_image'];

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: AppSizes.w(context, 28),
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage:
                                      (providerImage != null &&
                                          providerImage.toString().startsWith(
                                            'http',
                                          ))
                                      ? NetworkImage(
                                          providerImage,
                                          headers: const {},
                                        )
                                      : null,
                                  child:
                                      (providerImage == null ||
                                          !providerImage.toString().startsWith(
                                            'http',
                                          ))
                                      ? const Icon(
                                          Icons.person,
                                          color: AppColors.naturalBlack,
                                        )
                                      : null,
                                ),
                                SizedBox(width: Insets.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              providerName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: AppSizes.w(
                                                  context,
                                                  16,
                                                ),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: Insets.xsm,
                                              vertical: Insets.xxs,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isCompleted
                                                  ? AppColors.completedBlue
                                                  : AppColors.progressGreen,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    Insets.xs,
                                                  ),
                                            ),
                                            child: Text(
                                              () {
                                                final bData =
                                                    _currentBookingData is List
                                                    ? (_currentBookingData
                                                              as List)
                                                          .first
                                                    : _currentBookingData;
                                                final rawDetail =
                                                    bData?['booking_detail'];
                                                final detail = rawDetail is List
                                                    ? (rawDetail.isNotEmpty
                                                          ? rawDetail.first
                                                          : {})
                                                    : rawDetail;
                                                final status = detail?['status']
                                                    ?.toString()
                                                    .toLowerCase();

                                                if (status ==
                                                    'pending_approval')
                                                  return "Pending Approval";
                                                return isCompleted
                                                    ? UserMessages.completed
                                                    : UserMessages.inProgress;
                                              }(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.naturalWhite,
                                                fontSize: AppSizes.w(
                                                  context,
                                                  12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Find the rating display section and replace it
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Color(0xFFFFB300),
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            (() {
                                              final rating =
                                                  handyman?['handyman_rating'] ??
                                                  provider?['providers_service_rating'] ??
                                                  provider?['handyman_rating'] ??
                                                  0;

                                              if (rating == 0) {
                                                // Create a unique key for this handyman/provider
                                                final id =
                                                    handyman?['id']
                                                        ?.toString() ??
                                                    provider?['id']
                                                        ?.toString() ??
                                                    handyman?['uid']
                                                        ?.toString() ??
                                                    provider?['uid']
                                                        ?.toString() ??
                                                    'default';

                                                // Get cached rating or generate new one
                                                final cachedRating =
                                                    _dummyRatingsCache.putIfAbsent(
                                                      id,
                                                      () =>
                                                          4.2 +
                                                          (4.9 - 4.2) *
                                                              Random()
                                                                  .nextDouble(),
                                                    );

                                                return cachedRating
                                                    .toStringAsFixed(1);
                                              }

                                              return rating.toString();
                                            })(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "(${handyman?['total_services_booked'] ?? provider?['total_services_booked'] ?? 0} jobs done)",
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: AppSizes.h(context, 6)),
                                      Text(
                                        () {
                                          final bData =
                                              _currentBookingData is List
                                              ? (_currentBookingData as List)
                                                    .first
                                              : _currentBookingData;
                                          final rawDetail =
                                              bData?['booking_detail'];
                                          final detail = rawDetail is List
                                              ? (rawDetail.isNotEmpty
                                                    ? rawDetail.first
                                                    : {})
                                              : rawDetail;
                                          final status = detail?['status']
                                              ?.toString()
                                              .toLowerCase();

                                          if (status == 'pending_approval')
                                            return "Service Pending Approval";
                                          if (status == 'completed')
                                            return UserMessages
                                                .serviceCompletedText;
                                          return UserMessages
                                              .serviceInProgressText;
                                        }(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isCompleted
                                              ? AppColors.completedBlue
                                              : AppColors.primaryRed,
                                          fontWeight: FontWeight.bold,
                                          fontSize: AppSizes.w(context, 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: AppSizes.h(context, 15)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: Insets.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final bData = _currentBookingData is List
                                      ? (_currentBookingData as List).first
                                      : _currentBookingData;

                                  final rawHandyman = bData?['handyman_data'];
                                  final handyman = rawHandyman is List
                                      ? (rawHandyman.isNotEmpty
                                            ? rawHandyman.first
                                            : {})
                                      : rawHandyman;

                                  final rawProvider = bData?['provider_data'];
                                  final provider = rawProvider is List
                                      ? (rawProvider.isNotEmpty
                                            ? rawProvider.first
                                            : {})
                                      : rawProvider;

                                  final phone =
                                      (handyman?['contact_number'] ??
                                              provider?['contact_number'])
                                          ?.toString()
                                          ?.replaceAll(' ', '');

                                  if (phone != null && phone.isNotEmpty) {
                                    try {
                                      final Uri url = Uri(
                                        scheme: 'tel',
                                        path: phone,
                                      );
                                      if (await canLaunchUrl(url)) {
                                        await launchUrl(
                                          url,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } else {
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
                                child: Container(
                                  height: AppSizes.h(context, 45),
                                  padding: EdgeInsets.symmetric(
                                    vertical: Insets.xs,
                                    horizontal: Insets.md,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? AppColors.darkRed
                                        : AppColors.primaryYellow,
                                    borderRadius: BorderRadius.circular(
                                      Insets.xsm,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        color: isCompleted
                                            ? AppColors.naturalWhite
                                            : Colors.black,
                                      ),
                                      SizedBox(width: Insets.xxs),
                                      Text(
                                        UserMessages.call,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isCompleted
                                              ? AppColors.naturalWhite
                                              : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: AppSizes.w(context, 16)),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final bData = _currentBookingData is List
                                      ? (_currentBookingData as List).first
                                      : _currentBookingData;

                                  final rawHandyman = bData?['handyman_data'];
                                  final handyman = rawHandyman is List
                                      ? (rawHandyman.isNotEmpty
                                            ? rawHandyman.first
                                            : {})
                                      : rawHandyman;

                                  final rawProvider = bData?['provider_data'];
                                  final provider = rawProvider is List
                                      ? (rawProvider.isNotEmpty
                                            ? rawProvider.first
                                            : {})
                                      : rawProvider;

                                  final rawDetail = bData?['booking_detail'];
                                  final detail = rawDetail is List
                                      ? (rawDetail.isNotEmpty
                                            ? rawDetail.first
                                            : {})
                                      : rawDetail;

                                  final rawService = bData?['service'];
                                  final service = rawService is List
                                      ? (rawService.isNotEmpty
                                            ? rawService.first
                                            : {})
                                      : rawService;

                                  final prefs =
                                      await SharedPreferences.getInstance();

                                  final backendUserId =
                                      prefs.getString('backend_user_id') ?? '';

                                  final handymanUserType =
                                      handyman?['user_type']
                                          ?.toString()
                                          .toLowerCase();

                                  final isRealHandyman =
                                      handyman != null &&
                                      handyman['id'] != null &&
                                      handymanUserType == 'handyman';

                                  final targetId = isRealHandyman
                                      ? 'handyman_${handyman['id']}'
                                      : 'provider_${provider['id']}';

                                  debugPrint(
                                    "=========== CHAT TARGET DEBUG ===========",
                                  );

                                  debugPrint("HANDYMAN => $handyman");

                                  debugPrint(
                                    "HANDYMAN USER TYPE => $handymanUserType",
                                  );

                                  debugPrint(
                                    "IS REAL HANDYMAN => $isRealHandyman",
                                  );

                                  debugPrint("TARGET ID => $targetId");

                                  debugPrint(
                                    "=========================================",
                                  );

                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.chatHomeScreen,
                                    arguments: {
                                      'name':
                                          handyman?['display_name'] ??
                                          provider?['display_name'] ??
                                          detail?['provider_name'] ??
                                          "Professional",

                                      'image':
                                          handyman?['profile_image'] ??
                                          service?['provider_image'] ??
                                          provider?['profile_image'] ??
                                          "lib/assets/images/rider_image.png",

                                      'phone':
                                          (handyman?['contact_number'] ??
                                                  provider?['contact_number'])
                                              ?.toString(),

                                      'booking_id': detail?['id']?.toString(),

                                      // sender
                                      'my_chat_id': 'user_$backendUserId',

                                      // receiver
                                      'provider_uid': targetId,
                                      'is_handyman_chat': isRealHandyman,
                                    },
                                  );
                                },
                                child: Container(
                                  height: AppSizes.h(context, 45),
                                  padding: EdgeInsets.symmetric(
                                    vertical: Insets.xxs,
                                    horizontal: Insets.md,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black),
                                    borderRadius: BorderRadius.circular(
                                      Insets.xsm,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.chat, color: Colors.black),
                                      SizedBox(width: Insets.xxs),
                                      Text(
                                        UserMessages.chat,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSizes.h(context, 20)),
                      if (isCompleted) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: Insets.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.completedBlue,
                                    size: 20,
                                  ),
                                  SizedBox(width: Insets.xxs),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: () {
                                            final bData =
                                                _currentBookingData is List
                                                ? (_currentBookingData as List)
                                                      .first
                                                : _currentBookingData;
                                            final rawDetail =
                                                bData?['booking_detail'];
                                            final detail = rawDetail is List
                                                ? (rawDetail.isNotEmpty
                                                      ? rawDetail.first
                                                      : {})
                                                : rawDetail;
                                            return (detail?['status'] ==
                                                    'pending_approval')
                                                ? "Pending Approval: "
                                                : "Completed: ";
                                          }(),
                                          style: TextStyle(
                                            color: AppColors.completedBlue,
                                            fontWeight: FontWeight.w600,
                                            fontSize: AppSizes.w(context, 16),
                                          ),
                                        ),
                                        TextSpan(
                                          text: () {
                                            final userProvider =
                                                Provider.of<UserProvider>(
                                                  context,
                                                  listen: false,
                                                );
                                            DateTime? time;

                                            final prefsData =
                                                Provider.of<UserProvider>(
                                                  context,
                                                  listen: false,
                                                );

                                            time =
                                                widget.completionTime ??
                                                prefsData.serviceEndTime;

                                            if (time == null) {
                                              final bookingId = getBookingId(
                                                _currentBookingData,
                                              );

                                              if (bookingId != null) {
                                                final prefs =
                                                    SharedPreferences.getInstance();

                                                prefs.then((sp) {
                                                  final saved = sp.getString(
                                                    'service_end_time_$bookingId',
                                                  );

                                                  debugPrint(
                                                    "UI SAVED END TIME => $saved",
                                                  );

                                                  if (saved != null &&
                                                      mounted) {
                                                    final parsed =
                                                        DateTime.parse(saved);

                                                    setState(() {
                                                      _savedCompletionTime =
                                                          parsed;
                                                    });
                                                  }
                                                });
                                              }
                                            }
                                            final finalTime =
                                                time ?? _savedCompletionTime;

                                            if (finalTime != null) {
                                              return DateFormat(
                                                'hh:mm a',
                                              ).format(finalTime);
                                            }

                                            return "--:--"; // Fallback
                                          }(),
                                          style: TextStyle(
                                            color: AppColors.naturalBlack,
                                            fontWeight: FontWeight.bold,
                                            fontSize: AppSizes.w(context, 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppSizes.h(context, 12)),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.completedBlue,
                                    size: 20,
                                  ),
                                  SizedBox(width: Insets.xxs),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "Stoppage time: ",
                                          style: TextStyle(
                                            color: AppColors.completedBlue,
                                            fontWeight: FontWeight.w600,
                                            fontSize: AppSizes.w(context, 16),
                                          ),
                                        ),
                                        TextSpan(
                                          text: formatTime(totalSeconds),
                                          style: TextStyle(
                                            color: AppColors.naturalBlack,
                                            fontWeight: FontWeight.bold,
                                            fontSize: AppSizes.w(context, 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: AppSizes.h(context, 20)),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: AppSizes.h(context, 15)),
                      Column(
                        children: [
                          ServiceDetailsCard(bookingData: _currentBookingData),
                          SizedBox(height: AppSizes.h(context, 15)),
                          if (isCompleted ||
                              _currentBookingData?['booking_detail']?['status'] ==
                                  'pending_approval') ...[
                            EndOtpView(
                              totalTime: formatTime(totalSeconds),
                              bookingData: _currentBookingData,
                              otp:
                                  (_currentBookingData?['booking_detail']?['otp'] ??
                                          _currentBookingData?['booking_detail']?['service_otp'] ??
                                          _currentBookingData?['otp'])
                                      ?.toString(),
                            ),
                          ] else ...[
                            ServiceProgressWidget(
                              currentStep: () {
                                final bData = _currentBookingData is List
                                    ? (_currentBookingData as List).first
                                    : _currentBookingData;
                                final rawDetail = bData?['booking_detail'];
                                final detail = rawDetail is List
                                    ? (rawDetail.isNotEmpty
                                          ? rawDetail.first
                                          : {})
                                    : rawDetail;
                                final status = detail?['status']
                                    ?.toString()
                                    .toLowerCase();

                                if (status == 'completed') return 5;
                                if (status == 'pending_approval') return 4;
                                if (status == 'in_progress' ||
                                    status == 'started')
                                  return 3;
                                if (status == 'arrived' || status == 'ongoing')
                                  return 2;
                                return 2;
                              }(),
                            ),
                            SizedBox(height: AppSizes.h(context, 7)),
                          ],
                        ],
                      ),

                      SizedBox(height: AppSizes.h(context, 15)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildActionButtonRow(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
            child: _buildFooterButton(
              Icons.support_agent,
              "Contact Support",
              Colors.black,
            ),
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
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
