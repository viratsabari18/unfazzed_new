import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zeerah/core/common/app_exports.dart' hide BookingStatusModel, BookingState, ProfessionalMatch;

import 'package:zeerah/core/config/api_config.dart';
import 'package:zeerah/core/models/new_booking_model.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/routes/app_routes.dart';
import 'package:zeerah/core/services/booking_service.dart';
import 'package:zeerah/screens/handyman%20services/bookings/bookig_sevice_progress_home.dart';
import 'package:zeerah/screens/handyman%20services/bookings/booking_card.dart';
import 'package:zeerah/widgets/custom/fade_animation_text.dart';

class BookingHistory extends StatefulWidget {
  const BookingHistory({super.key});

  @override
  State<BookingHistory> createState() => _BookingHistoryState();
}

class _BookingHistoryState extends State<BookingHistory> {
  final BookingService _bookingService = BookingService();
  final Map<String, BookingModel> _bookingsCache = {};
  List<String> _bookingIds = [];
  bool _isInitialLoading = true;
  bool _isNavigating = false;
  Timer? _pollingTimer;
  
  // Cache for booking details to avoid repeated API calls
  final Map<String, Map<String, dynamic>> _bookingDetailsCache = {};

  @override
  void initState() {
    super.initState();
    _fetchBookings();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _bookingDetailsCache.clear();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // Don't poll if navigating or if initial load hasn't completed
      if (!_isNavigating && !_isInitialLoading) {
        _fetchBookingsLive();
      }
    });
  }

  Future<void> _fetchBookings() async {
    setState(() => _isInitialLoading = true);
    
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final response = await _bookingService.fetchBookingList(
        token: userProvider.apiToken,
      );

      if (mounted) {
        final List<dynamic> rawBookings = response['data'] ?? [];
        final Map<String, BookingModel> newCache = {};
        final List<String> newIds = [];
        
        for (final raw in rawBookings) {
          if (raw is Map) {
            // Convert dynamic map to String map
            final Map<String, dynamic> convertedMap = {};
            raw.forEach((key, value) {
              convertedMap[key.toString()] = value;
            });
            final booking = BookingModel.fromJson(convertedMap);
            newCache[booking.id] = booking;
            newIds.add(booking.id);
          }
        }
        
        setState(() {
          _bookingsCache.clear();
          _bookingsCache.addAll(newCache);
          _bookingIds = newIds;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    }
  }

  Future<void> _fetchBookingsLive() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    try {
      final response = await _bookingService.fetchBookingList(
        token: userProvider.apiToken,
      );

      if (!mounted) return;

      final List<dynamic> rawBookings = response['data'] ?? [];
      bool hasChanges = false;
      final Map<String, BookingModel> updatedBookings = {};

      for (final raw in rawBookings) {
        if (raw is Map) {
          // Convert dynamic map to String map
          final Map<String, dynamic> convertedMap = {};
          raw.forEach((key, value) {
            convertedMap[key.toString()] = value;
          });
          final newBooking = BookingModel.fromJson(convertedMap);
          updatedBookings[newBooking.id] = newBooking;
          
          // Check if this booking exists and if it has changed
          final existingBooking = _bookingsCache[newBooking.id];
          if (existingBooking == null || 
              existingBooking.status != newBooking.status ||
              existingBooking.statusLabel != newBooking.statusLabel) {
            hasChanges = true;
          }
        }
      }

      // Check for removed bookings
      if (_bookingIds.length != updatedBookings.length) {
        hasChanges = true;
      }

      if (hasChanges && mounted) {
        setState(() {
          _bookingsCache.clear();
          _bookingsCache.addAll(updatedBookings);
          _bookingIds = updatedBookings.keys.toList();
        });
      }
    } catch (e) {
      debugPrint('Live polling error: $e');
    }
  }

  Future<Map<String, dynamic>> _getBookingDetails(String bookingId) async {
    // Return from cache if available
    if (_bookingDetailsCache.containsKey(bookingId)) {
      return _bookingDetailsCache[bookingId]!;
    }

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

      Map<String, dynamic> data = {};
      if (response.statusCode == 200) {
        final raw = json.decode(response.body);
        // Convert dynamic map to String map
        if (raw is Map<dynamic, dynamic>) {
          data = Map<String, dynamic>.fromEntries(
            raw.entries.map((entry) => MapEntry(entry.key.toString(), entry.value))
          );
        } else if (raw is Map<String, dynamic>) {
          data = raw;
        } else if (raw is List && raw.isNotEmpty) {
          final firstItem = raw.first;
          if (firstItem is Map<dynamic, dynamic>) {
            data = Map<String, dynamic>.fromEntries(
              firstItem.entries.map((entry) => MapEntry(entry.key.toString(), entry.value))
            );
          } else if (firstItem is Map<String, dynamic>) {
            data = firstItem;
          }
        }
        
        // Cache the result
        _bookingDetailsCache[bookingId] = data;
      }
      
      return data;
    } catch (e) {
      debugPrint("Get booking details error: $e");
      return {};
    }
  }

  Future<void> _navigateToRatingScreen(BuildContext context, BookingModel booking) async {
    final bookingId = booking.id;
    final data = await _getBookingDetails(bookingId);
    
    if (!mounted) return;

    final detail = _extractDetail(data, booking);
    final handyman = _extractHandyman(data, booking);
    final provider = _extractProvider(data, booking);
    final service = _extractService(data, booking);

    Navigator.pushNamed(
      context,
      AppRoutes.ratingsAndReview,
      arguments: {
        'booking_data': data.isEmpty ? booking : data,
        'booking_id': bookingId,
        'detail': detail,
        'handyman': handyman,
        'provider': provider,
        'service': service,
        'service_name': detail['service_name'] ?? 
                       service['name'] ?? 
                       booking.serviceName,
        'handyman_id': handyman['id'] ?? provider['id'],
        'handyman_name': handyman['display_name'] ??
                         handyman['first_name'] ??
                         provider['display_name'] ??
                         'Service Provider',
        'handyman_image': handyman['profile_image'] ?? provider['profile_image'],
        'handyman_rating': handyman['providers_service_rating'] ??
                           provider['providers_service_rating'] ??
                           0.0,
        'handyman_jobs': handyman['total_services_booked'] ??
                          provider['total_services_booked'] ??
                          0,
        'service_id': detail['service_id'] ?? service['id'],
      },
    );
  }

  Map<String, dynamic> _extractDetail(Map<String, dynamic> data, BookingModel booking) {
    final rawDetail = data['booking_detail'];
    if (rawDetail is List && rawDetail.isNotEmpty) {
      return Map<String, dynamic>.from(rawDetail.first);
    } else if (rawDetail is Map) {
      return Map<String, dynamic>.from(rawDetail);
    }
    return {
      'status': booking.status,
      'service_name': booking.serviceName,
      'booking_date': booking.bookingDate,
      'booking_slot': booking.bookingSlot,
    };
  }

  Map<String, dynamic> _extractHandyman(Map<String, dynamic> data, BookingModel booking) {
    final rawHandyman = data['handyman_data'] ?? booking.handymanData;
    if (rawHandyman is List && rawHandyman.isNotEmpty) {
      return Map<String, dynamic>.from(rawHandyman.first);
    } else if (rawHandyman is Map) {
      return Map<String, dynamic>.from(rawHandyman);
    } else if (rawHandyman is HandymanModel) {
      return {
        'id': rawHandyman.id,
        'display_name': rawHandyman.displayName,
        'first_name': rawHandyman.firstName,
        'profile_image': rawHandyman.profileImage,
        'providers_service_rating': rawHandyman.rating,
        'total_services_booked': rawHandyman.totalJobs,
      };
    }
    return {};
  }

  Map<String, dynamic> _extractProvider(Map<String, dynamic> data, BookingModel booking) {
    final rawProvider = data['provider_data'] ?? booking.providerData;
    if (rawProvider is List && rawProvider.isNotEmpty) {
      return Map<String, dynamic>.from(rawProvider.first);
    } else if (rawProvider is Map) {
      return Map<String, dynamic>.from(rawProvider);
    } else if (rawProvider is ProviderModel) {
      return {
        'id': rawProvider.id,
        'display_name': rawProvider.displayName,
        'profile_image': rawProvider.profileImage,
        'providers_service_rating': rawProvider.rating,
        'total_services_booked': rawProvider.totalJobs,
      };
    }
    return {};
  }

  Map<String, dynamic> _extractService(Map<String, dynamic> data, BookingModel booking) {
    final rawService = data['service'] ?? booking.service;
    if (rawService is List && rawService.isNotEmpty) {
      return Map<String, dynamic>.from(rawService.first);
    } else if (rawService is Map) {
      return Map<String, dynamic>.from(rawService);
    } else if (rawService is ServiceModel) {
      return rawService.rawData ?? {'name': rawService.name, 'id': rawService.id};
    }
    return {};
  }

  void _handleBookingTap(BookingModel booking) async {
    final status = booking.status?.toLowerCase() ?? '';
    
    if (status == 'completed') {
      if (booking.isPaymentPending) {
        await _navigateToPaymentWithDetails(booking);
      } else {
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.bookingDetail,
            arguments: booking.id,
          );
        }
      }
    } else if (status == 'cancelled' || status == 'canceled' || status == 'rejected') {
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.bookingDetail,
          arguments: booking.id,
        );
      }
    } else {
      await _navigateToActiveBooking(booking);
    }
  }

  Future<void> _navigateToPaymentWithDetails(BookingModel booking) async {
    final data = await _getBookingDetails(booking.id);
    
    if (mounted) {
      Navigator.pushNamed(
        context,
        AppRoutes.paymentsHome,
        arguments: {
          'booking_data': data.isEmpty ? booking : data,
          'price': booking.totalAmount.toString(),
        },
      );
    }
  }

  Future<void> _navigateToActiveBooking(BookingModel booking) async {
    final bookingId = booking.id;
    if (_isNavigating) return;

    setState(() => _isNavigating = true);

    try {
      final data = await _getBookingDetails(bookingId);
      
      if (!mounted) return;

      final detail = _extractDetail(data, booking);
      final handyman = _extractHandyman(data, booking);
      final service = _extractService(data, booking);
      
      final currentStatus = (detail['status'] ?? booking.status ?? '')
          .toString()
          .trim()
          .toLowerCase();

      debugPrint('📋 BookingResume: ID=$bookingId | Status="$currentStatus"');

      if (currentStatus == 'pending' && handyman.isEmpty) {
        Navigator.pushNamed(
          context,
          AppRoutes.bookingStatus,
          arguments: {
            'service': service,
            'booking_id': bookingId,
            'date': detail['booking_date'] ?? booking.bookingDate,
            'time': detail['booking_slot'] ?? booking.bookingSlot,
            'price': booking.totalAmount.toString(),
          },
        );
      } else if (currentStatus == 'pending' ||
          currentStatus == 'ongoing' ||
          currentStatus == 'on_going' ||
          currentStatus == 'assigned') {
        Navigator.pushNamed(
          context,
          AppRoutes.professionalAssigned,
          arguments: {
            'service': service,
            'booking_data': data.isEmpty ? booking : data,
            'price': booking.totalAmount.toString(),
            'status': BookingStatusModel(
              currentState: BookingState.onTheWay,
              professional: ProfessionalMatch(
                name: handyman['display_name'] ?? handyman['first_name'] ?? 'Handyman',
                rating: double.tryParse(handyman['handyman_rating']?.toString() ?? '4.5') ?? 4.5,
                jobsDone: int.tryParse(handyman['handyman_job_completed']?.toString() ?? '10') ?? 10,
                avatarUrl: handyman['profile_image'] ?? '',
              ),
              appointmentDate: detail['booking_date'] ?? booking.bookingDate ?? '',
              appointmentTime: detail['booking_slot'] ?? booking.bookingSlot ?? '',
            ),
          },
        );
      } else if (currentStatus == 'accepted' ||
          currentStatus == 'arrived' ||
          currentStatus == 'reached') {
        Navigator.pushNamed(
          context,
          AppRoutes.serviceVerification,
          arguments: {
            'service': service,
            'booking_data': data.isEmpty ? booking : data,
            'price': booking.totalAmount.toString(),
            'status': BookingStatusModel(
              currentState: BookingState.assigned,
              professional: ProfessionalMatch(
                name: handyman['display_name'] ?? handyman['first_name'] ?? 'Handyman',
                rating: double.tryParse(handyman['handyman_rating']?.toString() ?? '4.5') ?? 4.5,
                jobsDone: int.tryParse(handyman['handyman_job_completed']?.toString() ?? '10') ?? 10,
                avatarUrl: handyman['profile_image'] ?? '',
              ),
              appointmentDate: detail['booking_date'] ?? booking.bookingDate ?? '',
              appointmentTime: detail['booking_slot'] ?? booking.bookingSlot ?? '',
            ),
          },
        );
      } else if (currentStatus == 'in_progress' ||
          currentStatus == 'inprogress' ||
          currentStatus == 'started' ||
          currentStatus == 'work_started' ||
          currentStatus == 'pending_approval' ||
          currentStatus == 'pending approval') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingServiceProgressHome(
              serviceDurationInSeconds: 3600,
              bookingData: data.isEmpty ? booking : data,
              startTime: DateTime.now(),
              price: booking.totalAmount.toString(),
            ),
          ),
        );
      } else {
        Navigator.pushNamed(
          context,
          AppRoutes.bookingStatus,
          arguments: {
            'service': service,
            'booking_id': bookingId,
            'date': detail['booking_date'] ?? booking.bookingDate,
            'time': detail['booking_slot'] ?? booking.bookingSlot,
            'price': booking.totalAmount.toString(),
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
            child: _isInitialLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryRed,
                    ),
                  )
                : _bookingIds.isEmpty
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
                      cacheExtent: 500,
                      padding: EdgeInsets.all(Insets.sm),
                      itemCount: _bookingIds.length,
                      itemBuilder: (_, index) {
                        final booking = _bookingsCache[_bookingIds[index]];
                        if (booking == null) return const SizedBox.shrink();
                        return RepaintBoundary(
                          child: BookingCard(
                            booking: booking,
                            onTap: () => _handleBookingTap(booking),
                            onRateReview: () => _navigateToRatingScreen(context, booking),
                          ),
                        );
                      },
                    ),
                  ),
          ),
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
}


