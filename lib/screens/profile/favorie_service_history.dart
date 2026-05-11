import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/models/favorite_service.dart';

import 'package:provider/provider.dart';
import 'package:zeerah/core/providers/favorites_provider.dart';

class FavorieServiceHistory extends StatefulWidget {
  const FavorieServiceHistory({super.key});

  @override
  State<FavorieServiceHistory> createState() => _FavorieServiceHistoryState();
}

class _FavorieServiceHistoryState extends State<FavorieServiceHistory> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        title: Text(
          UserMessages.favouriteServices,
          style: TextStyle(
            color: AppColors.naturalWhite,
            fontSize: AppSizes.w(context, 20),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
         icon: Icon(Icons.arrow_back_ios,
          color: AppColors.naturalWhite,)
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Insets.md,
              vertical: Insets.md,
            ),
            child: Text.rich(
              TextSpan(
                text: UserMessages.hereAreYourFavourite,
                style: const TextStyle(),
                children: [
                  TextSpan(
                    text: UserMessages.servicesLower,
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<FavoritesProvider>(
              builder: (context, favoritesProvider, child) {
                final services = favoritesProvider.favorites;
                if (services.isEmpty) {
                  return const Center(
                    child: Text(
                      "No favorite services yet.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }
                return GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: Insets.xsm),
                  itemCount: services.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.63,
                  ),
                  itemBuilder: (_, index) {
                    final item = services[index];
                    return ServiceCard(
                      item: item,
                      onFavoriteTap: () {
                        favoritesProvider.toggleFavorite(item);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final FavoriteService item;
  final VoidCallback onFavoriteTap;

  const ServiceCard({
    super.key,
    required this.item,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.naturalWhite,
        borderRadius: BorderRadius.circular(Insets.sm),
        boxShadow: [
          BoxShadow(
            color: AppColors.naturalBlack.withOpacity(0.05),
            blurRadius: AppSizes.w(context, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildImage(context),
          SizedBox(height: AppSizes.h(context, 6)),
          _buildTitle(context),
          SizedBox(height: AppSizes.h(context, 4)),
          _buildRating(context),
          SizedBox(height: AppSizes.h(context, 2)),
          _buildReviews(context),
          SizedBox(height: AppSizes.h(context, 4)),
          _buildPrice(context),
          SizedBox(height: AppSizes.h(context, 6)),
          _buildButton(context),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(Insets.xs),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(Insets.sm)),
            child: Image.network(
              item.serviceImage,
              height: AppSizes.h(context, 110),
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: AppSizes.h(context, 110),
                color: Colors.grey.shade300,
                child: const Icon(Icons.image),
              ),
            ),
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: GestureDetector(
            onTap: onFavoriteTap,
            child: CircleAvatar(
              radius: AppSizes.w(context, 14),
              backgroundColor: AppColors.naturalWhite,
              child: Icon(
                item.isFavorite ? Icons.favorite : Icons.favorite_border,
                size: AppSizes.w(context, 18),
                color: AppColors.primaryRed,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      item.serviceTitle,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: AppSizes.w(context, 12),
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRating(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StarRating(rating: item.rating),
        SizedBox(width: AppSizes.w(context, 4)),
        Text(
          "${item.rating}",
          style: TextStyle(fontSize: AppSizes.w(context, 10)),
        ),
      ],
    );
  }

  Widget _buildReviews(BuildContext context) {
    return Text(
      "${item.reviewsCount} ${UserMessages.reviews}",
      style: TextStyle(
        fontSize: AppSizes.w(context, 11),
        color: AppColors.naturalGray,
      ),
    );
  }

  Widget _buildPrice(BuildContext context) {
    return Text(
      "₹${item.rate}",
      style: TextStyle(
        color: AppColors.priceYellow,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Container(
      height: AppSizes.h(context, 32),
      width: AppSizes.w(context, 70),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(Insets.xs),
      ),
      child: Center(
        child: Text(
          UserMessages.bookNow,
          style: TextStyle(
            color: AppColors.naturalWhite,
            fontSize: AppSizes.w(context, 10),
          ),
        ),
      ),
    );
  }
}

class StarRating extends StatelessWidget {
  final double rating;
  final int starCount;

  const StarRating({super.key, required this.rating, this.starCount = 5});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        return _buildStar(context, index);
      }),
    );
  }

  Widget _buildStar(BuildContext context, int index) {
    double starValue = index + 1;

    if (rating >= starValue) {
      return Icon(
        Icons.star,
        color: AppColors.starOrange,
        size: AppSizes.w(context, 14),
      );
    } else if (rating > index && rating < starValue) {
      double fill = rating - index;
      return Stack(
        children: [
          Icon(
            Icons.star_border,
            color: AppColors.starOrange,
            size: AppSizes.w(context, 14),
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: fill,
              child: Icon(
                Icons.star,
                color: AppColors.starOrange,
                size: AppSizes.w(context, 14),
              ),
            ),
          ),
        ],
      );
    } else {
      return Icon(
        Icons.star_border,
        color: AppColors.starOrange,
        size: AppSizes.w(context, 14),
      );
    }
  }
}
