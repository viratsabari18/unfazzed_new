import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReusableServiceCard extends StatelessWidget {
  // Core data
  final String title;
  final String imageUrl;
  final bool isNetworkImage;
  final String appointmentDate;
  final String appointmentTime;
  
  // Optional data for different use cases
  final String? sectionTitle;
  final VoidCallback? onTap;
  final bool showFooter;
  final Widget? customFooter;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? imageWidth;
  final double? imageHeight;
  final BoxFit? imageFit;
  
  // Styling
  final Color? cardColor;
  final Color? sectionTitleColor;
  final double? borderRadius;
  final List<BoxShadow>? customBoxShadow;

  const ReusableServiceCard({
    Key? key,
    required this.title,
    required this.imageUrl,
    this.isNetworkImage = false,
    required this.appointmentDate,
    required this.appointmentTime,
    this.sectionTitle = "Service Details",
    this.onTap,
    this.showFooter = false,
    this.customFooter,
    this.margin = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.padding = const EdgeInsets.all(16),
    this.imageWidth = 100,
    this.imageHeight = 70,
    this.imageFit = BoxFit.cover,
    this.cardColor = Colors.white,
    this.sectionTitleColor = const Color(0xFF2E7D32),
    this.borderRadius = 16,
    this.customBoxShadow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(borderRadius!),
          boxShadow: customBoxShadow ?? [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: padding!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Title
              if (sectionTitle != null && sectionTitle!.isNotEmpty)
                Column(
                  children: [
                    Text(
                      sectionTitle!,
                      style: TextStyle(
                        color: sectionTitleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              
              // Main Content Row
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        
                        // Date Row
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 15,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                appointmentDate,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Time Row
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 15,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                appointmentTime,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Image Section
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isNetworkImage
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: imageWidth,
                            height: imageHeight,
                            fit: imageFit,
                            placeholder: (context, url) => Container(
                              width: imageWidth,
                              height: imageHeight,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: imageWidth,
                              height: imageHeight,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.broken_image,
                                size: 30,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Image.asset(
                            imageUrl,
                            width: imageWidth,
                            height: imageHeight,
                            fit: imageFit,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: imageWidth,
                                height: imageHeight,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
              
              // Optional Footer
              if (showFooter || customFooter != null) ...[
                const SizedBox(height: 20),
                if (customFooter != null) customFooter!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  
}