import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/screens/handyman%20services/bookings/service_in_progess.dart';

class BookingServiceProgressHome extends StatefulWidget {
  final int serviceDurationInSeconds; // Pass duration from first widget
  final dynamic bookingData;
  final DateTime? startTime;
  final DateTime? completionTime;
  final String? price;
  
  const BookingServiceProgressHome({
    Key? key, 
    required this.serviceDurationInSeconds,
    this.bookingData,
    this.startTime,
    this.completionTime,
    this.price, 
  }) : super(key: key);

  @override
  State<BookingServiceProgressHome> createState() =>
      _BookingServiceProgressHomeState();
}

class _BookingServiceProgressHomeState extends State<BookingServiceProgressHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryRed,
     appBar: AppBar(
  leading: IconButton(
    icon: const Icon(
      Icons.arrow_back,
      color: AppColors.naturalWhite,
    ),
    onPressed: (){
      Navigator.pushNamed(context, AppRoutes.landingPage);
    },
  ),
  elevation: 0,
  toolbarHeight: AppSizes.h(context, 40),
  centerTitle: true,
  backgroundColor: AppColors.primaryRed,

  title: Builder(
    builder: (context) {
      final bData = widget.bookingData is List
          ? (widget.bookingData as List).first
          : widget.bookingData;

      final rawDetail = bData?['booking_detail'];

      final detail = rawDetail is List
          ? (rawDetail.isNotEmpty ? rawDetail.first : {})
          : rawDetail;

      final status = detail?['status']
              ?.toString()
              .toLowerCase()
              .trim() ??
          "";

      return Text(
        status == 'pending_approval' ||
                status == 'completed'
            ? "Service Completed"
            : UserMessages.serviceInProgress,
        style: TextStyle(
          color: AppColors.naturalWhite,
          fontSize: AppSizes.w(context, 20),
        ),
      );
    },
  ),
),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ServiceInProgress(
              serviceDuration: widget.serviceDurationInSeconds, 
              bookingData: widget.bookingData, // Pass data for API polling
              startTime: widget.startTime,
              completionTime: widget.completionTime,
              price: widget.price,
            ),
          ),
        ],
      ),
    );
  }
}
