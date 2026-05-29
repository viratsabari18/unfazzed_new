import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
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

            _handleServiceCompletion(stopPolling: true);
          }
        } else if (currentStatus == 'pending_approval') {
          if (!_pendingApprovalSaved) {
            _pendingApprovalSaved = true;

            _handleServiceCompletion(stopPolling: false);
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

    if (isCompleted) {
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
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }

    if (stopPolling &&
        _statusPollingTimer != null &&
        _statusPollingTimer!.isActive) {
      _statusPollingTimer?.cancel();
    }

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

      final existingEndTime = prefs.getString('service_end_time_$bookingId');

      if (existingEndTime != null) {
        endTime = DateTime.parse(existingEndTime);

        debugPrint("USING OLD END TIME => $endTime");
      } else {
        endTime = DateTime.now();

        debugPrint("CREATING NEW END TIME => $endTime");
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

      final alreadySaved = prefs.getInt('service_total_time_$bookingId');

      if (alreadySaved == null || alreadySaved <= 0) {
        await prefs.setInt('service_total_time_$bookingId', finalSeconds);
      }
    }

    if (mounted && !isCompleted) {
      final now = DateTime.now();

      Provider.of<UserProvider>(context, listen: false).setServiceEndTime(now);

      setState(() {
        isCompleted = true;
      });

      print("Service completed at $now");
    }

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

  String? getExtraTimeTaken() {
    final bData = _currentBookingData is List
        ? (_currentBookingData as List).first
        : _currentBookingData;

    final rawService = bData?['service'];

    final service = rawService is List
        ? (rawService.isNotEmpty ? rawService.first : {})
        : rawService;

    final durationString = service?['duration']?.toString().trim() ?? "00:00";

    int estimatedSeconds = 0;

    try {
      if (durationString.contains(":")) {
        final parts = durationString.split(':');

        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;

        estimatedSeconds = (hours * 3600) + (minutes * 60);
      } else {
        final estimatedHours = double.tryParse(durationString) ?? 0;

        estimatedSeconds = (estimatedHours * 3600).toInt();
      }
    } catch (e) {
      print("DURATION PARSE ERROR => $e");
      estimatedSeconds = 0;
    }

    final extraSeconds = totalSeconds - estimatedSeconds;

    if (extraSeconds <= 0) {
      return null;
    }

    final hours = extraSeconds ~/ 3600;
    final minutes = (extraSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return "${hours}hr ${minutes}mins";
    }

    return "${minutes}mins";
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
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    !isCompleted
                        ? "lib/assets/images/test_service_in.PNG"
                        : "lib/assets/images/service_is_complted.PNG",
                    height: AppSizes.h(context, 240),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  if (!isCompleted) ...[
                    Padding(
                      padding: EdgeInsets.only(left: AppSizes.w(context, 130)),
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
                  ],
                ],
              ),
              Transform.translate(
                offset: Offset(0, -AppSizes.h(context, 8)),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.naturalWhite,
                    borderRadius: isCompleted
                        ? null
                        : BorderRadius.only(
                            topLeft: Radius.circular(AppSizes.w(context, 16)),
                            topRight: Radius.circular(AppSizes.w(context, 16)),
                          ),
                  ),
                  child: Column(
                    children: [
                      _buildProfessionalInfoAndActionsCard(),
                      if (!isCompleted)
                        SizedBox(height: AppSizes.h(context, 10)),
                      Column(
                        children: [
                          ServiceDetailsCard(bookingData: _currentBookingData),
                          SizedBox(height: AppSizes.h(context, 10)),
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
                      SizedBox(height: AppSizes.h(context, 4)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSizes.w(context, 10),
                        ),
                        child: _buildActionButtonRow(),
                      ),
                      SizedBox(height: AppSizes.h(context, 20)),
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
      padding: EdgeInsets.symmetric(vertical: AppSizes.h(context, 14)),
      alignment: Alignment.center,
      decoration: BoxDecoration(

        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.w(context, 12)),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: AppSizes.w(context, 6),
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: AppSizes.w(context, 18)),
          SizedBox(width: AppSizes.w(context, 8)),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.w(context, 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalInfoAndActionsCard() {
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
    final rawService = bData?['service'];
    final service = rawService is List
        ? (rawService.isNotEmpty ? rawService.first : {})
        : rawService;

    final providerName =
        handyman?['display_name']?.toString() ??
        provider?['display_name']?.toString() ??
        bData?['booking_detail']?['provider_name']?.toString() ??
        "";

    final providerImage =
        handyman?['profile_image'] ??
        service?['provider_image'] ??
        provider?['profile_image'] ??
        provider?['employee_image'] ??
        provider?['provider_image'] ??
        bData?['booking_detail']?['provider_image'];

    final rating =
        double.tryParse(
          (handyman?['handyman_rating'] ??
                  provider?['handyman_rating'] ??
                  handyman?['providers_service_rating'] ??
                  provider?['providers_service_rating'] ??
                  0)
              .toString(),
        ) ??
        0.0;

    final jobsDone =
        (handyman?['total_services_booked'] ??
                provider?['total_services_booked'] ??
                0)
            as int;

    final rawDetail = bData?['booking_detail'];
    final detail = rawDetail is List
        ? (rawDetail.isNotEmpty ? rawDetail.first : {})
        : rawDetail;
    final currentStatus = detail?['status']?.toString().toLowerCase() ?? "";

    String getStatusText() {
      if (currentStatus == 'pending_approval') return "Pending Approval";
      if (currentStatus == 'completed') return "Completed";
      return "In Progress";
    }

    String getSubtitleText() {
      if (currentStatus == 'pending_approval')
        return "Service Pending Approval";
      if (currentStatus == 'completed') return "Service Completed Successfully";
      return "Service is in progress";
    }

    return Transform.translate(
      offset: isCompleted ? Offset(0, -AppSizes.h(context, 8)) : Offset.zero,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.w(context, 16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: AppSizes.w(context, 12),
              spreadRadius: 1,
              offset: const Offset(0, -2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: AppSizes.w(context, 8),
              spreadRadius: 2,
              offset: const Offset(0, 2),
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
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        (providerImage != null &&
                            providerImage.toString().startsWith('http'))
                        ? CachedNetworkImageProvider(
                                providerImage.toString(),
                                headers: const {},
                              )
                              as ImageProvider
                        : null,
                    child:
                        (providerImage == null ||
                            !providerImage.toString().startsWith('http'))
                        ? Icon(
                            Icons.person,
                            color: Colors.black54,
                            size: AppSizes.w(context, 30),
                          )
                        : null,
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
                                providerName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppSizes.w(context, 16),
                                ),
                                maxLines: 1,
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
                                color: isCompleted
                                    ? const Color(0xFF2196F3)
                                    : const Color(0xFF22C55E),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.w(context, 8),
                                ),
                              ),
                              child: Text(
                                getStatusText(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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
                        SizedBox(height: AppSizes.h(context, 6)),
                        Text(
                          getSubtitleText(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isCompleted
                                ? const Color(0xFF2196F3)
                                : const Color(0xFFEF4444),
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
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final backendUserId =
                            prefs.getString('backend_user_id') ?? '';

                        final handymanUserType = handyman?['user_type']
                            ?.toString()
                            .toLowerCase();

                        final isRealHandyman =
                            handyman != null &&
                            handyman['id'] != null &&
                            handymanUserType == 'handyman';

                        final targetId = isRealHandyman
                            ? 'handyman_${handyman['id']}'
                            : 'provider_${provider['id']}';

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
                            'my_chat_id': 'user_$backendUserId',
                            'provider_uid': targetId,
                            'is_handyman_chat': isRealHandyman,
                          },
                        );
                      },
                      child: _buildActionButton(
                        icon: Icons.chat_bubble_outline,
                        label: "Chat",
                        color: AppColors.borderRejected,
                        textColor: AppColors.borderRejected,
                        isOutlined: true,
                      ),
                    ),
                  ),
                ],
              ),
              if (isCompleted) ...[
                SizedBox(height: AppSizes.h(context, 12)),

                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: AppSizes.w(context, 8),
                  ),
                  decoration: BoxDecoration(color: Colors.white),
                  child: Column(
                    children: [
                      // COMPLETED AT
                      _buildSummaryRow(
                        icon: Icons.check_circle,
                        iconColor: const Color(0xFF4CAF50),
                        bgColor: const Color(0xFFE8F5E9),
                        title: "Completed At",
                        value: () {
                          final userProvider = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          );

                          DateTime? time;

                          time =
                              widget.completionTime ??
                              userProvider.serviceEndTime;

                          if (time == null) {
                            final bookingId = getBookingId(_currentBookingData);

                            if (bookingId != null) {
                              final prefs = SharedPreferences.getInstance();

                              prefs.then((sp) {
                                final saved = sp.getString(
                                  'service_end_time_$bookingId',
                                );

                                if (saved != null && mounted) {
                                  setState(() {
                                    _savedCompletionTime = DateTime.parse(
                                      saved,
                                    );
                                  });
                                }
                              });
                            }
                          }

                          final finalTime = time ?? _savedCompletionTime;

                          if (finalTime != null) {
                            return DateFormat('hh:mm a').format(finalTime);
                          }

                          return "--:--";
                        }(),
                      ),

                      if (getExtraTimeTaken() != null &&
                          getExtraTimeTaken() != "0 mins") ...[
                        Divider(height: 1, color: Colors.grey.shade200),

                        _buildSummaryRow(
                          icon: Icons.warning_amber_rounded,
                          iconColor: const Color(0xFFFF9800),
                          bgColor: const Color(0xFFFFF3E0),
                          title: "Extra Time Taken",
                          value: getExtraTimeTaken()!,
                        ),
                      ],

                      Divider(height: 1, color: Colors.grey.shade200),

                      // TOTAL TIME
                      _buildSummaryRow(
                        icon: Icons.access_time_filled,
                        iconColor: const Color(0xFF4285F4),
                        bgColor: const Color(0xFFE8F0FF),
                        title: "Total Time Taken",
                        value: formatTime(totalSeconds),
                      ),

                      Divider(height: 1, color: Colors.grey.shade200),

                      // SERVICE
                      Padding(
                        padding: EdgeInsets.all(AppSizes.w(context, 16)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: AppSizes.w(context, 23),
                              height: AppSizes.w(context, 23),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFF4D6),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.description,
                                color: const Color(0xFFFFB300),
                                size: AppSizes.w(context, 19),
                              ),
                            ),

                            SizedBox(width: AppSizes.w(context, 14)),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Service Name",
                                    style: TextStyle(
                                      fontSize: AppSizes.w(context, 14),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  SizedBox(height: AppSizes.h(context, 4)),

                                  Text(
                                    (() {
                                      final bData = _currentBookingData is List
                                          ? (_currentBookingData as List).first
                                          : _currentBookingData;

                                      final rawService = bData?['service'];

                                      final service = rawService is List
                                          ? (rawService.isNotEmpty
                                                ? rawService.first
                                                : {})
                                          : rawService;

                                      return service?['name']?.toString() ??
                                          service?['service_name']
                                              ?.toString() ??
                                          "N/A";
                                    })(),
                                    style: TextStyle(
                                      fontSize: AppSizes.w(context, 13),
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSizes.h(context, 14)),

                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: AppSizes.w(context, 8),
                    vertical: AppSizes.w(context, 8),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.w(context, 12),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FBF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDEED7)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 55,
                        height: 55,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.shield,
                              size: 35,
                              color: Color(0xFF4CAF50),
                            ),
                            Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your home is in safe hands!",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: AppSizes.w(context, 12),
                              ),
                            ),
                            SizedBox(height: AppSizes.h(context, 4)),
                            Text(
                              "We're always here when you need us again.",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: AppSizes.w(context, 10),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Image.asset(
                        "lib/assets/images/completed_bottom.png",
                        height: AppSizes.h(context, 35),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSizes.h(context, 20)),
              ],
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
      padding: EdgeInsets.symmetric(vertical: AppSizes.h(context, 12)),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.white : color,
        borderRadius: BorderRadius.circular(AppSizes.w(context, 12)),
        border: isOutlined ? Border.all(color: color) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: AppSizes.w(context, 20)),
          SizedBox(width: AppSizes.w(context, 8)),
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

  Widget _buildSummaryRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.all(AppSizes.w(context, 8)),
      child: Row(
        children: [
          Container(
            width: AppSizes.w(context, 22),
            height: AppSizes.w(context, 22),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: AppSizes.w(context, 18)),
          ),

          SizedBox(width: AppSizes.w(context, 14)),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppSizes.w(context, 14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.w(context, 14),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
