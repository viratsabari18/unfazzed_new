import 'package:zeerah/core/common/app_exports.dart';

class SocialButton extends StatelessWidget {
  final String image;
  final String text;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const SocialButton({
    super.key,
    required this.image,
    required this.text,
    required this.width,
    required this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: height * 0.07,
        padding: EdgeInsets.symmetric(horizontal: Insets.sm),
        decoration: BoxDecoration(
          color: AppColors.naturalWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.naturalGray),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image, height: height * 0.03, width: height * 0.03),
            SizedBox(width: Insets.xs),
            Text(
              text,
              style: TextStyles.bodyLarge.copyWith(
                fontSize: width * 0.04,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
