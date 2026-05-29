import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/common/app_exports.dart';

class ServiceDetailsCard extends StatelessWidget {
  final dynamic bookingData;
  const ServiceDetailsCard({this.bookingData, super.key});

  @override
  Widget build(BuildContext context) {
    // Service Details Data Extraction
    String title = "Service";
    String date = "";
    String time = "";
    String imageUrl = UserMessages.fullHouseCleaningImage;
    bool isNetworkImage = false;

    if (bookingData != null) {
      final bData = bookingData is List ? (bookingData as List).first : bookingData;
      final rawDetail = bData['booking_detail'];
      final detail = rawDetail is List ? (rawDetail.isNotEmpty ? rawDetail.first : {}) : rawDetail;
      
      if (detail != null) {
        title = detail['service_name'] ?? "Service";
        date = detail['booking_date'] ?? '';
        time = detail['booking_slot'] ?? '';
      }
      
      final rawService = bData['service'];
      final service = rawService is List ? (rawService.isNotEmpty ? rawService.first : null) : rawService;
      final attachments = service?['attchments_array'];
      if (attachments != null && attachments is List && attachments.isNotEmpty) {
        imageUrl = attachments[0]['url'];
        isNetworkImage = true;
      }
    }

    return Container(

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 12,
    spreadRadius: 1,
    offset: const Offset(0, -2),
  ),
  BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 8,
    spreadRadius: 2,
    offset: const Offset(0, 2),
  ),
],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Details Section
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Date Row
                      if (date.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 8),
                            Text(
                          date.split(RegExp(r'\d{1,2}:\d{2}')).first.trim(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Time Row
                      if (time.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: isNetworkImage
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 120,
                          height: 80,
                          fit: BoxFit.cover,
                          httpHeaders: const {},
                          errorWidget: (_, __, ___) => _buildFallbackImage(context),
                        )
                      : Image.asset(
                          imageUrl,
                          width: 100,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackImage(context),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage(BuildContext context) {
    return Container(
      width: 100,
      height: 70,
      color: Colors.grey.shade300,
      child: const Icon(Icons.image, size: 30),
    );
  }
}

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const ActionButton({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.h(context, 55),
      decoration: BoxDecoration(
        color: AppColors.naturalWhite,
        borderRadius: BorderRadius.circular(Insets.sm),
        boxShadow: const [
          BoxShadow(
            color: AppColors.naturalBlack12,
            blurRadius: 8,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          SizedBox(width: Insets.xxs),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}