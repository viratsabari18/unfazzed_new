// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/dashboard_provider.dart';

class ExpolreCategoriesStack extends StatelessWidget {
  const ExpolreCategoriesStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, _) {
        final subCategories = dashboardProvider.currentSubCategories;
        
        // Map dynamic sub-categories to CategoryItem format for the carousel, deduplicating by title
        final List<CategoryItem> items = [];
        final Set<String> uniqueTitles = {};
        
        for (var sc in subCategories) {
          final String title = sc['name'] ?? "";
          
          // Filter out sub-categories that have zero services if the backend provides a count
          final dynamic rawCount = sc['services_count'] ?? sc['service_count'];
          if (rawCount != null) {
            final int count = int.tryParse(rawCount.toString()) ?? 0;
            if (count == 0) continue; 
          }

          if (title.isNotEmpty && !uniqueTitles.contains(title)) {
            uniqueTitles.add(title);
            items.add(CategoryItem(
              id: sc['id'],
              title: title,
              image: sc['image'] ?? "",
              subtitle: sc['description'] ?? "Professional service at your doorstep",
            ));
          }
        }

        if (dashboardProvider.isLoading && items.isEmpty) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: const Center(child: CircularProgressIndicator(color: AppColors.primaryRed)),
          );
        }

        if (dashboardProvider.categories.isEmpty && !dashboardProvider.isLoading) {
          return const SizedBox.shrink();
        }

        if (items.isEmpty && !dashboardProvider.isLoading) {
          // Show a placeholder card if no items are found
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.74,
                    height: MediaQuery.of(context).size.height * 0.35,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.construction_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          "Services Coming Soon",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "We're working on adding more services here",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: EditorPickCarousel(
                items: items, 
                categoryName: dashboardProvider.categories.firstWhere(
                  (c) => c['id'] == dashboardProvider.selectedCategoryId,
                  orElse: () => {'name': ''}
                )['name'] ?? "",
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

  // Tuning knobs for the stack depth effect.
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
    if (oldWidget.items.length != widget.items.length || oldWidget.categoryName != widget.categoryName) {
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
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final cardWidth = w * 0.74;
        final cardHeight = (h - 40).clamp(0.0, cardWidth * 1.55);

        return Stack(
          children: [
            // Gesture surface
            Positioned.fill(
              child: PageView.builder(
                controller: _controller,
                physics: widget.items.length <= 1 
                    ? const NeverScrollableScrollPhysics() 
                    : const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                itemBuilder: (_, __) => const SizedBox.expand(),
              ),
            ),

            // Visual layer
            Positioned.fill(
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
          ],
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
      if (delta < -1.2 || delta > 3.2) continue;
      final realIndex = (((vi % n) + n) % n).toInt();
      
      // For small collections, avoid showing the same item twice in the stack
      if (n < 5 && entries.any((e) => e.index == realIndex)) {
        // If we already have this index, only keep the one closer to the front (delta near 0)
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
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: _ImageView(item: item, categoryName: widget.categoryName,subCategoryId: item.id,),
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
  final String categoryName;  
  final int subCategoryId;   
  const _ImageView({required this.item, required this.categoryName, required this.subCategoryId});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          ignoring: true,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox.expand(child: _buildImage()),
          ),
        ),
        Positioned(
          left: 10,
          right: 10,
          bottom: 12,
          child: _BookNowButton(item: item, categoryName: categoryName,subCategoryId: subCategoryId,),
        ),
      ],
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
        placeholder: (context, url) => _buildLoadingWidget(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildErrorWidget(),
      );
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.white24),
            SizedBox(height: 8),
            Text('Failed to load image', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2),
      ),
    );
  }
}

class _BookNowButton extends StatefulWidget {
  final CategoryItem item;
  final String categoryName;
   final int subCategoryId;  

  const _BookNowButton({
    Key? key,
    required this.item,
    required this.categoryName,
    required this.subCategoryId,

  }) : super(key: key);

  @override
  State<_BookNowButton> createState() => _BookNowButtonState();
}

class _BookNowButtonState extends State<_BookNowButton> {
  double _dragOffset = 0;

  void _onDragUpdate(DragUpdateDetails details, double maxWidth) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(0, maxWidth - 60);
    });
  }

  void _onDragEnd(DragEndDetails details, double maxWidth) {
    if (_dragOffset >= (maxWidth - 60) * 0.7) {
      HapticFeedback.mediumImpact();
      final String capturedCategory = widget.categoryName;
      setState(() => _dragOffset = 0);
      Navigator.pushNamed(
        context,
        AppRoutes.cleaningServices, 
        arguments: {
         'subcategoryName': widget.item.title,      
          'subcategoryId': widget.subCategoryId,    
          'parentCategoryName': widget.categoryName,
        },
      );
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        return ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                gradient: LinearGradient(
                  colors: [const Color(0xFFC0A040).withOpacity(0.3), const Color(0xFF408080).withOpacity(0.3)],
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Opacity(
                      opacity: (1 - (_dragOffset / (totalWidth - 60))).clamp(0.2, 1.0),
                      child: const Text('Swipe to Book', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
                      child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                    ),
                  ),
                  Positioned(
                    left: _dragOffset,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (d) => _onDragUpdate(d, totalWidth),
                      onHorizontalDragEnd: (d) => _onDragEnd(d, totalWidth),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF131B1B)),
                        child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
