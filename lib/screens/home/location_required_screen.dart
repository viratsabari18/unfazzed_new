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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  /// IMAGE
                  Image.asset(
                    'lib/assets/images/loc_conig.jpeg',
                    height: size.height * .28,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 10),
                  Column(
                    children: [
                      const Text(
                        "We’d love to know",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF1D1D1D),
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            "your location",
                            style: TextStyle(
                              color: Color(0xFF1D1D1D),
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          SizedBox(width: 6),

                          Icon(
                            Icons.location_pin,
                            color: Color(0xFFE53935),
                            size: 26,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "Allow location access to get personalized experiences,relevant Services",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// FEATURES
                  Row(
                    children: [
                      Expanded(
                        child: _featureItem(
                          Icons.my_location,
                          const Color(0xFFE53935),
                          "Find Nearby",
                          "Discover Highly Rated Services around you.",
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 90,
                        color: Colors.grey.shade200,
                      ),

                      Expanded(
                        child: _featureItem(
                          Icons.map_outlined,
                          const Color(0xFFFF6B6B),
                          "Better Experience",
                          "Get directions and updates.",
                        ),
                      ),

                      Container(
                        width: 1,
                        height: 90,
                        color: Colors.grey.shade200,
                      ),

                      Expanded(
                        child: _featureItem(
                          Icons.workspace_premium_outlined,
                          const Color(0xFFD32F2F),
                          "Relevant Services",
                          "Receive deals that matter.",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  /// ERROR MESSAGE
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  /// ALLOW LOCATION
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFFF5252)],
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _enableLocation,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.navigation_outlined,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isLoading
                              ? "Getting Location..."
                              : "Allow Location Access",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// OPEN SETTINGS
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Geolocator.openAppSettings();
                      },
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Color(0xFFE53935),
                      ),
                      label: const Text(
                        "Open Settings",
                        style: TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFFE53935),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// FOOTER
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Colors.grey.shade500,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Your location is used only while using the app and won't be shared with anyone. You can change this anytime in settings.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
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
  ) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
