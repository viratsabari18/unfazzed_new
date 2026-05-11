import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:zeerah/core/config/api_config.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/common/app_exports.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  bool _isLoading = true;
  List<dynamic> _reviews = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.apiToken;

    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "You must be logged in to view reviews.";
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/get-user-handyman-ratings'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          if (decoded is List) {
            _reviews = decoded;
          } else if (decoded is Map && decoded.containsKey('data')) {
            _reviews = decoded['data'] ?? [];
          } else {
            _reviews = [decoded];
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load reviews. Status: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "An error occurred while fetching reviews: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Reviews',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No reviews found.",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _reviews.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final review = _reviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final rating = double.tryParse(review['rating']?.toString() ?? "0") ?? 0.0;
    final comment = review['review']?.toString() ?? review['comment']?.toString() ?? "No comment provided.";
    final date = review['created_at']?.toString() ?? review['date']?.toString() ?? "";
    final serviceName = review['service_name']?.toString() ?? "Service";
    final handymanName = review['handyman_name']?.toString() ?? "Handyman";
    final handymanImage = review['handyman_profile_image']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (handymanImage != null && handymanImage.isNotEmpty)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(handymanImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      handymanName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      serviceName,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: GoogleFonts.poppins(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          if (date.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                date,
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}
