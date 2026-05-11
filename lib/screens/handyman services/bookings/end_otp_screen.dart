
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/services.dart/clipboard_service.dart';

class EndOtpView extends StatelessWidget {
  final String? totalTime;
  final String? otp;
  final dynamic bookingData;
  const EndOtpView({this.totalTime, this.otp, this.bookingData, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.endOtpBgColor,
        borderRadius:  BorderRadius.only(
          topLeft: Radius.circular(Insets.md),
          topRight: Radius.circular(Insets.md),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: AppSizes.h(context, 30)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Insets.lg),
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: AppSizes.h(context, 44),
                    bottom: AppSizes.h(context, 45),
                    left: Insets.xl,
                    right: Insets.xl,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.endOtpCardRed,
                    borderRadius: BorderRadius.circular(Insets.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.naturalBlack.withOpacity(0.18),
                        blurRadius: AppSizes.w(context, 12),
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: Insets.md,
                          vertical: Insets.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.naturalWhite,
                          borderRadius: BorderRadius.circular(Insets.sm),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.naturalBlack12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          otp ?? UserMessages.endOtpCode,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppSizes.w(context, 32),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 19,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (totalTime != null)
                  Positioned(
                    bottom: -AppSizes.h(context, 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.naturalWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "Total Time: $totalTime",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: -AppSizes.h(context, 15),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Insets.md,
                      vertical: Insets.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.naturalWhite,
                      borderRadius: BorderRadius.circular(Insets.md),
                      boxShadow: const [
                        BoxShadow(color: AppColors.naturalBlack12, blurRadius: 6),
                      ],
                    ),
                    child: Text(
                      UserMessages.endOtpLabel,
                      style: TextStyle(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: AppSizes.w(context, 13),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -AppSizes.h(context, 18),
                  child: GestureDetector(
                    onTap: () {
                      copydata(context, UserMessages.endOtpCode);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Insets.md,
                        vertical: Insets.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.endOtpCopyButtonColor,
                        borderRadius: BorderRadius.circular(Insets.xsm),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.naturalBlack26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy, color: AppColors.naturalWhite, size: 16),
                          SizedBox(width: Insets.xs),
                          Text(
                            UserMessages.copyOtp,
                            style: TextStyle(
                              color: AppColors.naturalWhite,
                              fontWeight: FontWeight.w600,
                              fontSize: AppSizes.w(context, 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSizes.h(context, 40)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Insets.sm),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: UserMessages.shareThis,
                    style: const TextStyle(color: AppColors.naturalBlack),
                  ),
                  TextSpan(
                    text: UserMessages.code,
                    style: TextStyle(
                      color: AppColors.discountRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: UserMessages.withHandymanTo,
                    style: const TextStyle(color: AppColors.naturalBlack),
                  ),
                  TextSpan(
                    text: UserMessages.finish,
                    style: TextStyle(
                      color: AppColors.discountRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: UserMessages.theJob,
                    style: const TextStyle(color: AppColors.naturalBlack),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: AppSizes.h(context, 30)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Insets.md),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.ratingsAndReview,
                      arguments: {'booking_data': bookingData},
                    );
                  },
                  child: Container(
                    height: AppSizes.h(context, 55),
                    decoration: BoxDecoration(
                      color: AppColors.naturalWhite,
                      border: Border.all(width: 0.2, color: AppColors.naturalBlack),
                      borderRadius: BorderRadius.circular(Insets.sm),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.naturalBlack12,
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: AppColors.starColor),
                          SizedBox(width: 6),
                          Text(UserMessages.rateService),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.h(context, 16)),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: AppSizes.h(context, 55),
                    decoration: BoxDecoration(
                      color: AppColors.naturalWhite,
                      borderRadius: BorderRadius.circular(Insets.sm),
                      border: Border.all(width: 0.2, color: AppColors.naturalBlack),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.naturalBlack12,
                          blurRadius: 17,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.support_agent),
                          SizedBox(width: 6),
                          Text(UserMessages.support),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
  
        ],
      ),
    );
  }
}
