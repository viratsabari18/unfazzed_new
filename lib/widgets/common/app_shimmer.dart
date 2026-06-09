
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:zeerah/core/common/insets.dart';
import 'package:zeerah/core/utils/app_sizes.dart';

class AppShimmer extends StatelessWidget {
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const AppShimmer({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: height,
        width: width,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              borderRadius ?? BorderRadius.circular(12),
        ),
      ),
    );
  }
}
class AppCircleShimmer extends StatelessWidget {
  final double size;

  const AppCircleShimmer({
    super.key,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: size,
        width: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class AppCardShimmer extends StatelessWidget {
  final double height;

  const AppCardShimmer({
    super.key,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      height: height,
      width: double.infinity,
      borderRadius: BorderRadius.circular(20),
    );
  }
}

class CategoryShimmer extends StatelessWidget {
  const CategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.h(context, 120),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: 6, // Show 6 shimmer items
        itemBuilder: (context, index) {
          return Container(
            width: AppSizes.w(context, 90),
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AppShimmer(
                      height: double.infinity,
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                AppShimmer(
                  height: 14,
                  width: 60,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                AppShimmer(
                  height: 3,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(100),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CarouselShimmer extends StatelessWidget {
  const CarouselShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height * 0.56;
    
    return SizedBox(
      height: screenHeight,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.76,
          height: (screenHeight - 10).clamp(0.0, MediaQuery.of(context).size.width * 0.76 * 1.55),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.42),
              width: 2.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: AppShimmer(
              height: double.infinity,
              width: double.infinity,
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ),
    );
  }
}

class ServiceCardShimmer extends StatelessWidget {
  const ServiceCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          /// IMAGE SECTION SHIMMER
          SizedBox(
            width: double.infinity,
            height: AppSizes.h(context, 140),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(AppSizes.w(context, 8)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AppShimmer(
                      height: double.infinity,
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          /// CONTENT SHIMMER
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.w(context, 10),
              vertical: AppSizes.h(context, 8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Service Name Shimmer
                AppShimmer(
                  height: 14,
                  width: AppSizes.w(context, 100),
                  borderRadius: BorderRadius.circular(4),
                ),
                SizedBox(height: AppSizes.h(context, 6)),
                
                /// Price and Button Shimmer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// Price Shimmer
                    AppShimmer(
                      height: 16,
                      width: AppSizes.w(context, 60),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    /// Button Shimmer
                    AppShimmer(
                      height: 28,
                      width: AppSizes.w(context, 70),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BookingCardShimmer extends StatelessWidget {
  const BookingCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: Insets.sm),
      padding: EdgeInsets.all(Insets.xsm),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(Insets.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSizes.h(context, 8)),
          Row(
            children: [
              // Image shimmer
              AppShimmer(
                height: AppSizes.h(context, 80),
                width: AppSizes.w(context, 70),
                borderRadius: BorderRadius.circular(Insets.xs),
              ),
              SizedBox(width: Insets.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID and status shimmers
                    Row(
                      children: [
                        AppShimmer(
                          height: 20,
                          width: 50,
                          borderRadius: BorderRadius.circular(Insets.md),
                        ),
                        const SizedBox(width: 4),
                        AppShimmer(
                          height: 20,
                          width: 80,
                          borderRadius: BorderRadius.circular(Insets.md),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.h(context, 6)),
                    // Service name shimmer
                    AppShimmer(
                      height: 16,
                      width: 150,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(height: AppSizes.h(context, 4)),
                    // Price shimmer
                    AppShimmer(
                      height: 12,
                      width: 100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSizes.h(context, 10)),
          // Address and date shimmers
          Container(
            padding: EdgeInsets.all(Insets.xsm),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(Insets.sm),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    AppShimmer(
                      height: 12,
                      width: 50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(width: 8),
                    AppShimmer(
                      height: 12,
                      width: 150,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                SizedBox(height: AppSizes.h(context, 12)),
                Row(
                  children: [
                    AppShimmer(
                      height: 12,
                      width: 40,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(width: 8),
                    AppShimmer(
                      height: 12,
                      width: 120,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: AppSizes.h(context, 17)),
          // Handyman shimmer
          Row(
            children: [
              AppShimmer(
                height: 36,
                width: 36,
                borderRadius: BorderRadius.circular(18),
              ),
              SizedBox(width: Insets.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppShimmer(
                      height: 14,
                      width: 100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(height: AppSizes.h(context, 4)),
                    AppShimmer(
                      height: 10,
                      width: 60,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}