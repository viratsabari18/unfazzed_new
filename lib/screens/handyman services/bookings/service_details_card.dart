import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/common/app_exports.dart';

class ServiceDetailsCard extends StatelessWidget {
  final dynamic bookingData;
  const ServiceDetailsCard({this.bookingData, super.key});

  @override
  Widget build(BuildContext context) {
    String serviceName = UserMessages.fullHomeCleaning;
    String dateTime = UserMessages.serviceDateTime;
    String? imageUrl;
    bool isNetwork = false;

    if (bookingData != null) {
      final bData = bookingData is List ? (bookingData as List).first : bookingData;
      final rawDetail = bData['booking_detail'];
      final detail = rawDetail is List ? (rawDetail.isNotEmpty ? rawDetail.first : {}) : rawDetail;
      
      if (detail != null) {
        serviceName = detail['service_name'] ?? serviceName;
        dateTime = "${detail['booking_date'] ?? ''} ${detail['booking_slot'] ?? ''}".trim();
        if (dateTime.isEmpty) dateTime = UserMessages.serviceDateTime;
      }
      
      final rawService = bData['service'];
      final service = rawService is List ? (rawService.isNotEmpty ? rawService.first : {}) : rawService;
      if (service != null) {
        final attachments = service['attchments_array'];
        if (attachments != null && attachments is List && attachments.isNotEmpty) {
          imageUrl = attachments[0]['url'];
          isNetwork = true;
        }
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      UserMessages.serviceDetails,
                      style: TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.w600,
                        fontSize: AppSizes.w(context, 17),
                      ),
                    ),
                    SizedBox(height: AppSizes.h(context, 6)),
                    Text(
                      serviceName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppSizes.w(context, 14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSizes.h(context, 4)),
                    Text(
                      dateTime,
                      style: TextStyle(
                        fontSize: AppSizes.w(context, 11),
                        color: AppColors.naturalBlack54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(Insets.xs),
                child: isNetwork && imageUrl != null
                  ? Image.network(
                      imageUrl,
                      height: AppSizes.h(context, 90),
                      width: AppSizes.w(context, 120),
                      fit: BoxFit.cover,
                      headers: const {},
                      errorBuilder: (_, __, ___) => _buildFallbackImage(context),
                    )
                  : Image.asset(
                      imageUrl ?? UserMessages.fullHouseCleaningImage,
                      height: AppSizes.h(context, 90),
                      width: AppSizes.w(context, 120),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackImage(context),
                    ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildFallbackImage(BuildContext context) {
    return Container(
      height: AppSizes.h(context, 70),
      width: AppSizes.w(context, 90),
      color: Colors.grey.shade300,
      child: const Icon(Icons.image),
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
