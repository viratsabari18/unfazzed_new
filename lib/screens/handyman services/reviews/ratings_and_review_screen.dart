import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zeerah/core/config/api_config.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/common/app_exports.dart';

class RatingsAndReviewScreen extends StatefulWidget {
  const RatingsAndReviewScreen({super.key});

  @override
  State<RatingsAndReviewScreen> createState() => _RatingsAndReviewScreenState();
}

class _RatingsAndReviewScreenState extends State<RatingsAndReviewScreen> {
  int selectedRating = 4;
  int selectedTip = 100;
  final TextEditingController reviewController = TextEditingController();
  final List<int> tips = [50, 100, 200];
  bool _isSubmitting = false;

  // Data fields
  Map<String, dynamic>? _bookingData;
  Map<String, dynamic>? _provider;
  Map<String, dynamic>? _handyman;
  Map<String, dynamic>? _detail;
  Map<String, dynamic>? _service;
  
  // Extracted fields for easy access
  String? _bookingId;
  String? _handymanId;
  String? _serviceId;
  String? _serviceName;
  String? _handymanName;
  String? _handymanImage;
  double _handymanRating = 0.0;
  int _handymanJobs = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _extractArguments();
  }

  void _extractArguments() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) return;

    // Extract booking data
    final rawBooking = args['booking_data'];
    _bookingData = rawBooking is List 
        ? (rawBooking.isNotEmpty ? rawBooking.first : null) 
        : rawBooking;
    
    // Extract detail
    final rawDetail = args['detail'] ?? _bookingData?['booking_detail'];
    _detail = rawDetail is List 
        ? (rawDetail.isNotEmpty ? rawDetail.first : null) 
        : rawDetail;
    
    // Extract provider
    final rawProvider = args['provider'] ?? _bookingData?['provider_data'];
    _provider = rawProvider is List 
        ? (rawProvider.isNotEmpty ? rawProvider.first : null) 
        : rawProvider;

    // Extract handyman
    final rawHandyman = args['handyman'] ?? _bookingData?['handyman_data'];
    _handyman = rawHandyman is List 
        ? (rawHandyman.isNotEmpty ? rawHandyman.first : null) 
        : rawHandyman;

    // Extract service
    final rawService = args['service'] ?? _bookingData?['service'];
    _service = rawService is List 
        ? (rawService.isNotEmpty ? rawService.first : null) 
        : rawService;

    // Extract individual fields from arguments or derived data
    _bookingId = args['booking_id']?.toString() ?? _detail?['id']?.toString() ?? _bookingData?['id']?.toString();
    _handymanId = args['handyman_id']?.toString() ?? _handyman?['id']?.toString() ?? _provider?['id']?.toString();
    _serviceId = args['service_id']?.toString() ?? _detail?['service_id']?.toString() ?? _service?['id']?.toString();
    _serviceName = args['service_name']?.toString() ?? _detail?['service_name']?.toString() ?? _service?['name']?.toString() ?? _bookingData?['service_name']?.toString() ?? "Service";
    _handymanName = args['handyman_name']?.toString() ?? _handyman?['display_name']?.toString() ?? _handyman?['first_name']?.toString() ?? _provider?['display_name']?.toString() ?? _detail?['provider_name']?.toString() ?? "Service Provider";
    _handymanImage = args['handyman_image']?.toString() ?? _handyman?['profile_image']?.toString() ?? _provider?['profile_image']?.toString();
  _handymanRating = double.tryParse(
      (
        args['handyman_rating'] ??
        _handyman?['handyman_rating'] ??
        _provider?['handyman_rating'] ??
        _handyman?['providers_service_rating'] ??
        _provider?['providers_service_rating'] ??
        0.0
      ).toString(),
    ) ??
    0.0;
    _handymanJobs = (args['handyman_jobs'] ?? _handyman?['total_services_booked'] ?? _provider?['total_services_booked'] ?? 0).toInt();
  }

  Widget buildStar(int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRating = index + 1;
        });
      },
      child: Icon(
        Icons.star,
        size: AppSizes.w(context, 38),
        color: index < selectedRating ? AppColors.starColor : Colors.grey.shade300,
      ),
    );
  }


  Widget tipChip(int value) {
    final bool isSelected = selectedTip == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTip = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: EdgeInsets.symmetric(horizontal: Insets.sm, vertical: Insets.xs),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.softPeach : AppColors.naturalWhite,
          borderRadius: BorderRadius.circular(Insets.xs),
          border: Border.all(color: AppColors.naturalBlack, width: 0.2),
        ),
        child: Text(
          value == 0 ? UserMessages.custom : "₹$value",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  String getRatingText(int rating) {
    switch (rating) {
      case 1:
        return UserMessages.poorService;
      case 2:
        return UserMessages.belowAverage;
      case 3:
        return UserMessages.averageService;
      case 4:
        return UserMessages.goodService;
      case 5:
        return UserMessages.excellentService;
      default:
        return UserMessages.excellentService;
    }
  }

  Future<void> submitReview() async {
    final String reviewText = reviewController.text.trim();
    if (reviewText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write a review"))
      );
      return;
    }

    if (_bookingId == null || _handymanId == null || _serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Missing booking information. Please try again."))
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.apiToken;
      
      if (apiToken == null || apiToken.isEmpty) {
        throw Exception("Authentication token missing");
      }
      
      final url = Uri.parse('${ApiConfig.apiBaseUrl}/save-handyman-rating');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiToken',
        },
        body: json.encode({
          "booking_id": _bookingId,
          "handyman_id": _handymanId,
          "service_id": _serviceId,
          "rating": selectedRating.toDouble(),
          "review": reviewText,
        }),
      );

      debugPrint("📤 Review submission response: ${response.statusCode}");
      debugPrint("📤 Response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Thank you for your review!"))
          );
          // Navigate back to booking history or landing page
          Navigator.popAndPushNamed(context, AppRoutes.bookingHistory);
        }
      } else {
        final errorData = json.decode(response.body);
        final errorMsg = errorData['message'] ?? "Failed to submit review";
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg))
          );
        }
      }
    } catch (e) {
      debugPrint("❌ Error submitting review: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Network error. Please try again."))
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

          void _handleBack() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.landingPage,
      (route) => false,
    );
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
        backgroundColor: AppColors.reviewBgColor,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: AppColors.naturalWhite,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.primaryRed),
            onPressed: _handleBack,
          ),
          centerTitle: true,
          title: Text(
            UserMessages.rateYourExperience,
            style: TextStyle(
              color: AppColors.primaryRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(Insets.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Provider/Handyman Info Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: AppSizes.w(context, 28),
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: _handymanImage != null && _handymanImage!.startsWith('http')
                                ? NetworkImage(_handymanImage!)
                                : null,
                            child: _handymanImage == null || !_handymanImage!.startsWith('http')
                                ? const Icon(Icons.person, color: AppColors.naturalBlack)
                                : null,
                          ),
                          SizedBox(width: Insets.xsm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _handymanName ?? "Service Provider",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppSizes.w(context, 16),
                                  ),
                                ),
                                SizedBox(height: AppSizes.h(context, 4)),
                                Text(
                                  _serviceName ?? "Professional Service",
                                  style: TextStyle(
                                    fontSize: AppSizes.w(context, 13),
                                    color: AppColors.naturalBlack.withOpacity(0.54),
                                  ),
                                ),
                                SizedBox(height: AppSizes.h(context, 4)),
                                Text(
                                  "Rating: ${_handymanRating.toStringAsFixed(1)} ($_handymanJobs jobs)",
                                  style: TextStyle(
                                    fontSize: AppSizes.w(context, 12),
                                    color: AppColors.naturalBlack.withOpacity(0.54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
      
                      SizedBox(height: AppSizes.h(context, 20)),
      
                      // Star Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) => buildStar(index)),
                      ),
      
                      SizedBox(height: AppSizes.h(context, 12)),
      
                      Center(
                        child: Text(
                          getRatingText(selectedRating),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppSizes.w(context, 16),
                          ),
                        ),
                      ),
      
                      SizedBox(height: AppSizes.h(context, 20)),
      
                      // Review Label
                      Text(
                        "${UserMessages.writeA} ${UserMessages.review}",
                        style: TextStyle(
                          color: AppColors.reviewGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
      
                      SizedBox(height: AppSizes.h(context, 8)),
      
                      // Review TextField
                      Container(
                        height: AppSizes.h(context, 120),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Insets.xsm),
                          border: Border.all(color: Colors.grey.shade300),
                          color: AppColors.naturalWhite,
                        ),
                        child: TextField(
                          controller: reviewController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: UserMessages.reviewHint,
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(Insets.xsm),
                          ),
                        ),
                      ),
      
                      SizedBox(height: AppSizes.h(context, 24)),
      
                      // Submit Button
                      GestureDetector(
                        onTap: _isSubmitting ? null : submitReview,
                        child: Container(
                          height: AppSizes.h(context, 55),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _isSubmitting ? Colors.grey : AppColors.submitButtonColor,
                            borderRadius: BorderRadius.circular(Insets.sm),
                          ),
                          child: Center(
                            child: _isSubmitting 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  UserMessages.submitReview,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                          ),
                        ),
                      ),
      
                      SizedBox(height: AppSizes.h(context, 14)),
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
}