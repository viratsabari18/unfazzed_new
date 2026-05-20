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
              height: AppSizes.h(context, 120),

              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
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
      width: AppSizes.w(context, 95),

      margin: EdgeInsets.zero,

      child: Column(
        children: [
          /// IMAGE WITH GAP
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),

              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        isSelected ? 0.15 : 0.05,
                      ),

                      blurRadius: isSelected ? 10 : 5,

                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: Padding(
                  padding: const EdgeInsets.all(4),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),

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

                            errorBuilder:
                                (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image),
                          ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          /// TEXT
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: AppSizes.w(context, 13),

              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w500,

              color: isSelected
                  ? const Color(0xFFD92D20)
                  : Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 4),

          /// CONNECTED TABBAR LINE
          Container(
            height: isSelected?3:0.3,
            width: double.infinity,

            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFD92D20)
                  : Colors.grey.shade300,

              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ],
      ),
    );
  }
}