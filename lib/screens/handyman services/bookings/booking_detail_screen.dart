import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/services/booking_service.dart';
import 'package:zeerah/core/models/booking_model.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingService _bookingService = BookingService();
  Map<String, dynamic>? _bookingData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final response = await _bookingService.fetchBookingDetail(
      bookingId: widget.bookingId,
      token: userProvider.apiToken,
    );

    if (mounted) {
      setState(() {
        _bookingData = response;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.naturalWhite,
      appBar: AppBar(
        backgroundColor: AppColors.naturalWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.naturalBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Booking Details",
          style: TextStyle(
            color: AppColors.naturalBlack,
            fontSize: AppSizes.w(context, 20),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : _bookingData == null || _bookingData!['booking_detail'] == null
              ? const Center(child: Text("Booking details not found"))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final detail = _bookingData!['booking_detail'];
    final service = _bookingData!['service'] ?? {};
    final statusStr = detail['status']?.toString() ?? "pending";
    final status = BookingStatusExt.fromString(statusStr);
    final statusLabel = detail['status_label']?.toString() ?? status.value;

    return SingleChildScrollView(
      padding: EdgeInsets.all(Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          _buildStatusHeader(status, statusLabel, detail['id'].toString()),
          const SizedBox(height: 20),
          
          
          // Appointment Details
          _buildSectionTitle("Appointment Details"),
          _buildInfoTile(Icons.calendar_today_outlined, "Date", detail['booking_date'] ?? "N/A"),
          _buildInfoTile(Icons.access_time, "Time Slot", detail['booking_slot'] ?? "N/A"),
          _buildInfoTile(Icons.location_on_outlined, "Address", detail['address'] ?? "N/A"),
          const SizedBox(height: 24),

          // Provider/Handyman Info
          if (detail['provider_name'] != null) ...[
            _buildSectionTitle("Professional Info"),
            _buildProfessionalCard(detail, service),
            const SizedBox(height: 24),
          ],

          // Payment Summary
          _buildSectionTitle("Payment Summary"),
          _buildPaymentSummary(detail),
          const SizedBox(height: 24),

          // Booking Activity
          if (_bookingData!['booking_activity'] != null) ...[
            _buildSectionTitle("Booking Activity"),
            _buildActivityTimeline(_bookingData!['booking_activity']),
            const SizedBox(height: 32),
          ],

          // Cancel Button for Pending Bookings
          if (status == BookingStatus.pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showCancelDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryRed,
                    side: const BorderSide(color: AppColors.primaryRed),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Cancel Booking", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Booking"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Are you sure you want to cancel this booking?"),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: "Reason (Optional)",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking(reasonController.text);
            },
            child: const Text("Yes, Cancel", style: TextStyle(color: AppColors.primaryRed)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelBooking(String reason) async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await _bookingService.updateBookingStatus(
      bookingId: widget.bookingId,
      status: "cancelled",
      reason: reason.isEmpty ? "Changed my mind" : reason,
      token: userProvider.apiToken,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Booking cancelled successfully")),
        );
        _fetchDetail(); // Refresh the screen
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to cancel booking. Please try again.")),
        );
      }
    }
  }

  Widget _buildStatusHeader(BookingStatus status, String label, String id) {
    return Container(
      padding: EdgeInsets.all(Insets.sm),
      decoration: BoxDecoration(
        color: status == BookingStatus.completed ? AppColors.outerCompleted : AppColors.outerInProgress,
        borderRadius: BorderRadius.circular(Insets.sm),
        border: Border.all(color: status == BookingStatus.completed ? AppColors.neonGreen : AppColors.borderInProgress),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Booking ID: #$id",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                "Status: $label",
                style: TextStyle(
                  color: status == BookingStatus.completed ? AppColors.neonGreen : AppColors.primaryRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Icon(
            status == BookingStatus.completed ? Icons.check_circle : Icons.pending_actions,
            color: status == BookingStatus.completed ? AppColors.neonGreen : AppColors.primaryRed,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(dynamic detail, dynamic service, String imageUrl) {
    return Container(
      padding: EdgeInsets.all(Insets.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Insets.sm),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Insets.xs),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
              httpHeaders: const {},
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail['service_name'] ?? "Service",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "${UserMessages.serviceFee}: ",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    Text(
                      "₹${detail['price']}",
                      style: const TextStyle(
                        color: AppColors.priceOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 2),
              SizedBox(
                width: MediaQuery.of(context).size.width - 80,
                child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalCard(dynamic detail, dynamic service) {
    final rawHandy = _bookingData?['handyman_data'];
    final handyman = rawHandy is List ? (rawHandy.isNotEmpty ? rawHandy.first : {}) : (rawHandy ?? {});
    final providerImage = handyman['profile_image'] ?? service['provider_image'] ?? detail['provider_image'] ?? "";
    
    return Container(
      padding: EdgeInsets.all(Insets.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Insets.sm),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: (providerImage != null && providerImage.toString().startsWith('http')) 
                ? NetworkImage(providerImage.toString()) 
                : null,
            child: (providerImage == null || !providerImage.toString().startsWith('http')) 
                ? const Icon(Icons.person) 
                : null,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                handyman['display_name'] ?? detail['provider_name'] ?? "Professional",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    (handyman['handyman_rating'] ?? detail['total_rating'] ?? 5.0).toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(dynamic detail) {
    final double serviceFee = (detail['price'] ?? 0).toDouble();
    final double discountPercent = (detail['discount'] ?? 0).toDouble();
    final double discountAmount = (serviceFee * discountPercent) / 100;
    
    final List extraCharges = detail['extra_charges'] ?? [];
    final double extraChargesTotal = (detail['extra_charges_value'] ?? 0).toDouble();
    
    final double calculatedTotal = serviceFee - discountAmount + extraChargesTotal;
    final double displayTotal = (detail['payment_total_amount'] ?? calculatedTotal).toDouble();

    return Container(
      padding: EdgeInsets.all(Insets.sm),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(Insets.sm),
      ),
      child: Column(
        children: [
          _buildPaymentRow(
            "Total Amount", 
            "₹${displayTotal.toStringAsFixed(0)}", 
            isBold: true
          ),
          if (detail['payment_status'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Payment Status", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    detail['payment_status'].toString().toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: detail['payment_status'] == 'paid' ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isBold = false, bool isNegative = false, bool isPositive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isNegative ? Colors.green : (isPositive ? AppColors.priceOrange : Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline(List activity) {
    return Column(
      children: activity.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, size: 12, color: AppColors.primaryRed),
                  Container(height: 30, width: 2, color: Colors.grey[300]),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['activity_type'] ?? "Activity",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['activity_message'] ?? "",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['datetime'] ?? "",
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
