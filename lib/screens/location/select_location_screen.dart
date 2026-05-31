import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/screens/location/address_type_bottomsheet.dart';

class SelectLocationScreen extends StatelessWidget {
  const SelectLocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final addressProvider = Provider.of<AddressProvider>(context);
    final savedAddresses = addressProvider.savedAddresses;
    final selectedLocation = addressProvider.selectedLocation; 

    // Set status bar to light icons on dark background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

              void _handleBack() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.landingPage,
      (route) => false,
    );
  }


    return PopScope(
             canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 20, top: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Select a location',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
      
                // Search Bar
                _buildSearchBar(),
      
                // Current Location & Add Address Card
                _buildLocationOptionsCard(context),
      
                // SAVED ADDRESSES label with dividers
                _buildSectionLabel('SAVED ADDRESSES'),
      
                // Saved Address Cards
                ...savedAddresses.asMap().entries.map(
                  (entry) => _buildSavedAddressCard(
                    context, 
                    entry.value, 
                    isSelected: _isAddressSelected(entry.value, selectedLocation),
                  ),
                ),
      
                const SizedBox(height: 24), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isAddressSelected(Map<String, dynamic> address, Map<String, dynamic>? selectedLocation) {
    if (selectedLocation == null) return false;
    
    // Compare by address string or by coordinates
    return address['address'] == selectedLocation['address'] ||
        (address['latitude'] == selectedLocation['latitude'] && 
         address['longitude'] == selectedLocation['longitude']);
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A3A3A), width: 1),
      ),
      child: TextField(
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: 'Search for area, street name...',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF757575),
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFF757575),
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildLocationOptionsCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Color(0xFF3A3A3A), height: 1),
          ),
          // Add Address
          _buildLocationOptionItem(
            icon: Icons.add,
            title: 'Add Address',
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1C1C1C),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (_) {
                  return const AddressTypeBottomSheet();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationOptionItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFE53935), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFE53935),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFBDBDBD),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9E9E9E), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 8),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: Color(0xFF3A3A3A), thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: const Color(0xFF757575),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: Color(0xFF3A3A3A), thickness: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddressCard(
    BuildContext context,
    Map<String, dynamic> data, {
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        Provider.of<AddressProvider>(
          context,
          listen: false,
        ).setSelectedLocation(data);
        Navigator.pushNamed(context, AppRoutes.landingPage, arguments: true);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE53935).withOpacity(0.15) : const Color(0xFF242424),
          borderRadius: BorderRadius.circular(14),
          border: isSelected 
              ? Border.all(color: const Color(0xFFE53935), width: 1.5) 
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Icon + Distance
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Icon(
                    data['icon'], 
                    color: isSelected ? const Color(0xFFE53935) : Colors.white, 
                    size: 26,
                  ),
                  const SizedBox(height: 4),
                  // Text(
                  //   data['distance'] ?? '0 m',
                  //   textAlign: TextAlign.center,
                  //   style: GoogleFonts.poppins(
                  //     color: isSelected ? const Color(0xFFE53935) : const Color(0xFF9E9E9E),
                  //     fontSize: 11,
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right Column: Address Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        data['label'] ?? 'Other',
                        style: GoogleFonts.poppins(
                          color: isSelected ? const Color(0xFFE53935) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                  
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['address'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : const Color(0xFFBDBDBD),
                      fontSize: 13,
                    ),
                  ),
                  if (data['phone'] != null) ...[
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.poppins(fontSize: 12),
                        children: [
                          const TextSpan(
                            text: 'Phone number: ',
                            style: TextStyle(color: Color(0xFF9E9E9E)),
                          ),
                          TextSpan(
                            text: data['phone'],
                            style: const TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildActionButton(Icons.more_horiz),
                      const SizedBox(width: 10),
                      _buildActionButton(Icons.share, isShare: true),
                      const SizedBox(width: 10),
                      _buildDeleteButton(context, data),
                    ],
                  ),
                ],
              ),
            ),
            // Add checkmark icon for selected address
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFFE53935),
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context, Map<String, dynamic> data) {
    return IconButton(
      onPressed: () async {
        // Show confirmation dialog
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF242424),
            title: Text(
              'Delete Address',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to delete this address?',
              style: GoogleFonts.poppins(
                color: Colors.white70,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFE53935),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await Provider.of<AddressProvider>(
            context,
            listen: false,
          ).deleteAddress(context, data);
        }
      },
      icon: const Icon(
        Icons.delete_outline,
        color: Color(0xFFE53935),
        size: 20,
      ),
    );
  }

  Widget _buildActionButton(IconData icon, {bool isShare = false}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF3A3A3A)),
      ),
      child: Center(
        child: isShare
            ? Transform.scale(
                scaleX: -1,
                child: Icon(
                  Icons.reply,
                  color: const Color(0xFFE53935),
                  size: 18,
                ),
              )
            : Icon(icon, color: const Color(0xFFE53935), size: 18),
      ),
    );
  }
}