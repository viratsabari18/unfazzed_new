import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/address_provider.dart';

class LocationRequiredScreen extends StatefulWidget {
  const LocationRequiredScreen({super.key});

  @override
  State<LocationRequiredScreen> createState() => _LocationRequiredScreenState();
}

class _LocationRequiredScreenState extends State<LocationRequiredScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set status bar to dark icons on white background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("APP RESUMED - Checking location permission");

      Future.microtask(() async {
        final addressProvider = Provider.of<AddressProvider>(
          context,
          listen: false,
        );

        LocationPermission permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          debugPrint(
            "Permission granted after returning from settings - Auto fetching location",
          );
          await _fetchLocationAndNavigate(addressProvider);
        }
      });
    }
  }

  Future<void> _fetchLocationAndNavigate(
    AddressProvider addressProvider,
  ) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await addressProvider.requestPermissionAndGetLocation();

    if (mounted && addressProvider.hasSelectedLocation) {
      debugPrint("Location fetched successfully - Navigating to LandingPage");
      Navigator.pushReplacementNamed(context, AppRoutes.landingPage);
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            addressProvider.errorMessage ??
            "Failed to get location. Please try again.";
      });
    }
  }

  Future<void> _enableLocation() async {
    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );

    await _fetchLocationAndNavigate(addressProvider);
  }

  Future<void> _selectAddressManually() async {
    debugPrint("Navigating to AddAddress screen");

    await Navigator.pushNamed(context, AppRoutes.selectLocation);

    if (!mounted) return;

    debugPrint(
      "Returned from AddAddress screen - Checking if address was added",
    );

    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );

    if (addressProvider.hasSelectedLocation) {
      debugPrint("Address added successfully - Navigating to LandingPage");
      Navigator.pushReplacementNamed(context, AppRoutes.landingPage);
    } else {
      debugPrint("No address added - Staying on LocationRequiredScreen");
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = AppSizes.width(context);
    final screenHeight = AppSizes.height(context);
    final isTablet = screenWidth > 600;
    final isSmallPhone = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.w(context, 20),
              vertical: AppSizes.h(context, 10),
            ),
            child: Container(
              width: isTablet 
                  ? screenWidth * 0.7 
                  : double.infinity,
              constraints: BoxConstraints(
                maxWidth: isTablet ? 500 : double.infinity,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.w(context, 24),
                vertical: AppSizes.h(context, 12),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.w(context, 32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: AppSizes.w(context, 20),
                    offset: Offset(0, AppSizes.h(context, 8)),
                  ),
                ],
              ),
              child: Column(
                children: [
                  /// IMAGE
                  Image.asset(
                    'lib/assets/images/loc_conig.jpeg',
                    height: isSmallPhone 
                        ? AppSizes.h(context, 180) 
                        : AppSizes.h(context, 235),
                    fit: BoxFit.contain,
                  ),

    

                  /// TITLE SECTION
                  Column(
                    children: [
                      Text(
                        "We’d love to know",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF1D1D1D),
                          fontSize: isTablet 
                              ? AppSizes.w(context, 28) 
                              : AppSizes.w(context, 25),
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "your location",
                            style: TextStyle(
                              color: const Color(0xFF1D1D1D),
                              fontSize: isTablet 
                                  ? AppSizes.w(context, 28) 
                                  : AppSizes.w(context, 25),
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          SizedBox(width: AppSizes.w(context, 6)),

                          Icon(
                            Icons.location_pin,
                            color: const Color(0xFFE53935),
                            size: isTablet 
                                ? AppSizes.w(context, 30) 
                                : AppSizes.w(context, 26),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: AppSizes.h(context, 16)),

                  /// ALLOW LOCATION BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: isSmallPhone 
                        ? AppSizes.h(context, 50) 
                        : AppSizes.h(context, 58),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSizes.w(context, 14)),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFFF5252)],
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _enableLocation,
                        icon: _isLoading
                            ? SizedBox(
                                width: AppSizes.w(context, 18),
                                height: AppSizes.w(context, 18),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.navigation_outlined,
                                color: Colors.white,
                                size: AppSizes.w(context, 20),
                              ),
                        label: Text(
                          _isLoading
                              ? "Getting Location..."
                              : "Allow Location Access",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallPhone 
                                ? AppSizes.w(context, 15) 
                                : AppSizes.w(context, 17),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.w(context, 14)),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: AppSizes.h(context, 14)),

                  /// OPEN SETTINGS BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: isSmallPhone 
                        ? AppSizes.h(context, 50) 
                        : AppSizes.h(context, 58),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Geolocator.openAppSettings();
                      },
                      icon: Icon(
                        Icons.settings_outlined,
                        color: const Color(0xFFE53935),
                        size: AppSizes.w(context, 20),
                      ),
                      label: Text(
                        "Open Settings",
                        style: TextStyle(
                          color: const Color(0xFFE53935),
                          fontSize: isSmallPhone 
                              ? AppSizes.w(context, 15) 
                              : AppSizes.w(context, 17),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFE53935),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.w(context, 14)),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: AppSizes.h(context, 16)),

                  /// DESCRIPTION TEXT
                  Text(
                    "Allow location access to get personalized experiences, relevant Services",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isSmallPhone 
                          ? AppSizes.w(context, 13) 
                          : isTablet 
                              ? AppSizes.w(context, 16) 
                              : AppSizes.w(context, 15),
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: AppSizes.h(context, isTablet ? 40 : 30)),

                  /// FEATURES SECTION
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (isTablet && constraints.maxWidth > 500) {
                        // For tablets, use a more spaced out layout
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _featureItem(
                                Icons.my_location,
                                const Color(0xFFE53935),
                                "Find Nearby",
                                "Discover Highly Rated Services around you.",
                                context,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: AppSizes.h(context, 90),
                              color: Colors.grey.shade200,
                            ),
                            Expanded(
                              child: _featureItem(
                                Icons.map_outlined,
                                const Color(0xFFFF6B6B),
                                "Better Experience",
                                "Get directions and updates.",
                                context,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: AppSizes.h(context, 90),
                              color: Colors.grey.shade200,
                            ),
                            Expanded(
                              child: _featureItem(
                                Icons.workspace_premium_outlined,
                                const Color(0xFFD32F2F),
                                "Relevant Services",
                                "Receive deals that matter.",
                                context,
                              ),
                            ),
                          ],
                        );
                      }
                      
                      // For mobile phones
                      return Row(
                        children: [
                          Expanded(
                            child: _featureItem(
                              Icons.my_location,
                              const Color(0xFFE53935),
                              "Find Nearby",
                              isSmallPhone 
                                  ? "Discover Highly Rated Services around you."
                                  : "Discover Highly Rated Services around you.",
                              context,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: AppSizes.h(context, 90),
                            color: Colors.grey.shade200,
                          ),
                          Expanded(
                            child: _featureItem(
                              Icons.map_outlined,
                              const Color(0xFFFF6B6B),
                              "Better Experience",
                              "Get directions and updates.",
                              context,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: AppSizes.h(context, 90),
                            color: Colors.grey.shade200,
                          ),
                          Expanded(
                            child: _featureItem(
                              Icons.workspace_premium_outlined,
                              const Color(0xFFD32F2F),
                              "Relevant Services",
                              "Receive deals that matter.",
                              context,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: AppSizes.h(context, 35)),

                  /// ERROR MESSAGE
                  if (_errorMessage != null)
                    Container(
                      margin: EdgeInsets.only(bottom: AppSizes.h(context, 16)),
                      padding: EdgeInsets.all(AppSizes.w(context, 12)),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(AppSizes.w(context, 12)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline, 
                            color: Colors.red,
                            size: AppSizes.w(context, 20),
                          ),
                          SizedBox(width: AppSizes.w(context, 10)),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: AppSizes.w(context, 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: AppSizes.h(context, 4)),

                  /// FOOTER
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Colors.grey.shade500,
                        size: isSmallPhone 
                            ? AppSizes.w(context, 14) 
                            : AppSizes.w(context, 16),
                      ),
                      SizedBox(width: AppSizes.w(context, 6)),
                      Expanded(
                        child: Text(
                          "Your location is used only while using the app and won't be shared with anyone. You can change this anytime in settings.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: isSmallPhone 
                                ? AppSizes.w(context, 11) 
                                : isTablet 
                                    ? AppSizes.w(context, 13) 
                                    : AppSizes.w(context, 12),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureItem(
    IconData icon,
    Color color,
    String title,
    String subtitle,
    BuildContext context,
  ) {
    final isSmallPhone = AppSizes.width(context) < 360;
    final isTablet = AppSizes.width(context) > 600;
    
    return Column(
      children: [
        Container(
          width: isSmallPhone 
              ? AppSizes.w(context, 45) 
              : isTablet 
                  ? AppSizes.w(context, 60) 
                  : AppSizes.w(context, 52),
          height: isSmallPhone 
              ? AppSizes.w(context, 45) 
              : isTablet 
                  ? AppSizes.w(context, 60) 
                  : AppSizes.w(context, 52),
          decoration: BoxDecoration(
            color: color.withOpacity(.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon, 
            color: color, 
            size: isSmallPhone 
                ? AppSizes.w(context, 22) 
                : isTablet 
                    ? AppSizes.w(context, 30) 
                    : AppSizes.w(context, 26),
          ),
        ),
        SizedBox(height: AppSizes.h(context, isSmallPhone ? 6 : 10)),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmallPhone 
                ? AppSizes.w(context, 11) 
                : isTablet 
                    ? AppSizes.w(context, 14) 
                    : AppSizes.w(context, 13),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSizes.h(context, isSmallPhone ? 4 : 6)),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          maxLines: isSmallPhone ? 2 : 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isSmallPhone 
                ? AppSizes.w(context, 10) 
                : isTablet 
                    ? AppSizes.w(context, 12) 
                    : AppSizes.w(context, 11),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}