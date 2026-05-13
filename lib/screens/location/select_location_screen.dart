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
    final savedAddresses = Provider.of<AddressProvider>(context).savedAddresses;

    // Set status bar to light icons on dark background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
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
              ...savedAddresses.map(
                (address) => _buildSavedAddressCard(context, address),
              ),

              const SizedBox(height: 24), // Bottom padding
            ],
          ),
        ),
      ),
    );
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
    Map<String, dynamic> data,
  ) {
    return GestureDetector(
      onTap: () {
        Provider.of<AddressProvider>(
          context,
          listen: false,
        ).setSelectedLocation(data);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Icon + Distance
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Icon(data['icon'], color: Colors.white, size: 26),
                  const SizedBox(height: 4),
                  Text(
                    data['distance'],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF9E9E9E),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Right Column: Address Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['label'],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['address'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
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
                      IconButton(
                        onPressed: () {
                          Provider.of<AddressProvider>(
                            context,
                            listen: false,
                          ).deleteAddress(data);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
