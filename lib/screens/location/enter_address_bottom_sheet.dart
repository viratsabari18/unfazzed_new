import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/core/providers/user_provider.dart';

class EnterAddressBottomSheet extends StatefulWidget {
  final String address;
  final double latitude;
  final double longitude;
  final String addressType;
  const EnterAddressBottomSheet({
    super.key,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.addressType,
  });

  @override
  State<EnterAddressBottomSheet> createState() =>
      _EnterAddressBottomSheetState();
}

class _EnterAddressBottomSheetState extends State<EnterAddressBottomSheet> {
  final _houseController = TextEditingController();
  final _floorController = TextEditingController();
  final _towerController = TextEditingController();
  bool _isFormValid = false;
  late String _selectedAddressType;

  @override
  void initState() {
    super.initState();
    _houseController.addListener(_validateForm);
    _selectedAddressType = widget.addressType;
  }

  @override
  void dispose() {
    _houseController.dispose();
    _floorController.dispose();
    _towerController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _houseController.text.trim().isNotEmpty;
    });
  }

  void _confirmAddress() {
    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userName = userProvider.user?.displayName ?? "User";
    final userPhone = userProvider.user?.phoneNumber ?? "+91-0000000000";

    // Build the complete address
    String completeAddress = _houseController.text.trim();
    if (_floorController.text.trim().isNotEmpty) {
      completeAddress += ", Floor ${_floorController.text.trim()}";
    }
    if (_towerController.text.trim().isNotEmpty) {
      completeAddress += ", ${_towerController.text.trim()}";
    }
    completeAddress += ", ${widget.address}";

    // Create new address map
    final newAddress = {
      'label': _selectedAddressType.isEmpty ? 'Other' : _selectedAddressType,
      'icon': _selectedAddressType == 'Home'
          ? Icons.home_outlined
          : (_selectedAddressType == 'Work'
                ? Icons.work_outline
                : Icons.location_on_outlined),
      'distance': '0 m',
      'address': completeAddress,
      'phone': userPhone,
      'receiver_name': userName,
      'latitude': widget.latitude,
      'longitude': widget.longitude,
    };

    // Save to provider
    addressProvider.addAddress(context, newAddress);
    // Also set as currently selected location
    addressProvider.setSelectedLocation(newAddress);

    // Navigate back twice (to close bottom sheet then the location screen)
    Navigator.pop(context); // Close bottom sheet
    Navigator.pop(context); // Go back to previous screen
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C1C1C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCloseButton(),
                      _buildTitle(),
                      _buildReceiverCard(),
                      _buildSaveAddressCard(),
                      _buildInputFields(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildConfirmButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCloseButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF3A3A3A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(
        "Enter complete address",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }

  Widget _buildReceiverCard() {
    final userProvider = Provider.of<UserProvider>(context);
    final userName = userProvider.user?.displayName ?? "User";
    final userPhone = userProvider.user?.phoneNumber ?? "No Phone";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Receiver details for this address",
            style: GoogleFonts.poppins(
              color: const Color(0xFF9E9E9E),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.phone_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    children: [
                      TextSpan(text: "$userName, "),
                      TextSpan(
                        text: userPhone,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9E9E9E),
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveAddressCard() {
    final savedAddresses = Provider.of<AddressProvider>(context).savedAddresses;

    final hasHome = savedAddresses.any((e) => e['label'] == 'Home');
    final hasWork = savedAddresses.any((e) => e['label'] == 'Work');
    final hasOther = savedAddresses.any((e) => e['label'] == 'Other');
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Save address as *",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (!hasHome) ...[
                  _addressChip(label: "Home", icon: Icons.home_outlined),
                  const SizedBox(width: 8),
                ],

                if (!hasWork) ...[
                  _addressChip(label: "Work", icon: Icons.work_outline),
                  const SizedBox(width: 8),
                ],

                if (!hasOther)
                  _addressChip(
                    label: "Other",
                    icon: Icons.location_on_outlined,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1C),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF3A3A3A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.address,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF757575),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE53935)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    "Change",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFE53935),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Updated based on your exact map pin",
            style: GoogleFonts.poppins(
              color: const Color(0xFF9E9E9E),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressChip({required String label, required IconData icon}) {
final bool isSelected = _selectedAddressType == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressType = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC62828) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC62828)
                : const Color(0xFF3A3A3A),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
              size: 18,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildInputField(
            hint: "House number *",
            controller: _houseController,
          ),
          _buildInputField(hint: "Floor", controller: _floorController),
          _buildInputField(hint: "LandDmark", controller: _towerController),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF757575),
            fontSize: 14,
          ),
          filled: true,
          fillColor: const Color(0xFF2A2A2A),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1C1C1C),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: ElevatedButton(
          onPressed: _isFormValid ? _confirmAddress : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isFormValid
                ? const Color(0xFFE53935)
                : const Color(0xFF4A4A4A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size(double.infinity, 54),
            elevation: 0,
            disabledBackgroundColor: const Color(0xFF4A4A4A),
          ),
          child: Text(
            "Confirm address",
            style: GoogleFonts.poppins(
              color: _isFormValid ? Colors.white : const Color(0xFF9E9E9E),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
