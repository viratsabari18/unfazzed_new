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

  Map<String, dynamic>? _bookingData;
  Map<String, dynamic>? _provider;
  Map<String, dynamic>? _handyman;
  Map<String, dynamic>? _detail;
  Map<String, dynamic>? _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      final rawBooking = args['booking_data'];
      final bData = rawBooking is List ? (rawBooking.isNotEmpty ? rawBooking.first : {}) : rawBooking;
      _bookingData = bData;
      
      final rawDetail = bData?['booking_detail'];
      _detail = rawDetail is List ? (rawDetail.isNotEmpty ? rawDetail.first : {}) : rawDetail;
      
      final rawProvider = bData?['provider_data'];
      _provider = rawProvider is List ? (rawProvider.isNotEmpty ? rawProvider.first : {}) : rawProvider;

      final rawHandyman = bData?['handyman_data'];
      _handyman = rawHandyman is List ? (rawHandyman.isNotEmpty ? rawHandyman.first : {}) : rawHandyman;

      final rawService = bData?['service'];
      _service = rawService is List ? (rawService.isNotEmpty ? rawService.first : {}) : rawService;
    }
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
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please write a review")));
       return;
    }

    final bookingId = _detail?['id'];
    final handymanId = _handyman?['id'] ?? _provider?['id'];
    final serviceId = _detail?['service_id'];

    if (bookingId == null || handymanId == null || serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Missing booking information")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.apiToken;
      
      final url = Uri.parse('${ApiConfig.apiBaseUrl}/save-handyman-rating');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $apiToken',
          
        },
        body: json.encode({
          "booking_id": bookingId,
          "handyman_id": handymanId,
          "service_id": serviceId,
          "rating": selectedRating.toDouble(),
          "review": reviewText,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Review submitted successfully!")));
          Navigator.pop(context);
        }
      } else {
        debugPrint("Review failed: ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${response.statusCode}")));
        }
      }
    } catch (e) {
      debugPrint("Error submitting review: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("An error occurred")));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.reviewBgColor,
      resizeToAvoidBottomInset: false, 
      appBar: AppBar(
        backgroundColor: AppColors.naturalWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryRed),
          onPressed: () => Navigator.popAndPushNamed(context, AppRoutes.landingPage)
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
        
                    Row(
                      children: [
                        CircleAvatar(
                          radius: AppSizes.w(context, 28),
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: () {
                            final img = _handyman?['profile_image'] ?? _service?['provider_image'] ?? _provider?['profile_image'];
                            return (img != null && img.toString().startsWith('http'))
                                ? NetworkImage(
                                    img.toString(),
                                    headers: const {},
                                  )
                                : null;
                          }(),
                          child: () {
                            final img = _handyman?['profile_image'] ?? _service?['provider_image'] ?? _provider?['profile_image'];
                            return (img == null || !img.toString().startsWith('http'))
                                ? const Icon(Icons.person, color: AppColors.naturalBlack)
                                : null;
                          }(),
                        ),
                        SizedBox(width: Insets.xsm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _handyman?['display_name']?.toString() ?? _provider?['display_name']?.toString() ?? _detail?['provider_name']?.toString() ?? "",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: AppSizes.w(context, 16),
                              ),
                            ),
                            SizedBox(height: AppSizes.h(context, 4)),
                            Text(
                              _detail?['service_name'] ?? UserMessages.professionalType,
                              style: TextStyle(
                                fontSize: AppSizes.w(context, 13),
                                color: AppColors.naturalBlack.withOpacity(0.54),
                              ),
                            ),
                            SizedBox(height: AppSizes.h(context, 4)),
                            Text(
                              "Rating: ${_handyman?['providers_service_rating'] ?? _provider?['providers_service_rating'] ?? 0.0} (${_handyman?['total_services_booked'] ?? _provider?['total_services_booked'] ?? 0} jobs)",
                              style: TextStyle(
                                fontSize: AppSizes.w(context, 12),
                                color: AppColors.naturalBlack.withOpacity(0.54),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
        
                    SizedBox(height: AppSizes.h(context, 20)),
        
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
        
                    Text(
                      "${UserMessages.writeA}${UserMessages.review}",
                      style: TextStyle(
                        color: AppColors.reviewGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
        
                    SizedBox(height: AppSizes.h(context, 8)),
        
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
        
                    SizedBox(height: AppSizes.h(context, 20)),
        
             
                    Text(
                      UserMessages.tipYourProfessional,
                      style: TextStyle(
                        color: AppColors.discountRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
        
                    SizedBox(height: AppSizes.h(context, 10)),
        
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [...tips.map((e) => tipChip(e)), tipChip(0)],
                      ),
                    ),
        
                    SizedBox(height: AppSizes.h(context, 24)),
        
            
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
        
         
                    GestureDetector(
                      onTap: () {
                        print(UserMessages.bookAgainTapped);
                      },
                      child: Container(
                        height: AppSizes.h(context, 55),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.naturalWhite,
                          borderRadius: BorderRadius.circular(Insets.sm),
                          border: Border.all(color: AppColors.primaryRed),
                          boxShadow: [
                            BoxShadow(
                              spreadRadius: 0,
                              blurRadius: AppSizes.w(context, 8),
                              color: AppColors.naturalBlack.withAlpha(70),
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            UserMessages.bookAgain,
                            style: TextStyle(
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
        
              
                  ],
                ),
              ),
            ),
        
          
          ],
        ),
      ),
    );
  }
}
