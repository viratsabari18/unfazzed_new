// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/core/providers/dashboard_provider.dart';
import 'package:zeerah/screens/home/coming_soon_section.dart';

class ExpolreCategoriesStack extends StatelessWidget {
  const ExpolreCategoriesStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        final addressProvider = Provider.of<AddressProvider>(context);

        final location = addressProvider.selectedLocation;

        if (location == null) {
          return const SizedBox.shrink();
        }

        final subCategories = dashboardProvider.currentSubCategories;

        final List<CategoryItem> items = [];
        final Set<String> uniqueTitles = {};

        for (var sc in subCategories) {
          final String title = sc['name'] ?? "";

          final dynamic rawCount = sc['services_count'] ?? sc['service_count'];

          if (rawCount != null) {
            final int count = int.tryParse(rawCount.toString()) ?? 0;

            if (count == 0) continue;
          }

          if (title.isNotEmpty && !uniqueTitles.contains(title)) {
            uniqueTitles.add(title);

            items.add(
              CategoryItem(
                id: sc['id'],
                title: title,
                image: sc['image'] ?? "",
                subtitle:
                    sc['description'] ??
                    "Professional service at your doorstep",
              ),
            );
          }
        }

        if (dashboardProvider.isSubCategoryLoading) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.56,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.red),
            ),
          );
        }

        if (dashboardProvider.isLoading && items.isEmpty) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.56,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            ),
          );
        }

        if (dashboardProvider.categories.isEmpty &&
            !dashboardProvider.isLoading) {
          return const SizedBox.shrink();
        }

        if (items.isEmpty && !dashboardProvider.isLoading) {
          return ComingSoonSection();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.56,
              child: EditorPickCarousel(
                items: items,
                categoryName:
                    dashboardProvider.categories.firstWhere(
                      (c) => c['id'] == dashboardProvider.selectedCategoryId,
                      orElse: () => {'name': ''},
                    )['name'] ??
                    "",
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class EditorPickCarousel extends StatefulWidget {
  final List<CategoryItem> items;
  final String categoryName;

  const EditorPickCarousel({
    super.key,
    required this.items,
    required this.categoryName,
  });

  @override
  State<EditorPickCarousel> createState() => _EditorPickCarouselState();
}

class _EditorPickCarouselState extends State<EditorPickCarousel> {
  late PageController _controller;
  late int _baseOffset;

  static const double _stackScaleStep = 0.07;
  static const double _stackXStep = 44.0;
  static const double _stackOpacityStep = 0.32;
  static const double _leftPeekFraction = 1.08;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _baseOffset = (1000 * widget.items.length).toInt();

    _controller = PageController(
      viewportFraction: 1.0,
      initialPage: _baseOffset,
    );
  }

  @override
  void didUpdateWidget(EditorPickCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.items.length != widget.items.length ||
        oldWidget.categoryName != widget.categoryName) {
      _initController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _page {
    if (!_controller.hasClients) {
      return _controller.initialPage.toDouble();
    }

    final pos = _controller.position;

    if (!pos.hasPixels || !pos.hasContentDimensions) {
      return _controller.initialPage.toDouble();
    }

    return _controller.page ?? _controller.initialPage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final cardWidth = w * 0.76;

        final cardHeight = (h - 10).clamp(0.0, cardWidth * 1.55);

        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return _buildStackedCards(
                        page: _page,
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                      );
                    },
                  ),
                ),
              ),

              Positioned.fill(
                child: PageView.builder(
                  controller: _controller,
                  physics: widget.items.length <= 1
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                  itemBuilder: (context, index) {
                    final realIndex =
                        (((index % widget.items.length) + widget.items.length) %
                                widget.items.length)
                            .toInt();

                    final item = widget.items[realIndex];

                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.cleaningServices,
                          arguments: {
                            'subcategoryName': item.title,
                            'subcategoryId': item.id,
                            'parentCategoryName': widget.categoryName,
                          },
                        );
                      },
                      child: const SizedBox.expand(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStackedCards({
    required double page,
    required double cardWidth,
    required double cardHeight,
  }) {
    final n = widget.items.length;
    final centerV = page.floor();

    final entries = <_RenderEntry>[];

    for (var offset = -2; offset <= 4; offset++) {
      final vi = centerV + offset;
      final delta = vi - page;

      if (delta < -1.2 || delta > 3.2) {
        continue;
      }

      final realIndex = (((vi % n) + n) % n).toInt();

      if (n < 5 && entries.any((e) => e.index == realIndex)) {
        final existing = entries.firstWhere((e) => e.index == realIndex);

        if (delta.abs() < existing.delta.abs()) {
          entries.remove(existing);

          entries.add(_RenderEntry(index: realIndex, delta: delta));
        }

        continue;
      }

      entries.add(_RenderEntry(index: realIndex, delta: delta));
    }

    entries.sort((a, b) => b.delta.compareTo(a.delta));

    return Stack(
      alignment: Alignment.center,
      children: [
        for (final e in entries)
          _buildPositionedCard(
            item: widget.items[e.index],
            delta: e.delta,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
          ),
      ],
    );
  }

  Widget _buildPositionedCard({
    required CategoryItem item,
    required double delta,
    required double cardWidth,
    required double cardHeight,
  }) {
    late final double scale;
    late final double xOffset;
    late final double opacity;

    if (delta >= 0) {
      final d = delta;

      scale = (1.0 - _stackScaleStep * d).clamp(0.6, 1.0);

      xOffset = _stackXStep * d;

      opacity = (1.0 - _stackOpacityStep * d).clamp(0.0, 1.0);
    } else {
      final t = -delta;

      scale = 1.0;

      xOffset = -cardWidth * _leftPeekFraction * t;

      opacity = (1.0 - 0.25 * t).clamp(0.0, 1.0);
    }

    return Transform.translate(
      offset: Offset(xOffset, 0),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: IgnorePointer(
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: _ImageView(item: item),
            ),
          ),
        ),
      ),
    );
  }
}

class _RenderEntry {
  final int index;
  final double delta;

  const _RenderEntry({required this.index, required this.delta});
}

class _ImageView extends StatelessWidget {
  final CategoryItem item;

  const _ImageView({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = item.image;

    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        httpHeaders: const {},
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) =>
            _buildLoadingWidget(),
        errorWidget:
            (context, url, error) =>
                _buildErrorWidget(),
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) =>
            _buildErrorWidget(),
      );
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: Colors.white24,
            ),
            SizedBox(height: 8),
            Text(
              'Failed to load image',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.amber,
          strokeWidth: 2,
        ),
      ),
    );
  }
}