import 'package:zeerah/core/common/app_exports.dart';

class PriceDetails extends StatefulWidget {
  final double totalAmount;
  final double discountAmount;
  final double discountPercent;

  const PriceDetails({
    required this.totalAmount,
    required this.discountAmount,
    required this.discountPercent,
    super.key,
  });

  @override
  State<PriceDetails> createState() => _PriceDetailsState();
}

class _PriceDetailsState extends State<PriceDetails> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            UserMessages.priceDetail,
            style: TextStyle(
              fontSize: AppSizes.w(context, 16),
              fontWeight: FontWeight.w500,
              color: AppColors.darkGrayText,
            ),
          ),
          SizedBox(height: AppSizes.h(context, 10)),
          Container(
            decoration: BoxDecoration(
              color: AppColors.softPeachBg,
              borderRadius: BorderRadius.circular(Insets.xsm),
            ),
            child: Column(
              children: [
                _priceRow(
                  context,
                  UserMessages.price,
                  '₹ ${widget.totalAmount.toStringAsFixed(2)}',
                  isRed: false,
                ),
                _divider(context),
                _priceRow(
                  context,
                 'discount (${widget.discountPercent.toInt()}%)',
                  '- ₹ ${widget.discountAmount.toStringAsFixed(2)}',
                  labelColor: AppColors.discountRed,
                  isRed: true,
                ),
                _divider(context),
                _priceRow(
                  context,
                  UserMessages.subtotal,
                '₹ ${(widget.totalAmount - widget.discountAmount).toStringAsFixed(2)}',
                  isRed: false,
                ),
                // _divider(context),
                // _priceRow(context, UserMessages.tax, '₹ 0.00', isRed: true),
                _divider(context),
                _priceRow(
                  context,
                  UserMessages.totalAmount,
                '₹ ${(widget.totalAmount - widget.discountAmount).toStringAsFixed(2)}',
                  isRed: false,
                  isBold: true,
                ),
              ],
            ),
          ),
          SizedBox(height: AppSizes.h(context, 20)),
          Text(
            UserMessages.disclaimerTitle,
            style: TextStyle(
              fontSize: AppSizes.w(context, 15),
              fontWeight: FontWeight.w500,
              color: AppColors.darkGrayText,
            ),
          ),
          SizedBox(height: AppSizes.h(context, 6)),
          Text(
            UserMessages.disclaimerText,
            style: TextStyle(
              fontSize: AppSizes.w(context, 13),
              color: AppColors.lightGrayText,
              height: 1.5,
            ),
          ),
          SizedBox(height: AppSizes.h(context, 16)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Insets.sm,
              vertical: Insets.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.softPeachBg,
              borderRadius: BorderRadius.circular(Insets.xsm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  UserMessages.bookingsCoins,
                  width: AppSizes.w(context, 48),
                  height: AppSizes.h(context, 48),
                  fit: BoxFit.contain,
                ),
                SizedBox(width: Insets.xsm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: AppSizes.w(context, 13),
                            color: AppColors.darkGrayText,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(text: UserMessages.completeBookingEarn),
                            TextSpan(
                              text: UserMessages.loyaltyPoints20,
                              style: TextStyle(
                                color: AppColors.discountRed,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: AppSizes.h(context, 4)),
                      Text(
                        UserMessages.redeemPointsText,
                        style: TextStyle(
                          fontSize: AppSizes.w(context, 11),
                          color: AppColors.lighterGrayText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    BuildContext context,
    String label,
    String value, {
    bool isRed = false,
    bool isBold = false,
    Color? labelColor,
  }) {
    final valueColor = isRed ? AppColors.discountRed : AppColors.darkGrayText;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Insets.sm,
        vertical: AppSizes.h(context, 13),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.w(context, 13.5),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w700,
              color: labelColor ?? AppColors.naturalBlack,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.w(context, 13.5),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) => Divider(
    height: 1,
    thickness: 1,
    color: AppColors.naturalWhite.withOpacity(0.6),
    indent: Insets.sm,
    endIndent: Insets.sm,
  );
}
