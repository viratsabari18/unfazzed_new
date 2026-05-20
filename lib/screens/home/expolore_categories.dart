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
              height: AppSizes.h(context,150),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: _CategoryItem(
                        title: item["name"] ?? "",
                        image: item["image"] ?? "",
                        isSelected: isSelected,
                      ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),

      width: AppSizes.w(context, 102),

      margin: EdgeInsets.symmetric(horizontal: Insets.xxs),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

     border: Border.all(
  color: isSelected
      ? Colors.black
      : Colors.transparent,
  width: 1.5,
),

    boxShadow: [
  BoxShadow(
    color: isSelected
        ? Colors.black.withOpacity(0.40)
        : Colors.transparent,

    blurRadius: 10,

    spreadRadius: isSelected ? 1 : 0,
 
  ),
],
      ),

      child: Column(
        children: [
          /// IMAGE
          Padding(
            padding:  EdgeInsets.symmetric(horizontal: 4,vertical:4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              
              child: SizedBox(
                height: AppSizes.h(context, 92),

                width: double.infinity,

                child: image.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,

                        placeholder: (context, url) => Center(
                          child: SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red.shade300,
                            ),
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
          ),

          /// TITLE
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Insets.xs,
              ),

              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize: AppSizes.w(context, 13),

                    fontWeight: isSelected
                        ? FontWeight.w900
                        : FontWeight.w600,

                    color: isSelected
                        ? const Color(0xFFD92D20)
                        : const Color(0xFF444444),

                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 4,)
        ],
      ),
    );
  }
}