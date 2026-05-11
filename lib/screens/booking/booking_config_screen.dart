import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zeerah/core/config/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/models/service_list_model.dart';
import 'package:zeerah/screens/handyman%20services/bookings/booking_home_page.dart';

class BookingConfigScreen extends StatefulWidget {
  final ServiceData service;
  const BookingConfigScreen({required this.service, super.key});

  @override
  State<BookingConfigScreen> createState() => _BookingConfigScreenState();
}

class _BookingConfigScreenState extends State<BookingConfigScreen> {
  int _selectedBhkIndex = 0;
  final Set<int> _selectedAddOnIndices = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<dynamic> bhkOptions = [];
  List<dynamic> addOnServices = [];

  @override
  void initState() {
    super.initState();
    _fetchBookingConfig();
  }

  Future<void> _fetchBookingConfig() async {
    try {
      final url = Uri.parse('${ApiConfig.apiBaseUrl}/service-detail');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          
        },
        body: json.encode({'service_id': widget.service.id}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            final serviceDetail = data['service_detail'];
            bhkOptions = serviceDetail?['service_options'] ?? [];
            addOnServices = data['serviceaddon'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching booking config: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalPrice {
    double total = 0.0;
    
    if (bhkOptions.isNotEmpty && _selectedBhkIndex < bhkOptions.length) {
      final priceRaw = bhkOptions[_selectedBhkIndex]['price'] ?? 0;
      total += double.tryParse(priceRaw.toString()) ?? 0.0;
    } else {
      total += widget.service.price ?? 0.0; // Fallback to service base price if no options
    }

    for (int index in _selectedAddOnIndices) {
      if (index < addOnServices.length) {
        final priceRaw = addOnServices[index]['price'] ?? 0;
        total += double.tryParse(priceRaw.toString()) ?? 0.0;
      }
    }
    return total;
  }

  Map<String, dynamic>? get _selectedOption {
    if (bhkOptions.isNotEmpty && _selectedBhkIndex < bhkOptions.length) {
      return bhkOptions[_selectedBhkIndex];
    }
    return null;
  }

  List<Map<String, dynamic>> get _selectedAddOns {
    List<Map<String, dynamic>> addons = [];
    for (int index in _selectedAddOnIndices) {
      if (index < addOnServices.length) {
        addons.add(addOnServices[index]);
      }
    }
    return addons;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            if (bhkOptions.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Select Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              // BHK Options Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(bhkOptions.length, (index) {
                    final option = bhkOptions[index];
                    final isSelected = _selectedBhkIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedBhkIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFD9CC) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.black12,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Builder(
                              builder: (context) {
                                String? imageUrl;
                                if (option['image_url'] != null) imageUrl = option['image_url'];
                                else if (option['image'] != null) imageUrl = option['image'];
                                else if (option['attchments_array'] != null && (option['attchments_array'] as List).isNotEmpty) {
                                  imageUrl = option['attchments_array'][0]['url'];
                                } else if (option['attachments_array'] != null && (option['attachments_array'] as List).isNotEmpty) {
                                  imageUrl = option['attachments_array'][0]['url'];
                                }

                                if (imageUrl != null && imageUrl.isNotEmpty) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        httpHeaders: const {},
                                        height: 40,
                                        width: 40,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => const SizedBox(
                                          height: 40, width: 40,
                                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        ),
                                        errorWidget: (context, url, error) => const Icon(Icons.image, size: 40, color: Colors.grey),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            Text(
                              option['title'] ?? option['name'] ?? 'Option',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${option['price'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
            if (addOnServices.isNotEmpty) ...[
              const SizedBox(height: 32),
            const Text(
              'Add-on-services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
              // Add-on Services List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: addOnServices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final service = addOnServices[index];
                  final isAdded = _selectedAddOnIndices.contains(index);
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Builder(
                                    builder: (context) {
                                      String? imageUrl;
                                      if (service['image_url'] != null) imageUrl = service['image_url'];
                                      else if (service['image'] != null) imageUrl = service['image'];
                                      else if (service['attchments_array'] != null && (service['attchments_array'] as List).isNotEmpty) {
                                        imageUrl = service['attchments_array'][0]['url'];
                                      } else if (service['attachments_array'] != null && (service['attachments_array'] as List).isNotEmpty) {
                                        imageUrl = service['attachments_array'][0]['url'];
                                      }

                                      if (imageUrl != null && imageUrl.isNotEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 12.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              httpHeaders: const {},
                                              height: 40,
                                              width: 40,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => const SizedBox(
                                                height: 40, width: 40,
                                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                              ),
                                              errorWidget: (context, url, error) => const Icon(Icons.image, size: 40, color: Colors.grey),
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                  Expanded(
                                    child: Text(
                                      service['title'] ?? service['name'] ?? 'Add-on',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (service['subtitle'] != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  service['subtitle'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            Text(
                              '₹${service['price'] ?? 0}',
                              style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isAdded) {
                                  _selectedAddOnIndices.remove(index);
                                } else {
                                  _selectedAddOnIndices.add(index);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              decoration: BoxDecoration(
                                color: isAdded ? Colors.grey : const Color(0xFF263238),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isAdded ? 'Remove' : 'Add',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  );
                },
              ),
            ],
            const SizedBox(height: 120), // Spacer for bottom bar
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '₹${_totalPrice.toInt()}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookingHomePage(
                            service: widget.service,
                            totalAmount: _totalPrice,
                            selectedOption: _selectedOption,
                            selectedAddOns: _selectedAddOns,
                          ),
                        ),
                      );
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                decoration: BoxDecoration(
                  color: _isSubmitting ? Colors.grey : const Color(0xFF263238),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
