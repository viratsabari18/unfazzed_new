import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/dashboard_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeOfferSection extends StatelessWidget {
  const HomeOfferSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final offers = dashboard.offers;
        if (offers.isEmpty) return const SizedBox.shrink();

        return _buildOfferSection(context, offers);
      },
    );
  }

  Widget _buildOfferSection(BuildContext context, List<Map<String, dynamic>> offers) {
    final w = MediaQuery.of(context).size.width;
    
    // Large card is always the first offer
    final featuredOffer = offers[0];
    
    // Small cards are the next 4 offers (if available)
    final gridOffers = offers.skip(1).take(4).toList();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(35),
          topRight: Radius.circular(35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Offer for you',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.naturalBlack,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 230,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Featured Large Card (Left) - Always takes the first offer
                  Expanded(
                    flex: 11, 
                    child: _buildFeaturedOfferCard(featuredOffer),
                  ),
                  const SizedBox(width: 10),
                  
                  // 2x2 Grid of Small Cards (Right) - Takes offers 2 to 5
                  Expanded(
                    flex: 19,
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: gridOffers.isNotEmpty 
                                  ? _buildSmallOfferCard(gridOffers[0], 0)
                                  : _buildPlaceholderCard('Bundle\n& Save', 'Up to 25%', const Color(0xFFFF6B6B)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: gridOffers.length > 1 
                                  ? _buildSmallOfferCard(gridOffers[1], 1)
                                  : _buildPlaceholderCard('Refer\n& Earn', '50 Points', const Color(0xFF5D8BF4)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: gridOffers.length > 2 
                                  ? _buildSmallOfferCard(gridOffers[2], 2)
                                  : _buildPlaceholderCard('Weekend\nSpecial', 'Up to 15%', const Color(0xFF58E067)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: gridOffers.length > 3 
                                  ? _buildSmallOfferCard(gridOffers[3], 3)
                                  : _buildPlaceholderCard('First Booking\nOffer', '20% OFF', const Color(0xFFD600D6)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeaturedOfferCard(Map<String, dynamic> offer) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFE84F),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            offer['title'] ?? '20%\nOFF',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryRed,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Limited Offer',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CachedNetworkImage(
              imageUrl: offer['image'],
              httpHeaders: const {},
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              errorWidget: (context, url, error) => Image.asset('lib/assets/images/man.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            offer['subtitle'] ?? 'Gardening Services',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.naturalBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallOfferCard(Map<String, dynamic> offer, int index) {
    // Parse hex color from backend with high-fidelity fallback
    Color cardColor;
    try {
      final hexColor = offer['color']?.toString().replaceAll('#', '') ?? 'FF6B6B';
      cardColor = Color(int.parse('FF$hexColor', radix: 16));
    } catch (e) {
      // Fallback colors if parsing fails
      final List<Color> fallbacks = [
        const Color(0xFFFF6B6B),
        const Color(0xFF5D8BF4),
        const Color(0xFF58E067),
        const Color(0xFFD600D6),
      ];
      cardColor = fallbacks[index % fallbacks.length];
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CachedNetworkImage(
                  imageUrl: offer['image'],
                  httpHeaders: const {},
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Icon(Icons.redeem, color: Colors.white.withOpacity(0.5), size: 16),
                  errorWidget: (context, url, error) => Icon(Icons.redeem, color: Colors.white.withOpacity(0.5), size: 16),
                ),
              ),
              Text(
                offer['subtitle'] ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            offer['title'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const Spacer(),
          Text(
            offer['footer'] ?? 'Explore Now',
            style: GoogleFonts.poppins(
              fontSize: 8,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(String title, String subtitle, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.redeem, color: Colors.white.withOpacity(0.9), size: 16),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          const Spacer(),
          Text(
            'Coming Soon',
            style: GoogleFonts.poppins(
              fontSize: 8,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

