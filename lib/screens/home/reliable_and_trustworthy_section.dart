
import 'package:zeerah/core/common/app_exports.dart';

class ReliableAndTrustworthySection extends StatelessWidget {
  const ReliableAndTrustworthySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 20),

          /// Title
          Text(
            "Reliable & Trustworthy",
            style: TextStyles.bodyMedium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.naturalBlack,
            ),
          ),

          const SizedBox(height: 10),

          /// Subtitle
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyles.bodySmall.copyWith(
               fontWeight: FontWeight.w400,
               fontSize: 13,
                color: AppColors.naturalBlack,
              ),
              children: [
                const TextSpan(
                  
                  text: "Unfazzed ",
                  style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: "ensures integrity through verified standards",
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// Cards Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCard(
                image: "lib/assets/images/girl2.png",
                title: "Verified Professionals You Can Trust",
              ),
              _buildCard(
                image: "lib/assets/images/girl3.png",
                title: "Well Trained To Deliver Great Service",
              ),
              _buildCard(
                image: "lib/assets/images/girl4.png",
                title: "Safe, Reliable & Consistent Every Single Time",
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String image,
    required String title,
  }) {
    return Expanded(
      child: Column(
        children: [
          /// Image Container
          Container(
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade200,
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              image,
              fit: BoxFit.cover, // ✅ FIX: fills fully (no grey bottom issue)
              width: double.infinity,
              cacheHeight: 500, // Optimize loading for large images
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey, size: 30),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          /// Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyles.bodyMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.naturalBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
