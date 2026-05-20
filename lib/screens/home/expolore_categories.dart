import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/core/providers/dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zeerah/screens/home/coming_soon_section.dart';

class ExpoloreCategories extends StatelessWidget {
  const ExpoloreCategories({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        final addressProvider = Provider.of<AddressProvider>(context);

        final location = addressProvider.selectedLocation;

        if (location == null) {
          return const SizedBox.shrink();
        }

        final categories = dashboardProvider.categories;

        if (dashboardProvider.isLoading && categories.isEmpty) {
          return const SizedBox.shrink();
        }

        if (categories.isEmpty && !dashboardProvider.isLoading) {
          return const ComingSoonSection();
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

            SizedBox(height: Insets.sm),

            SizedBox(
              height: AppSizes.h(context, 140),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: Insets.xs),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final item = categories[index];

                  final isSelected =
                      dashboardProvider.selectedCategoryId == item['id'];

                  return GestureDetector(
                    onTap: () =>
                        dashboardProvider.selectCategory(item['id']),
                    child: _CategoryItem(
                      title: item["name"] ?? "",
                      image: item["image"] ?? "",
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
    return Container(
      width: AppSizes.w(context, 110),
      margin: EdgeInsets.symmetric(horizontal: Insets.xxs),
   

      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFFFF1F1)
            : AppColors.naturalWhite,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(
          color: isSelected
              ? Colors.red
              : Colors.grey,
          width: isSelected? 2:1,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
      ClipRRect(
  borderRadius: const BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
  ),
  child: Container(
    height: AppSizes.h(context, 90),
    width: double.infinity,
    color: Colors.grey.shade100,
    child: image.startsWith('http')
        ? CachedNetworkImage(
            imageUrl: image,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
            errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image),
          )
        : Image.asset(
            image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image),
          ),
  ),
),
          

          Expanded(
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,

                style: TextStyle(
                  fontSize: AppSizes.w(context, 13),
                  fontWeight: FontWeight.w600,
                  color: AppColors.naturalBlack,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}