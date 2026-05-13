import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/address_provider.dart';

class AddressTypeBottomSheet extends StatelessWidget {
  const AddressTypeBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Select Address Type",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          _item(
            context,
            icon: Icons.home_outlined,
            title: "Home",
          ),

          _item(
            context,
            icon: Icons.work_outline,
            title: "Work",
          ),

          _item(
            context,
            icon: Icons.location_on_outlined,
            title: "Other",
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return InkWell(
      onTap: () {
        final provider = Provider.of<AddressProvider>(
          context,
          listen: false,
        );

        final alreadyExists = provider.savedAddresses.any(
          (item) =>
              item['label']
                  .toString()
                  .trim()
                  .toLowerCase() ==
              title.toLowerCase(),
        );

        /// IF ALREADY EXISTS
        if (alreadyExists) {
          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "$title address already added",
              ),
            ),
          );

          return;
        }

        /// NORMAL FLOW
        Navigator.pop(context);

        Navigator.pushNamed(
          context,
          AppRoutes.confirmLocation,
          arguments: title,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.red),

            const SizedBox(width: 16),

            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}