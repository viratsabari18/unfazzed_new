import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/widgets/common/map_picker_screen.dart';

import 'package:cached_network_image/cached_network_image.dart';

class ServiceType extends StatefulWidget {
  final dynamic service;
  final Map<String, dynamic>? selectedOption;
  final List<Map<String, dynamic>> selectedAddOns;

  const ServiceType({
    required this.service,
    this.selectedOption,
    this.selectedAddOns = const [],
    super.key,
  });

  @override
  State<ServiceType> createState() => _ServiceTypeState();
}

class _ServiceTypeState extends State<ServiceType> {
  /// ✅ Controllers
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  final selectedBg = AppColors.selectedServiceBg;
  final tickColor = AppColors.tickColor;

  @override
  void dispose() {
    addressController.dispose();
    descriptionController.dispose();
    super.dispose();
  }



  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔴 Title
          Padding(
            padding: EdgeInsets.only(
                right: Insets.sm, left: Insets.sm, top: Insets.sm, bottom: Insets.xxs),
            child: Text(
              UserMessages.serviceType,
              style: TextStyle(
                fontSize: AppSizes.w(context, 18),
                fontWeight: FontWeight.bold,
                color: AppColors.primaryRed,
              ),
            ),
          ),

          /// 📦 Service Summary
          if (widget.selectedOption != null)
            Container(
              margin: EdgeInsets.symmetric(horizontal: Insets.xsm, vertical: Insets.xxs),
              padding: EdgeInsets.all(Insets.xsm),
              decoration: BoxDecoration(
                color: selectedBg,
                borderRadius: BorderRadius.circular(Insets.xs),
                border: Border.all(color: tickColor.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  /// 🖼 Image
                  Builder(
                    builder: (context) {
                      String? imageUrl;
                      final option = widget.selectedOption!;
                      if (option['image_url'] != null) imageUrl = option['image_url'];
                      else if (option['image'] != null) imageUrl = option['image'];
                      else if (option['attchments_array'] != null && (option['attchments_array'] as List).isNotEmpty) {
                        imageUrl = option['attchments_array'][0]['url'];
                      } else if (option['attachments_array'] != null && (option['attachments_array'] as List).isNotEmpty) {
                        imageUrl = option['attachments_array'][0]['url'];
                      }

                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Insets.xs),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              httpHeaders: const {},
                              height: AppSizes.h(context, 50),
                              width: AppSizes.w(context, 50),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) => const Icon(Icons.image, size: 40, color: Colors.grey),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  /// 📝 Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service.name ?? 'Service',
                          style: TextStyle(
                            fontSize: AppSizes.w(context, 16),
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: AppSizes.h(context, 4)),
                        Text(
                          widget.selectedOption!['title'] ?? widget.selectedOption!['name'] ?? 'Option',
                          style: TextStyle(
                            fontSize: AppSizes.w(context, 14),
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// 💰 Price
                  Text(
                    '₹${widget.selectedOption!['price'] ?? 0}',
                    style: TextStyle(
                      fontSize: AppSizes.w(context, 16),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ],
              ),
            ),

          if (widget.selectedAddOns.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(right: Insets.sm, left: Insets.sm, top: Insets.sm, bottom: Insets.xxs),
              child: Text(
                'Add-on Services',
                style: TextStyle(
                  fontSize: AppSizes.w(context, 16),
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRed,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.selectedAddOns.length,
              itemBuilder: (context, index) {
                final addon = widget.selectedAddOns[index];
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: Insets.xsm, vertical: Insets.xxs),
                  padding: EdgeInsets.all(Insets.xsm),
                  decoration: BoxDecoration(
                    color: AppColors.naturalWhite,
                    borderRadius: BorderRadius.circular(Insets.xs),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) {
                          String? imageUrl;
                          if (addon['image_url'] != null) imageUrl = addon['image_url'];
                          else if (addon['image'] != null) imageUrl = addon['image'];
                          else if (addon['attchments_array'] != null && (addon['attchments_array'] as List).isNotEmpty) {
                            imageUrl = addon['attchments_array'][0]['url'];
                          } else if (addon['attachments_array'] != null && (addon['attachments_array'] as List).isNotEmpty) {
                            imageUrl = addon['attachments_array'][0]['url'];
                          }

                          if (imageUrl != null && imageUrl.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(Insets.xs),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  httpHeaders: const {},
                                  height: AppSizes.h(context, 40),
                                  width: AppSizes.w(context, 40),
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const SizedBox.shrink(),
                                  errorWidget: (context, url, error) => const Icon(Icons.image, size: 30, color: Colors.grey),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      Expanded(
                        child: Text(
                          addon['title'] ?? addon['name'] ?? 'Add-on',
                          style: TextStyle(
                            fontSize: AppSizes.w(context, 14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '₹${addon['price'] ?? 0}',
                        style: TextStyle(
                          fontSize: AppSizes.w(context, 14),
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          SizedBox(height: AppSizes.h(context, 16)),

          Consumer<AddressProvider>(
            builder: (context, addressProvider, child) {
              final selectedLocation = addressProvider.selectedLocation;
              
              if (selectedLocation == null) {
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.selectLocation),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: Insets.sm),
                    padding: EdgeInsets.all(Insets.sm),
                    decoration: BoxDecoration(
                      color: AppColors.naturalWhite,
                      borderRadius: BorderRadius.circular(Insets.sm),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_location_alt_outlined, color: AppColors.primaryRed),
                        SizedBox(width: Insets.sm),
                        Text(
                          UserMessages.enterYourAddress,
                          style: TextStyle(
                            color: AppColors.naturalBlack.withOpacity(0.6),
                            fontSize: AppSizes.w(context, 14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              }

              String label = selectedLocation['label'] ?? "Address";
              String displayAddress = selectedLocation['address'] ?? "";
              
              return Container(
                margin: EdgeInsets.symmetric(horizontal: Insets.sm),
                padding: EdgeInsets.all(Insets.sm),
                decoration: BoxDecoration(
                  color: AppColors.naturalWhite,
                  borderRadius: BorderRadius.circular(Insets.sm),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.naturalBlack.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Insets.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.primaryRed,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: Insets.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            UserMessages.yourAddress,
                            style: TextStyle(
                              fontSize: AppSizes.w(context, 14),
                              fontWeight: FontWeight.w700,
                              color: AppColors.naturalBlack,
                            ),
                          ),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: AppSizes.w(context, 11),
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryRed,
                            ),
                          ),
                          SizedBox(height: AppSizes.h(context, 2)),
                          Text(
                            displayAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: AppSizes.w(context, 12),
                              color: AppColors.naturalBlack.withOpacity(0.6),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: Insets.sm),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.selectLocation),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: Insets.xsm),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Change",
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: AppSizes.h(context, 16)),

          /// 📝 Description Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Insets.sm),
            child: Text(
              UserMessages.descriptionTitle,
              style: TextStyle(
                fontSize: AppSizes.w(context, 16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SizedBox(height: AppSizes.h(context, 8)),

          Container(
            margin: EdgeInsets.symmetric(horizontal: Insets.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Insets.xsm),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: UserMessages.enterDescription,
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(Insets.xsm),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
