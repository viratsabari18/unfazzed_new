import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/models/service_list_model.dart';
import 'package:zeerah/core/services/booking_service.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/providers/user_provider.dart';

class BookingConfirmedScreen extends StatelessWidget {
  final dynamic service;
  final String bookingId;
  final String date;
  final String time;
  final String price;

  const BookingConfirmedScreen({
    required this.service,
    this.bookingId = "#UC876-67",
    this.date = "26 March, 2026",
    this.time = "10:30 AM",
    this.price = "0",
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.landingPage),
        ),
        title: const Text(
          "Booking Confirmed",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Hero Success Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB300), // Yellow circle
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFFD90000), // Red check
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Your booking is confirmed!",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Service Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Service Details",
                    style: TextStyle(
                      color: Color(0xFFD90000),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service is CategoryItem ? service.title : (service.name ?? ''),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$date ~ $time",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: service is CategoryItem
                            ? Image.asset(
                                service.image,
                                width: 100,
                                height: 70,
                                fit: BoxFit.cover,
                              )
                            : CachedNetworkImage(
                                imageUrl: (service.attachmentsArray?.isNotEmpty == true)
                                    ? service.attachmentsArray!.first.url ?? ''
                                    : '',
                                width: 100,
                                height: 70,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => const Icon(Icons.image),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // What happens next section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "What happens next",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildNextStep(
                    icon: Icons.search,
                    color: const Color(0xFFFFCCBC),
                    title: "We'll find the best professional for you",
                    subtitle: "Usually within 2~5 minutes",
                  ),
                  _buildNextStep(
                    icon: Icons.notifications_none,
                    color: const Color(0xFFF8BBD0),
                    title: "You'll get a notifications once provider accepts",
                    subtitle: "",
                  ),
                  _buildNextStep(
                    icon: Icons.sensors,
                    color: const Color(0xFFFFD180),
                    title: "Live tracking will start once they leave",
                    subtitle: "",
                  ),
                ],
              ),
            ),
            const Divider(thickness: 4, color: Color(0xFFEEEEEE), height: 40),
            // Booking Details section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Booking details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow("Service Date:", date),
                  const SizedBox(height: 16),
                  _buildDetailRow("Amount:", "₹$price", isAmount: true),
                  const SizedBox(height: 16),
                  _buildDetailRow("Booking ID:", bookingId),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.bookingStatus,
                        arguments: {
                          'service': service,
                          'booking_id': bookingId,
                          'date': date,
                          'time': time,
                          'price': price,
                        },
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300), // Yellow button
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          "View Booking",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Cancel Booking Button with functionality
                  _CancelBookingButton(
                    bookingId: bookingId,
                    service: service,
                    date: date,
                    time: time,
                    price: price,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStep({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.brown[700], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAmount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isAmount ? const Color(0xFF2E7D32) : Colors.black,
          ),
        ),
      ],
    );
  }
}

// Separate StatefulWidget for Cancel Button to handle loading state
class _CancelBookingButton extends StatefulWidget {
  final String bookingId;
  final dynamic service;
  final String date;
  final String time;
  final String price;

  const _CancelBookingButton({
    required this.bookingId,
    required this.service,
    required this.date,
    required this.time,
    required this.price,
  });

  @override
  State<_CancelBookingButton> createState() => _CancelBookingButtonState();
}

class _CancelBookingButtonState extends State<_CancelBookingButton> {
  bool _isCancelling = false;
  final BookingService _bookingService = BookingService();

  void _showConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Cancel Booking",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: const Text(
            "Are you sure you want to cancel this booking? This action cannot be undone.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "No",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the confirm dialog
                _performCancellation(); // Proceed with cancellation
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Yes, Cancel",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performCancellation() async {
    // Check if it's a dummy booking ID
    if (widget.bookingId.startsWith('#')) {
      // For dummy booking, just navigate back
      Navigator.pop(context); // Go back to previous screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking cancelled successfully")),
      );
      return;
    }

    setState(() => _isCancelling = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiToken = userProvider.apiToken;

      if (apiToken == null || apiToken.isEmpty) {
        throw Exception("User not authenticated");
      }

      final success = await _bookingService.updateBookingStatus(
        bookingId: widget.bookingId,
        status: "cancelled",
        reason: "Cancelled by user from confirmation screen",
        token: apiToken,
      );

      if (mounted) {
        setState(() => _isCancelling = false);

        if (success) {
          // Show success message and navigate back
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Booking cancelled successfully"),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to previous screen
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to cancel booking. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isCancelling ? null : _showConfirmDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: _isCancelling
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Cancel Booking",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}