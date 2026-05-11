import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zeerah/core/config/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/controllers/service%20_list_controller.dart';

import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/models/service_list_model.dart';
import 'package:zeerah/core/providers/favorites_provider.dart';
import 'package:zeerah/core/models/favorite_service.dart';
import 'package:zeerah/core/providers/address_provider.dart';

class CategoryDetailsScreen extends StatelessWidget {
  final String subcategoryName;
  final int subcategoryId;
  final String? parentCategoryName;

  const CategoryDetailsScreen({
    Key? key,
    required this.subcategoryName,
    required this.subcategoryId,
    this.parentCategoryName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Print the three arguments
    print("=== CategoryDetailsScreen Arguments ===");
    print("subcategoryName: $subcategoryName");
    print("subcategoryId: $subcategoryId");
    print("parentCategoryName: $parentCategoryName");
    print("=======================================");

    return Scaffold(
      backgroundColor: AppColors.categoryBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(Insets.xs),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.naturalWhite,
              borderRadius: BorderRadius.circular(Insets.xsm),
              boxShadow: [
                BoxShadow(
                  color: AppColors.naturalBlack.withOpacity(0.05),
                  blurRadius: AppSizes.w(context, 10),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.naturalBlack87,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          subcategoryName.replaceAll('\n', ' '),
          style: TextStyle(
            color: AppColors.naturalBlack87,
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.w(context, 20),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.all(Insets.xs),
            child: Container(
              width: AppSizes.w(context, 44),
              decoration: BoxDecoration(
                color: AppColors.naturalWhite,
                borderRadius: BorderRadius.circular(Insets.xsm),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.naturalBlack.withOpacity(0.05),
                    blurRadius: AppSizes.w(context, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.notes, color: AppColors.naturalBlack87),
            ),
          ),
        ],
      ),
      body: Consumer2<ServiceListController, AddressProvider>(
        builder: (context, controller, addressProvider, _) {
          final loc = addressProvider.selectedLocation;
          final lat = double.tryParse(loc?['latitude']?.toString() ?? '');
          final lng = double.tryParse(loc?['longitude']?.toString() ?? '');

          debugPrint("📱 CategoryDetailsScreen: Selected Location -> Lat: $lat, Lng: $lng");

          if ((controller.serviceList.isEmpty || controller.subcategoryId != subcategoryId || controller.latitude != lat) && !controller.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.setSubcategory(subcategoryId);
              controller.setLocation(lat, lng);
              controller.fetchServices();
            });
          }

          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }

          if (controller.serviceList.isEmpty) {
            return Center(child: Text(UserMessages.noServicesFound));
          }

          return ListView.separated(
            padding: EdgeInsets.all(Insets.md),
            itemCount: controller.serviceList.length,
            separatorBuilder: (_, __) =>
                SizedBox(height: AppSizes.h(context, 16)),
            itemBuilder: (context, index) {
              final service = controller.serviceList[index];
              return _ServiceCard(service: service);
            },
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final ServiceData service;

  const _ServiceCard({required this.service});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  double? _lowestPrice;
  bool _isFetchingPrice = false;
  bool _hasOptionsOrAddons = false;

  @override
  void initState() {
    super.initState();
    _fetchLowestPrice();
  }

  Future<void> _fetchLowestPrice() async {
    if (mounted) setState(() => _isFetchingPrice = true);
    try {
      final url = Uri.parse('${ApiConfig.apiBaseUrl}/service-detail');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          
        },
        body: json.encode({'service_id': widget.service.id}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final serviceDetail = data['service_detail'];
        final List<dynamic> bhkOptions = serviceDetail?['service_options'] ?? [];
        final List<dynamic> addOnServices = data['serviceaddon'] ?? [];

        double? minPrice;

        // Check options
        for (var opt in bhkOptions) {
          final p = double.tryParse(opt['price'].toString());
          if (p != null) {
            if (minPrice == null || p < minPrice) {
              minPrice = p;
            }
          }
        }

        // Check add-ons
        for (var addon in addOnServices) {
          final p = double.tryParse(addon['price'].toString());
          if (p != null) {
            if (minPrice == null || p < minPrice) {
              minPrice = p;
            }
          }
        }

        if (mounted) {
          setState(() {
            _lowestPrice = minPrice;
            _hasOptionsOrAddons = bhkOptions.isNotEmpty || addOnServices.isNotEmpty;
            _isFetchingPrice = false;
          });
        }
      } else {
        if (mounted) setState(() => _isFetchingPrice = false);
      }
    } catch (e) {
      debugPrint("Error fetching lowest price: $e");
      if (mounted) setState(() => _isFetchingPrice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> cardColors = [
      AppColors.cardLightGreen,
      AppColors.cardLightBlue,
      AppColors.cardLightYellow,
      AppColors.cardLightPink,
      AppColors.cardLightPurple,
      AppColors.cardLightTeal,
    ];
    final Color cardColor = cardColors[widget.service.id! % cardColors.length];

    // Determine which price to show
    final String displayPrice = _lowestPrice != null 
        ? '₹${_lowestPrice!.toStringAsFixed(0)}' 
        : '₹${widget.service.price ?? 0}';

    return Container(
      height: AppSizes.h(context, 160),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(Insets.lg),
      ),
      padding: EdgeInsets.all(Insets.xsm),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    width: AppSizes.w(context, 130),
                    height: AppSizes.h(context, 110),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Insets.md),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: (widget.service.attachmentsArray != null && widget.service.attachmentsArray!.isNotEmpty)
                          ? widget.service.attachmentsArray!.first.url ?? ""
                          : (widget.service.attachments != null && widget.service.attachments!.isNotEmpty)
                              ? widget.service.attachments!.first
                              : widget.service.providerImage ?? "",
                      httpHeaders: const {},
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.naturalGray,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.broken_image,
                          color: AppColors.naturalBlack26,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Consumer<FavoritesProvider>(
                      builder: (context, favoritesProvider, child) {
                        final isFav = favoritesProvider.isFavorite(widget.service.id!);
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            favoritesProvider.toggleFavorite(
                              FavoriteService(
                                id: widget.service.id!,
                                serviceImage: (widget.service.attachmentsArray != null && widget.service.attachmentsArray!.isNotEmpty)
                                  ? widget.service.attachmentsArray!.first.url ?? ""
                                  : (widget.service.attachments != null && widget.service.attachments!.isNotEmpty)
                                      ? widget.service.attachments!.first
                                      : widget.service.providerImage ?? "",
                                serviceTitle: widget.service.name ?? "Service",
                                rating: double.tryParse(widget.service.totalRating?.toString() ?? "0") ?? 0.0,
                                reviewsCount: 0,
                                rate: widget.service.price ?? 0,
                                isFavorite: true,
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: isFav ? AppColors.primaryRed : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.h(context, 8)),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.pushNamed(
                    context,
                    AppRoutes.serviceDetails,
                    arguments: widget.service,
                  );
                },
                child: Text(
                  UserMessages.viewDetails,
                  style: TextStyle(
                    fontSize: AppSizes.w(context, 11),
                    fontWeight: FontWeight.w700,
                    color: AppColors.naturalBlack,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: Insets.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_fix_high,
                      size: 16,
                      color: AppColors.naturalBlack45,
                    ),
                    SizedBox(width: Insets.xxs),
                    Expanded(
                      child: Text(
                        widget.service.name ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: AppSizes.w(context, 18),
                          fontWeight: FontWeight.bold,
                          color: AppColors.naturalBlack87,
                        ),
                      ),
                    ),
                    SizedBox(width: Insets.xxs),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Insets.xxs,
                        vertical: Insets.xxxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.naturalWhite,
                        borderRadius: BorderRadius.circular(Insets.xs),
                      ),
                      child: Row(
                        children: [
                          Text(
                            widget.service.totalRating?.toString() ??
                                UserMessages.defaultRating,
                            style: TextStyle(
                              fontSize: AppSizes.w(context, 12),
                              fontWeight: FontWeight.bold,
                              color: AppColors.naturalBlack87,
                            ),
                          ),
                          SizedBox(width: Insets.xxxs),
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: AppColors.starOrange,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.h(context, 4)),
                Text(
                  widget.service.description ?? UserMessages.defaultServiceDescription,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppSizes.w(context, 13),
                    color: AppColors.naturalBlack45,
                    letterSpacing: 0.2,
                  ),
                ),
                SizedBox(height: AppSizes.h(context, 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _isFetchingPrice 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryRed)
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_lowestPrice != null)
                            Text(
                              "Starts with",
                              style: TextStyle(
                                fontSize: AppSizes.w(context, 10),
                                color: AppColors.naturalBlack45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          Text(
                            displayPrice,
                            style: TextStyle(
                              fontSize: AppSizes.w(context, 15),
                              fontWeight: FontWeight.bold,
                              color: AppColors.naturalBlack87,
                            ),
                          ),
                        ],
                      ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (_hasOptionsOrAddons) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.bookingConfig,
                            arguments: widget.service,
                          );
                        } else {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.bookingHomePage,
                            arguments: {
                              'service': widget.service,
                              'total_amount': _lowestPrice ?? () {
                                if (widget.service.price is String) {
                                  return double.tryParse(widget.service.price as String);
                                } else if (widget.service.price is num) {
                                  return (widget.service.price as num).toDouble();
                                }
                                return null;
                              }() ?? 0.0,
                            },
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bookNowButtonColor,
                          borderRadius: BorderRadius.circular(Insets.sm),
                        ),
                        child: Text(
                          UserMessages.bookNow,
                          style: TextStyle(
                            color: AppColors.naturalWhite,
                            fontSize: AppSizes.w(context, 12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
