import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/address_provider.dart';

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

  // Helper method to get service name safely
  String _getServiceName() {
    try {
      // Check if it's ServiceData class instance
      if (widget.service.runtimeType.toString() == 'ServiceData') {
        return widget.service.name ?? 'Service';
      }
      // Check if it's a Map
      if (widget.service is Map) {
        return widget.service['name'] ?? widget.service['title'] ?? 'Service';
      }
      // Fallback for other types
      return widget.service.name ?? widget.service.title ?? 'Service';
    } catch (_) {
      return 'Service';
    }
  }

  // Helper method to get service price
  String _getServicePrice() {
    try {
      if (widget.service.runtimeType.toString() == 'ServiceData') {
        return widget.service.price?.toString() ?? '0';
      }
      if (widget.service is Map) {
        return widget.service['price']?.toString() ?? '0';
      }
      return widget.service.price?.toString() ?? '0';
    } catch (_) {
      return '0';
    }
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
          /// 🔴 Title - Service Type Header
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

          /// 📦 Main Service Card (Always show the base service)
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
                /// 🖼 Service Image
                Builder(
                  builder: (context) {
                    String? imageUrl;
                    
                    // Try to get image from ServiceData
                    if (widget.service.runtimeType.toString() == 'ServiceData') {
                      if (widget.service.attachmentsArray != null && widget.service.attachmentsArray!.isNotEmpty) {
                        imageUrl = widget.service.attachmentsArray![0].url;
                      } else if (widget.service.attachments != null && widget.service.attachments!.isNotEmpty) {
                        imageUrl = widget.service.attachments![0];
                      }
                    } 
                    // Try to get image from Map
                    else if (widget.service is Map) {
                      if (widget.service['image_url'] != null) imageUrl = widget.service['image_url'];
                      else if (widget.service['image'] != null) imageUrl = widget.service['image'];
                      else if (widget.service['attchments_array'] != null && (widget.service['attchments_array'] as List).isNotEmpty) {
                        imageUrl = widget.service['attchments_array'][0]['url'];
                      }
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
                    
                    // Default icon if no image
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Container(
                        height: AppSizes.h(context, 50),
                        width: AppSizes.w(context, 50),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(Insets.xs),
                        ),
                        child: Icon(Icons.build, color: AppColors.primaryRed, size: 30),
                      ),
                    );
                  },
                ),

                /// 📝 Service Name and Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getServiceName(),
                        style: TextStyle(
                          fontSize: AppSizes.w(context, 16),
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: AppSizes.h(context, 4)),
                      // Show selected option if exists, otherwise show service type
                      if (widget.selectedOption != null)
                        Text(
                          widget.selectedOption!['title'] ?? widget.selectedOption!['name'] ?? 'Standard',
                          style: TextStyle(
                            fontSize: AppSizes.w(context, 14),
                            color: Colors.grey.shade600,
                          ),
                        )
                      else
                        Text(
                          'Base Service',
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
                  '₹${widget.selectedOption != null ? widget.selectedOption!['price'] : _getServicePrice()}',
                  style: TextStyle(
                    fontSize: AppSizes.w(context, 16),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                  ),
                ),
              ],
            ),
          ),

          /// 📦 Selected Option (if different from base service)
          if (widget.selectedOption != null && widget.selectedOption!['title'] != null)
            Padding(
              padding: EdgeInsets.only(left: Insets.sm, right: Insets.sm, top: Insets.xxs, bottom: Insets.xxs),
              child: Text(
                'Selected: ${widget.selectedOption!['title']}',
                style: TextStyle(
                  fontSize: AppSizes.w(context, 12),
                  color: Colors.grey.shade500,
                ),
              ),
            ),

          /// 📦 Add-on Services Section
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
                                  height: AppSizes.w(context, 40),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addon['title'] ?? addon['name'] ?? 'Add-on',
                              style: TextStyle(
                                fontSize: AppSizes.w(context, 14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (addon['description'] != null)
                              Text(
                                addon['description'],
                                style: TextStyle(
                                  fontSize: AppSizes.w(context, 11),
                                  color: Colors.grey.shade500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
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

          /// 📍 Address Section
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
          
          SizedBox(height: AppSizes.h(context, 20)),
        ],
      ),
    );
  }
}