import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ExpoloreCategories extends StatelessWidget {
  const ExpoloreCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        final categories = dashboardProvider.categories;

        if (dashboardProvider.isLoading && categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Insets.sm),
              child: Text(
                UserMessages.exploreCategories,
                style: TextStyle(
                  fontSize: AppSizes.w(context, 18),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              height: AppSizes.h(context, 130),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: Insets.xsm),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final item = categories[index];
                  final isSelected = dashboardProvider.selectedCategoryId == item['id'];
                  
                  return GestureDetector(
                    onTap: () => dashboardProvider.selectCategory(item['id']),
                    child: _CategoryItem(
                      title: item["name"]!,
                      image: item["image"]!,
                      isSelected: isSelected,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String title;
  final String image;
  final bool isSelected;

  const _CategoryItem({
    required this.title,
    required this.image,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Insets.xxs),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: AppSizes.h(context, 80),
            width: AppSizes.w(context, 80),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryYellow : AppColors.naturalWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.naturalBlack.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(Insets.xs),
              child: image.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: image,
                      httpHeaders: const {},
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                    )
                  : Image.asset(
                      image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                    ),
            ),
          ),
          SizedBox(height: Insets.xxs),
          SizedBox(
            width: AppSizes.w(context, 85),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppSizes.w(context, 10),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.naturalBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
