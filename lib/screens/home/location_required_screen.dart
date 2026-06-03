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
          debugPrint("Permission granted after returning from settings - Auto fetching location");
          await _fetchLocationAndNavigate(addressProvider);
        }
      });
    }
  }

  Future<void> _fetchLocationAndNavigate(AddressProvider addressProvider) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    await addressProvider.requestPermissionAndGetLocation();
    
    if (mounted && addressProvider.hasSelectedLocation) {
      debugPrint("Location fetched successfully - Navigating to LandingPage");
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.landingPage,
      );
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = addressProvider.errorMessage ?? "Failed to get location. Please try again.";
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
    
    await Navigator.pushNamed(
      context,
      AppRoutes.selectLocation,
    );
    
    if (!mounted) return;
    
    debugPrint("Returned from AddAddress screen - Checking if address was added");
    
    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );
    
    if (addressProvider.hasSelectedLocation) {
      debugPrint("Address added successfully - Navigating to LandingPage");
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.landingPage,
      );
    } else {
      debugPrint("No address added - Staying on LocationRequiredScreen");
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Location Icon
              Container(
                width: w * 0.25,
                height: w * 0.25,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFE53935),
                  size: 60,
                ),
              ),
              
              SizedBox(height: h * 0.04),
              
              // Title
              Text(
                "Enable Your Location",
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontSize: w * 0.07,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: h * 0.02),
              
              // Description
              Text(
                "Please enable location access to find nearby services, track providers and get accurate addresses.",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: w * 0.04,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: h * 0.04),
              
              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: w * 0.035,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.02),
              ],
              
              // Enable Location Button
              SizedBox(
                width: double.infinity,
                height: h * 0.07,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enableLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          "Enable Location",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: w * 0.045,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              // SizedBox(height: h * 0.02),
              
              // // Select Address Manually Button
              // SizedBox(
              //   width: double.infinity,
              //   height: h * 0.07,
              //   child: OutlinedButton(
              //     onPressed: _isLoading ? null : _selectAddressManually,
              //     style: OutlinedButton.styleFrom(
              //       side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //     ),
              //     child: Text(
              //       "Select Address Manually",
              //       style: GoogleFonts.poppins(
              //         color: const Color(0xFFE53935),
              //         fontSize: w * 0.045,
              //         fontWeight: FontWeight.w600,
              //       ),
              //     ),
              //   ),
              // ),
              
              SizedBox(height: h * 0.03),
              
              // Open Settings Button
              SizedBox(
                width: double.infinity,
                height: h * 0.06,
                child: OutlinedButton(
                  onPressed: () async {
                    debugPrint("Open Settings clicked");
                    await Geolocator.openAppSettings();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Open App Settings",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: w * 0.04,
                      fontWeight: FontWeight.w500,
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