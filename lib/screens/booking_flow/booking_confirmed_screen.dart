import 'package:cached_network_image/cached_network_image.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/models/service_list_model.dart';

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
          onPressed: () => Navigator.pop(context),
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
                  GestureDetector(
                    onTap: () {},
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
                      child: const Center(
                        child: Text(
                          "Cancel Booking",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
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
