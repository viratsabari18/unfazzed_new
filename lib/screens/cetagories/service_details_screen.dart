import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zeerah/core/config/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/models/service_list_model.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final ServiceData service;

  const ServiceDetailsScreen({required this.service, super.key});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  bool _showAllReviews = false;
  bool _isLoading = true;
  List<dynamic> _howItDone = [];
  List<dynamic> _whatsIncluded = [];
  List<dynamic> _whatsNotIncluded = [];
  List<dynamic> _customerReview = [];
  List<dynamic> _serviceOptions = [];
  Map<String, dynamic>? _serviceDetail;

  @override
  void initState() {
    super.initState();
    _fetchServiceDetails();
  }

  Future<void> _fetchServiceDetails() async {
    try {
      final url = Uri.parse('${ApiConfig.apiBaseUrl}/service-detail');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'service_id': widget.service.id}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _serviceDetail = data['service_detail'];
            _howItDone = _serviceDetail?['how_it_done'] ?? [];
            _whatsIncluded = _serviceDetail?['whats_included'] ?? [];
            _whatsNotIncluded = _serviceDetail?['whats_not_included'] ?? [];
            _serviceOptions = _serviceDetail?['service_options'] ?? [];
            _customerReview = data['customer_review'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching service details: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            )
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(context),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHowItsDone(),

                        _buildWhatsIncluded(),

                        _buildWhatsNotIncluded(),

                        _buildReviewsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            (widget.service.attachmentsArray != null &&
                    widget.service.attachmentsArray!.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: widget.service.attachmentsArray!.first.url ?? '',
                    httpHeaders: const {},
                    fit: BoxFit.fill,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Image.asset(
                      'lib/assets/images/man.png',
                      fit: BoxFit.cover,
                    ),
                  )
                : widget.service.providerImage != null &&
                      widget.service.providerImage!.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: widget.service.providerImage!,
                    httpHeaders: const {},
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Image.asset(
                      'lib/assets/images/man.png',
                      fit: BoxFit.cover,
                    ),
                  )
                : Image.asset('lib/assets/images/man.png', fit: BoxFit.cover),
            Container(color: Colors.black.withOpacity(0.2)),
            Positioned(
              bottom: 20,
              left: 20,
              child: Text(
                widget.service.name ?? 'Service Details',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItsDone() {
    if (_howItDone.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "How it’s done",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 items per row
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio:
                0.85, // Adjusted for better card proportions (width/height)
          ),
          itemCount: _howItDone.length,
          itemBuilder: (context, index) {
            final step = _howItDone[index];
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child:
                          step['image'] != null &&
                              step['image'].toString().startsWith('http')
                          ? CachedNetworkImage(
                              imageUrl: step['image'],
                              httpHeaders: const {},
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "${index + 1}. ${step['title'] ?? ''}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

Widget _buildWhatsIncluded() {
  if (_whatsIncluded.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text(
        "What's Included",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
  
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _whatsIncluded.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = _whatsIncluded[index];
          
          String text = item is Map
              ? (item['title'] ??
                    item['name'] ??
                    item['text'] ??
                    item.toString())
              : item.toString();
          
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ],
  );
}
  Widget _buildWhatsNotIncluded() {
    if (_whatsNotIncluded.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "What's Not Included",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),
        ),
 
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _whatsNotIncluded.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _whatsNotIncluded[index];
            String text = item is Map
                ? (item['title'] ??
                      item['name'] ??
                      item['text'] ??
                      item.toString())
                : item.toString();

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.close, color: Colors.red, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    final reviews = _customerReview;
    if (reviews.isEmpty) return const SizedBox.shrink();

    final displayReviews = _showAllReviews ? reviews : reviews.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Customer Reviews",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showAllReviews = !_showAllReviews;
                });
              },
              child: Text(
                _showAllReviews ? "Hide <<" : "See all >>",
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9F0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Text(
                    widget.service.totalRating?.toString() ?? '0.0',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        Icons.star,
                        size: 14,
                        color: i < 5 ? Colors.amber : Colors.grey[300],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "(65K+ Reviews)",
                    style: TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildRatingBar(5, 0.8),
                    _buildRatingBar(4, 0.6),
                    _buildRatingBar(3, 0.4),
                    _buildRatingBar(2, 0.2),
                    _buildRatingBar(1, 0.1),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...displayReviews.map(
          (review) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildReviewCard(review as Map<String, dynamic>),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBar(int star, double percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            "$star",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.star, size: 11, color: Colors.amber),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey[200],
                color: star >= 3
                    ? (star == 3 ? Colors.blue : Colors.green)
                    : (star == 2 ? Colors.orange : Colors.red),
                minHeight: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                radius: 18,
                child: const Icon(Icons.person, color: Colors.grey, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name'] ?? review['customer_name'] ?? 'Customer',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      review['date'] ?? review['created_at'] ?? '',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    Icons.star,
                    size: 14,
                    color: i < (review['rating'] ?? 5)
                        ? Colors.red
                        : Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review['comment'] ?? review['review'] ?? '',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayPrice() {
    if (_serviceOptions.isNotEmpty) {
      final priceRaw = _serviceOptions[0]['price'];
      if (priceRaw != null) return priceRaw.toString();
    }
    return widget.service.price?.toString() ?? "0";
  }
}
