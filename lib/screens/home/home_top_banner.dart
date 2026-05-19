import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/services/payment_service.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/providers/dashboard_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zeerah/core/services/notification_service.dart';

class HomeTopBanner extends StatefulWidget {
  const HomeTopBanner({super.key});

  @override
  State<HomeTopBanner> createState() => _HomeTopBannerState();
}

class _HomeTopBannerState extends State<HomeTopBanner> {
  int currentIndex = 0;
  final PaymentService _paymentService = PaymentService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addressProvider = Provider.of<AddressProvider>(
        context,
        listen: false,
      );

      // ONLY LOAD WHEN LOCATION EXISTS
      if (addressProvider.selectedLocation != null) {
        _refreshDashboardData();
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.apiToken != null && userProvider.apiToken!.isNotEmpty) {
        _fetchWalletBalance();
        _fetchNotificationCount();
      } else {
        userProvider.addListener(_onUserProviderChange);
      }

      // Refresh dashboard if address changes
      Provider.of<AddressProvider>(
        context,
        listen: false,
      ).addListener(_onAddressChange);
    });
  }

  void _onAddressChange() {
    if (!mounted) return;
    _refreshDashboardData(force: true);
  }

  void _refreshDashboardData({bool force = false}) {
    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );
    final location = addressProvider.selectedLocation;

    if (location == null ||
        location['latitude'] == null ||
        location['longitude'] == null) {
      debugPrint("Location not selected yet");
      return;
    }

    double? lat = location?['latitude'] != null
        ? double.tryParse(location!['latitude'].toString())
        : null;
    double? lng = location?['longitude'] != null
        ? double.tryParse(location!['longitude'].toString())
        : null;

    final dashboardProvider = Provider.of<DashboardProvider>(
      context,
      listen: false,
    );

    if (force) {
      dashboardProvider.setLocation(lat, lng);
      dashboardProvider.fetchDashboardData();
      dashboardProvider.fetchCategories();
      dashboardProvider.fetchOffers();
    } else {
      dashboardProvider.fetchInitialData(latitude: lat, longitude: lng);
    }
  }

  void _onUserProviderChange() {
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.apiToken != null && userProvider.apiToken!.isNotEmpty) {
      _fetchWalletBalance();
      _fetchNotificationCount();
      userProvider.removeListener(_onUserProviderChange);
    }
  }

  @override
  void dispose() {
    // Safely remove listeners
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.removeListener(_onUserProviderChange);

      final addressProvider = Provider.of<AddressProvider>(
        context,
        listen: false,
      );
      addressProvider.removeListener(_onAddressChange);
    } catch (e) {
      debugPrint("Error removing listeners in HomeTopBanner: $e");
    }
    super.dispose();
  }

  Future<void> _fetchNotificationCount() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final response = await _notificationService.fetchNotificationList(
      customerId: userProvider.backendUserId ?? "166",
      token: userProvider.apiToken,
    );

    if (mounted && response['notification_data'] != null) {
      final List notifications = response['notification_data'];
      final unreadCount = notifications
          .where((n) => n['read_at'] == null)
          .length;
      userProvider.updateUnreadNotificationCount(unreadCount);
    }
  }

  Future<void> _fetchWalletBalance() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Only fetch if we have an API token
    if (userProvider.apiToken == null || userProvider.apiToken!.isEmpty) {
      return;
    }

    try {
      final history = await _paymentService.fetchWalletHistory(
        token: userProvider.apiToken,
      );
      if (mounted && history['available_balance'] != null) {
        final balance =
            double.tryParse(history['available_balance'].toString()) ?? 0.0;
        userProvider.updateWalletBalance(balance);
      }
    } catch (e) {
      debugPrint("Error fetching wallet balance on home: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        final List<String> banners = dashboardProvider.sliderImages.isNotEmpty
            ? dashboardProvider.sliderImages
            : [
                UserMessages.homepageBannerDummy2,
                UserMessages.homepageBannerDummy3,
                UserMessages.homeBanner,
                UserMessages.homepageBannerDummy,
              ];

        if (dashboardProvider.isLoading &&
            dashboardProvider.sliderImages.isEmpty) {
          return SizedBox(
            height: AppSizes.h(context, 325),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
          );
        }

        return SizedBox(
          height: AppSizes.h(context, 325),
          child: Stack(
            children: [
              CarouselSlider(
                options: CarouselOptions(
                  height: AppSizes.h(context, 325),
                  autoPlay: true,
                  viewportFraction: 1.0,
                  onPageChanged: (index, reason) {
                    setState(() {
                      currentIndex = index;
                    });
                  },
                ),
                items: banners.map((image) {
                  return image.startsWith('http')
                      ? CachedNetworkImage(
                          imageUrl: image,
                          httpHeaders: const {},
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
                        )
                      : Image.asset(
                          image,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                }).toList(),
              ),
              Positioned(
                top: Insets.xs,
                left: 0,
                right: 0,
                child: SafeArea(child: _topAppBar(context)),
              ),
              Positioned(
                bottom: Insets.md,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(banners.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: Insets.xxs),
                      width: currentIndex == index ? Insets.xsm : Insets.xxs,
                      height: Insets.xxs,
                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? AppColors.softBlue
                            : AppColors.naturalBlack.withOpacity(0.54),
                        borderRadius: BorderRadius.circular(Insets.xs),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _topAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Insets.sm, vertical: Insets.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Location Section
          Expanded(
            child: Consumer<AddressProvider>(
              builder: (context, provider, _) {
                final selectedLoc = provider.selectedLocation;
                final String address =
                    selectedLoc?['address'] ?? "Select your location";

                return GestureDetector(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.selectLocation),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me,
                            color: Colors.black,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Consumer<UserProvider>(
                            builder: (context, userProvider, _) {
                              return Text(
                                userProvider.firstName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  color: Colors.black,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              address,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Right: Wallet + Profile and Notification
          Row(
            children: [
              // Wallet + Profile Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // const SizedBox(width: 8),
                    // Image.asset(UserMessages.homepageAppbarCoin, height: 24),
                    // const SizedBox(width: 6),
                    // Consumer<UserProvider>(
                    //   builder: (context, userProvider, _) {
                    //     return Text(
                    //       "₹${userProvider.walletBalance.toStringAsFixed(0)}",
                    //       style: GoogleFonts.poppins(
                    //         fontWeight: FontWeight.w600,
                    //         fontSize: 15,
                    //         color: Colors.black,
                    //       ),
                    //     );
                    //   },
                    // ),
                    // const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53935),
                          shape: BoxShape.circle,
                        ),
                        child: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Color(0xFFE53935),
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Notification Icon
              GestureDetector(
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.notificationHistory),
                child: Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    final count = userProvider.unreadNotificationCount;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.notifications,
                          color: Colors.black,
                          size: 32,
                        ),
                        if (count > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFD600),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  count > 9 ? "9+" : count.toString(),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
