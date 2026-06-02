import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/screens/handyman%20services/bookings/booking_history.dart';
import 'package:zeerah/screens/home/home_page.dart';
import 'package:zeerah/screens/profile/help_desk_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  int currentIndex = 0;
  late PageController _pageController;
  bool _isLocationSheetShowing = false;
  bool _hasCheckedLocation = false;

  @override
  bool get wantKeepAlive => true;

  final List<Widget> pages = [
    const HomePage(),
    BookingHistory(),
    const HelpDeskScreen(),
  ];

  final List<IconData> icons = [
    Icons.home_rounded,
    Icons.calendar_today_rounded,
    Icons.emoji_events_rounded,
  ];

  final List<String> labels = [
    UserMessages.home,
    UserMessages.bookings,
    "Support",
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationAndShowSheetIfNeeded();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _hasCheckedLocation = false;
      _checkLocationAndShowSheetIfNeeded();
    }
  }

  Future<void> _checkLocationAndShowSheetIfNeeded() async {
    // FIXED: Set flag at the very beginning to prevent concurrent checks
    if (_hasCheckedLocation) return;
    _hasCheckedLocation = true;

    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );

    // Check if provider is still initializing
    if (!addressProvider.isInitialized || addressProvider.isLoading) {
      debugPrint("AddressProvider still initializing (isInitialized: ${addressProvider.isInitialized}, isLoading: ${addressProvider.isLoading}) - waiting...");
      _hasCheckedLocation = false; // Reset flag to allow retry
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        _checkLocationAndShowSheetIfNeeded();
      }
      return;
    }

    debugPrint("AddressProvider loaded - hasSelectedLocation: ${addressProvider.hasSelectedLocation}");
    debugPrint("AddressProvider savedAddresses count: ${addressProvider.savedAddresses.length}");

    // Don't show sheet if there are any saved addresses
    if (addressProvider.savedAddresses.isNotEmpty) {
      debugPrint("Saved addresses exist, skipping location sheet");
      return;
    }

    // Only show sheet if no location AND no saved addresses AND not already showing
    if (!addressProvider.hasSelectedLocation &&
        addressProvider.savedAddresses.isEmpty &&
        !_isLocationSheetShowing) {
      debugPrint("No location and no saved addresses, showing mandatory sheet");
      _showMandatoryLocationSheet();
    }
  }

void _showMandatoryLocationSheet() {
  if (_isLocationSheetShowing) return;
  _isLocationSheetShowing = true;

  showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return WillPopScope(
        onWillPop: () async => false,
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.red, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    "Location Access Required",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Please enable location access to find nearby services, track providers and get accurate addresses.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () async {
                        debugPrint("ENABLE LOCATION CLICKED");

                        final addressProvider = Provider.of<AddressProvider>(
                          context,
                          listen: false,
                        );

                        await addressProvider.requestPermissionAndGetLocation();

                        debugPrint(
                          "HAS LOCATION => ${addressProvider.hasSelectedLocation}",
                        );

                        if (mounted && addressProvider.hasSelectedLocation) {
                          debugPrint("CLOSING SHEET");
                          _isLocationSheetShowing = false;
                          if (mounted) Navigator.pop(context);
                        } else {
                          debugPrint("SHEET REMAINS OPEN - No location yet");
                          setState(() {}); // Refresh to show any error messages
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Enable Location",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      debugPrint("OPEN SETTINGS CLICKED");
                      await Geolocator.openAppSettings();
                    },
                    child: const Text(
                      "Open Settings",
                      style: TextStyle(color: Color(0xFFE53935)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  ).then((_) {
    _isLocationSheetShowing = false;
    _hasCheckedLocation = false;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _checkLocationAndShowSheetIfNeeded();
    });
  });
}

  void onTabTapped(int index) {
    setState(() => currentIndex = index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: pages,
        ),
        bottomNavigationBar: Container(
          color: Colors.transparent,
          padding: EdgeInsets.only(
            left: AppSizes.w(context, 20),
            right: AppSizes.w(context, 20),
            bottom: AppSizes.h(context, 10),
          ),
          child: ClipRRect(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(AppSizes.w(context, 32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                height: AppSizes.h(context, 64),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.32),
                      const Color(0xFFEFFFFF).withOpacity(0.18),
                      const Color(0xFFD6F5FF).withOpacity(0.12),
                      Colors.white.withOpacity(0.06),
                      const Color(0xFFC8FFF4).withOpacity(0.10),
                    ],
                  ),
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(AppSizes.w(context, 32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / icons.length;
                    final pillWidth = itemWidth - AppSizes.w(context, 18);
                    final pillHeight = AppSizes.h(context, 46);

                    return Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          left: currentIndex * itemWidth + AppSizes.w(context, 9),
                          top: AppSizes.h(context, 9),
                          child: _GlassPill(width: pillWidth, height: pillHeight),
                        ),
                        Row(
                          children: List.generate(icons.length, (index) {
                            final isSelected = currentIndex == index;

                            if (index == 2) {
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => onTabTapped(index),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSizes.w(context, 4),
                                      vertical: AppSizes.h(context, 8),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(22),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFE53935),
                                            Color(0xFFFF5252),
                                            Color(0xFFC62828),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.45),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(0.18),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(22),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              top: 2,
                                              left: 16,
                                              child: Container(
                                                width: 50,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(50),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white.withOpacity(0.35),
                                                      Colors.transparent,
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Center(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    "Support",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: AppSizes.w(context, 16),
                                                      fontWeight: FontWeight.w900,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Transform.rotate(
                                                    angle: -0.7,
                                                    child: const Icon(
                                                      Icons.arrow_forward,
                                                      size: 25,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return Expanded(
                              child: GestureDetector(
                                onTap: () => onTabTapped(index),
                                behavior: HitTestBehavior.translucent,
                                child: SizedBox(
                                  height: AppSizes.h(context, 64),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedScale(
                                        duration: const Duration(milliseconds: 220),
                                        scale: isSelected ? 1 : 0.86,
                                        child: Icon(
                                          icons[index],
                                          size: AppSizes.w(context, 22),
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.black.withOpacity(0.38),
                                        ),
                                      ),
                                      SizedBox(height: AppSizes.h(context, 2)),
                                      AnimatedDefaultTextStyle(
                                        duration: const Duration(milliseconds: 220),
                                        style: TextStyle(
                                          fontSize: AppSizes.w(context, 10),
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.black.withOpacity(0.40),
                                        ),
                                        child: Text(labels[index]),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatefulWidget {
  final double width;
  final double height;
  const _GlassPill({required this.width, required this.height});

  @override
  State<_GlassPill> createState() => _GlassPillState();
}

class _GlassPillState extends State<_GlassPill> with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(26);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFFFFFFF).withOpacity(0.22),
                const Color(0xFFD9F3FF).withOpacity(0.10),
                const Color(0xFFFFFFFF).withOpacity(0.04),
              ],
            ),
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -10,
                left: 6,
                child: Container(
                  width: widget.width * 0.52,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.60),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _shimmer,
                builder: (_, __) {
                  return Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        gradient: SweepGradient(
                          startAngle: _shimmer.value * 2 * pi,
                          endAngle: (_shimmer.value * 2 * pi) + pi,
                          colors: [
                            Colors.transparent,
                            Colors.blue.withOpacity(0.08),
                            Colors.purple.withOpacity(0.06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: widget.height * 0.25,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(26),
                      bottomRight: Radius.circular(26),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.03),
                      ],
                    ),
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