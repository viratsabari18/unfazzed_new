import 'package:cached_network_image/cached_network_image.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/widgets/custom/fade_animation_text.dart';

import '../../../core/models/new_booking_model.dart' show BookingModel, BookingStatus;

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;
  final VoidCallback onRateReview;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    required this.onRateReview,
  });

  Color getOuterColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.onHold:
        return AppColors.outerInProgress;
      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
      case BookingStatus.arrived:
        return AppColors.outerAccepted;
      case BookingStatus.inProgress:
        return AppColors.outerInProgress;
      case BookingStatus.completed:
        return AppColors.outerCompleted;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return AppColors.outerRejected;
      default:
        return AppColors.outerInProgress;
    }
  }

  Color getInnerColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.onHold:
        return AppColors.innerInProgress;
      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
      case BookingStatus.arrived:
        return AppColors.innerAccepted;
      case BookingStatus.inProgress:
        return AppColors.innerInProgress;
      case BookingStatus.completed:
        return AppColors.innerCompleted;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return AppColors.innerRejected;
      default:
        return AppColors.innerInProgress;
    }
  }

  Color getBorderColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.onHold:
        return AppColors.borderInProgress;
      case BookingStatus.accepted:
      case BookingStatus.onTheWay:
      case BookingStatus.arrived:
        return AppColors.pauseBlue;
      case BookingStatus.inProgress:
        return AppColors.borderInProgress;
      case BookingStatus.completed:
        return AppColors.neonGreen;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
        return AppColors.borderRejected;
      default:
        return AppColors.borderInProgress;
    }
  }

  String getStatusText() {
    if (booking.bookingStatus == BookingStatus.completed) {
      return booking.isPaymentPending ? "Payment Pending" : "Completed";
    }
    return booking.statusLabel?.isNotEmpty == true 
        ? booking.statusLabel! 
        : booking.bookingStatus.value;
  }


  @override
  Widget build(BuildContext context) {
    final status = booking.bookingStatus;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: Insets.sm),
        padding: EdgeInsets.all(Insets.xsm),
        decoration: BoxDecoration(
          color: getOuterColor(status),
          borderRadius: BorderRadius.circular(Insets.sm),
          border: Border.all(color: getBorderColor(status)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSizes.h(context, 8)),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Insets.xs),
                  child: CachedNetworkImage(
                    imageUrl: booking.displayImage.isEmpty 
                        ? UserMessages.serviceBookingDummy1 
                        : booking.displayImage,
                    height: AppSizes.h(context, 80),
                    width: AppSizes.w(context, 70),
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      height: AppSizes.h(context, 80),
                      width: AppSizes.w(context, 70),
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image),
                    ),
                    placeholder: (_, __) => Container(
                      height: AppSizes.h(context, 80),
                      width: AppSizes.w(context, 70),
                      color: Colors.grey.shade200,
                    ),
                  ),
                ),
                SizedBox(width: Insets.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildStatusChip(
                            context,
                            "#${booking.id}",
                            getBorderColor(status),
                            getInnerColor(status),
                          ),
                          const SizedBox(width: 4),
                          _buildStatusChip(
                            context,
                            getStatusText(),
                            getBorderColor(status),
                            getInnerColor(status),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.serviceName ?? "Service",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (status == BookingStatus.accepted)
                            BlinkingText(
                              text: UserMessages.currentlyAtYourService,
                              style: TextStyle(
                                fontSize: AppSizes.w(context, 11),
                                color: AppColors.blinkingRed,
                              ),
                            ),
                          Row(
                            children: [
                              const Text(
                                "Service Fee: ",
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              Text(
                                "₹${booking.totalAmount.toStringAsFixed(0)}",
                                style: TextStyle(
                                  color: AppColors.priceOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ].withSpaceBetween(height: AppSizes.h(context, 2)),
                      ),
                    ].withSpaceBetween(height: AppSizes.h(context, 6)),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.h(context, 10)),
            Container(
              padding: EdgeInsets.all(Insets.xsm),
              decoration: BoxDecoration(
                color: getInnerColor(status),
                borderRadius: BorderRadius.circular(Insets.sm),
              ),
              child: Column(
                children: [
                  _buildRowText(context, UserMessages.addressLabel, booking.address ?? "N/A"),
                  SizedBox(height: AppSizes.h(context, 12)),
                  _buildRowText(context, UserMessages.dateLabel, booking.bookingDate ?? "N/A"),
                ],
              ),
            ),
            SizedBox(height: AppSizes.h(context, 17)),
            if (status != BookingStatus.rejected && status != BookingStatus.cancelled)
              const Divider(color: Colors.black12),
            Row(
              children: [
                CircleAvatar(
                  radius: AppSizes.w(context, 18),
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: booking.handymanData?.profileImage ?? 
                               booking.providerImage ?? 
                               "",
                      height: AppSizes.h(context, 36),
                      width: AppSizes.w(context, 36),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Image.asset(
                        UserMessages.riderImage,
                        height: AppSizes.h(context, 36),
                        width: AppSizes.w(context, 36),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Insets.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
  booking.handymanData?.displayName ??
  booking.handymanData?.firstName ??
  booking.displayName,
),
                      SizedBox(height: AppSizes.h(context, 4)),
                      if (status != BookingStatus.cancelled && status != BookingStatus.rejected)
                        Text(
                          UserMessages.handyman,
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                if (status == BookingStatus.completed && !booking.isPaymentPending)
                  TextButton(
                    onPressed: onRateReview,
                    child: const Text(
                      "Rate & Review",
                      style: TextStyle(fontSize: 12, color: AppColors.primaryRed),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String text, Color textColor, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Insets.xs, vertical: Insets.xxs),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(Insets.md),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: AppSizes.w(context, 11),
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRowText(BuildContext context, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppSizes.w(context, 70),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}