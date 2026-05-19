import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:zeerah/controllers/service%20_list_controller.dart';


import 'package:zeerah/core/config/api_config.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/models/service_list_model.dart';
import 'package:zeerah/core/providers/favorites_provider.dart';
import 'package:zeerah/core/models/favorite_service.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/screens/handyman services/bookings/booking_home_page.dart';

class CategoryDetailsScreen extends StatefulWidget {
  final String subcategoryName;
  final int subcategoryId;
  final String? parentCategoryName;

  const CategoryDetailsScreen({
    Key? key,
    required this.subcategoryName,
    required this.subcategoryId,
    this.parentCategoryName,
  }) : super(key: key);

  @override
  State<CategoryDetailsScreen> createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  // Search related variables
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter related variables
  bool _isFilterVisible = false;
  RangeValues _priceRange = const RangeValues(0, 10000);
  double _minPrice = 0;
  double _maxPrice = 10000;
  String _sortBy = 'default'; // default, price_low_to_high, price_high_to_low

  void toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.naturalWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(Insets.xs),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Insets.xsm),
              boxShadow: [
                BoxShadow(
                  color: AppColors.naturalBlack.withOpacity(0.05),
                  blurRadius: AppSizes.w(context, 10),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.naturalBlack87,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          widget.subcategoryName.replaceAll('\n', ' '),
          style: TextStyle(
            color: AppColors.naturalBlack87,
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.w(context, 20),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: toggleSearch,
            icon: const Icon(
              Icons.search,
              color: AppColors.naturalBlack87,
              size: 22,
            ),
          ),
        ],
      ),
      body: Consumer2<ServiceListController, AddressProvider>(
        builder: (context, controller, addressProvider, _) {
          final loc = addressProvider.selectedLocation;
          final lat = double.tryParse(loc?['latitude']?.toString() ?? '');
          final lng = double.tryParse(loc?['longitude']?.toString() ?? '');

          debugPrint(
            "📱 CategoryDetailsScreen: Selected Location -> Lat: $lat, Lng: $lng",
          );

          if ((controller.serviceList.isEmpty ||
                  controller.subcategoryId != widget.subcategoryId ||
                  controller.latitude != lat) &&
              !controller.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.setSubcategory(widget.subcategoryId);
              controller.setLocation(lat, lng);
              controller.fetchServices();
            });
          }

          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryRed),
            );
          }

          if (controller.serviceList.isEmpty) {
            return Center(child: Text(UserMessages.noServicesFound));
          }

          // Calculate min and max prices for filter
          if (_minPrice == 0 && _maxPrice == 10000 && controller.serviceList.isNotEmpty) {
            final prices = controller.serviceList.map((s) => s.price?.toDouble() ?? 0).toList();
            _minPrice = prices.reduce((a, b) => a < b ? a : b);
            _maxPrice = prices.reduce((a, b) => a > b ? a : b);
            _priceRange = RangeValues(_minPrice, _maxPrice);
          }

          // Filter and sort services
          List<ServiceData> filteredServices = _filterAndSortServices(controller.serviceList);

          return Column(
            children: [
              // Search Bar (Conditional)
              if (_isSearchVisible)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search ${widget.subcategoryName}...',
                            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                            prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSearchVisible = false;
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                        child: const Text('Cancel', style: TextStyle(color: AppColors.primaryRed)),
                      ),
                    ],
                  ),
                ),

              // Header with Popular text and Filter Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    /// POPULAR TEXT
                    Text(
                      "Popular",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),

                    /// FILTER BUTTON
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isFilterVisible = !_isFilterVisible;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _isFilterVisible 
                              ? AppColors.primaryRed.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              "Filters",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _isFilterVisible 
                                    ? AppColors.primaryRed 
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.tune,
                              size: 16,
                              color: _isFilterVisible 
                                  ? AppColors.primaryRed 
                                  : Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Panel (Conditional)
              if (_isFilterVisible)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price Range Filter
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Price Range',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _priceRange = RangeValues(_minPrice, _maxPrice);
                                _sortBy = 'default';
                              });
                            },
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                color: AppColors.primaryRed,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RangeSlider(
                        values: _priceRange,
                        min: _minPrice,
                        max: _maxPrice,
                        divisions: 100,
                        labels: RangeLabels(
                          '₹${_priceRange.start.round()}',
                          '₹${_priceRange.end.round()}',
                        ),
                        activeColor: AppColors.primaryRed,
                        inactiveColor: Colors.grey.shade300,
                        onChanged: (RangeValues values) {
                          setState(() {
                            _priceRange = values;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${_priceRange.start.round()}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              '₹${_priceRange.end.round()}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Sort By
                      const Text(
                        'Sort By',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildSortChip('Default', 'default'),
                          _buildSortChip('Price: Low to High', 'price_low_to_high'),
                          _buildSortChip('Price: High to Low', 'price_high_to_low'),
                        ],
                      ),
                      
                      // Apply Filter Button
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isFilterVisible = false;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Results Count
              if (_searchQuery.isNotEmpty || _priceRange.start > _minPrice || _priceRange.end < _maxPrice || _sortBy != 'default')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${filteredServices.length} results found',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                            _priceRange = RangeValues(_minPrice, _maxPrice);
                            _sortBy = 'default';
                          });
                        },
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Service Grid
              Expanded(
                child: filteredServices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No services found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                  _priceRange = RangeValues(_minPrice, _maxPrice);
                                  _sortBy = 'default';
                                });
                              },
                              child: const Text('Clear filters'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: EdgeInsets.all(Insets.md),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = filteredServices[index];
                          return _ServiceCard(service: service);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: _sortBy == value,
      onSelected: (selected) {
        setState(() {
          _sortBy = value;
        });
      },
      selectedColor: AppColors.primaryRed.withOpacity(0.1),
      checkmarkColor: AppColors.primaryRed,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(
        color: _sortBy == value ? AppColors.primaryRed : Colors.transparent,
      ),
    );
  }

  List<ServiceData> _filterAndSortServices(List<ServiceData> services) {
    List<ServiceData> filtered = List.from(services);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((service) {
        final title = service.name?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return title.contains(query);
      }).toList();
    }

    // Apply price range filter
    filtered = filtered.where((service) {
      final price = service.price?.toDouble() ?? 0;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    // Apply sorting
    if (_sortBy == 'price_low_to_high') {
      filtered.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
    } else if (_sortBy == 'price_high_to_low') {
      filtered.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
    }

    return filtered;
  }
}

class _ServiceCard extends StatefulWidget {
  final ServiceData service;

  const _ServiceCard({required this.service});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  double? _lowestPrice;
  bool _isFetchingPrice = false;
  bool _hasOptionsOrAddons = false;

  // Add-ons data
  List<dynamic> _addOnServices = [];
  bool _isLoadingAddOns = false;

  @override
  void initState() {
    super.initState();
    _fetchLowestPriceAndAddOns();
  }

  Future<void> _fetchLowestPriceAndAddOns() async {
    if (mounted)
      setState(() {
        _isFetchingPrice = true;
        _isLoadingAddOns = true;
      });

    try {
      final url = Uri.parse('${ApiConfig.apiBaseUrl}/service-detail');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'service_id': widget.service.id}),
      );
      debugPrint("========== FULL API RESPONSE ==========");
      debugPrint(response.body);
      debugPrint("======================================");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final serviceDetail = data['service_detail'];
        final List<dynamic> bhkOptions =
            serviceDetail?['service_options'] ?? [];
        final List<dynamic> addOnServices = data['serviceaddon'] ?? [];

        double? minPrice;

        // Check options
        for (var opt in bhkOptions) {
          final p = double.tryParse(opt['price'].toString());
          if (p != null) {
            if (minPrice == null || p < minPrice) {
              minPrice = p;
            }
          }
        }

        // Check add-ons
        for (var addon in addOnServices) {
          final p = double.tryParse(addon['price'].toString());
          if (p != null) {
            if (minPrice == null || p < minPrice) {
              minPrice = p;
            }
          }
        }

        if (mounted) {
          setState(() {
            _lowestPrice = minPrice;
            _hasOptionsOrAddons =
                bhkOptions.isNotEmpty || addOnServices.isNotEmpty;
            _addOnServices = addOnServices;
            _isFetchingPrice = false;
            _isLoadingAddOns = false;
          });
        }
      } else {
        if (mounted)
          setState(() {
            _isFetchingPrice = false;
            _isLoadingAddOns = false;
          });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted)
        setState(() {
          _isFetchingPrice = false;
          _isLoadingAddOns = false;
        });
    }
  }

  void _showAddOnsBottomSheet() {
    final Set<int> selectedAddOnIndices = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double getTotalPrice() {
              double total = widget.service.price?.toDouble() ?? 0.0;

              for (int index in selectedAddOnIndices) {
                if (index < _addOnServices.length) {
                  final priceRaw = _addOnServices[index]['price'] ?? 0;
                  total += double.tryParse(priceRaw.toString()) ?? 0.0;
                }
              }
              return total;
            }

            List<Map<String, dynamic>> getSelectedAddOns() {
              List<Map<String, dynamic>> addons = [];
              for (int index in selectedAddOnIndices) {
                if (index < _addOnServices.length) {
                  addons.add(_addOnServices[index]);
                }
              }
              return addons;
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Frequently Added Together',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  _isLoadingAddOns
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryRed,
                            ),
                          ),
                        )
                      : _addOnServices.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: Text('No add-ons available'),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _addOnServices.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final addon = _addOnServices[index];
                            final isSelected = selectedAddOnIndices.contains(
                              index,
                            );
                            final addonPrice =
                                double.tryParse(
                                  addon['price']?.toString() ?? '0',
                                ) ??
                                0;

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryRed.withOpacity(0.05)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryRed
                                      : Colors.grey.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey[100],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Builder(
                                        builder: (context) {
                                          String? imageUrl;
                                          if (addon['image_url'] != null)
                                            imageUrl = addon['image_url'];
                                          else if (addon['image'] != null)
                                            imageUrl = addon['image'];
                                          else if (addon['attchments_array'] !=
                                                  null &&
                                              (addon['attchments_array']
                                                      as List)
                                                  .isNotEmpty) {
                                            imageUrl =
                                                addon['attchments_array'][0]['url'];
                                          } else if (addon['attachments_array'] !=
                                                  null &&
                                              (addon['attachments_array']
                                                      as List)
                                                  .isNotEmpty) {
                                            imageUrl =
                                                addon['attachments_array'][0]['url'];
                                          }

                                          if (imageUrl != null &&
                                              imageUrl.isNotEmpty) {
                                            return CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    color: Colors.grey[200],
                                                    child: const Center(
                                                      child: SizedBox(
                                                        height: 24,
                                                        width: 24,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                        color: Colors.grey[200],
                                                        child: const Icon(
                                                          Icons.image,
                                                          size: 32,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                            );
                                          }
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.add_shopping_cart,
                                              size: 32,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          addon['title'] ??
                                              addon['name'] ??
                                              'Add-on Service',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (addon['subtitle'] != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            addon['subtitle'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Text(
                                          '₹${addonPrice.toInt()}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedAddOnIndices.add(index);
                                        } else {
                                          selectedAddOnIndices.remove(index);
                                        }
                                      });
                                    },
                                    activeColor: AppColors.primaryRed,
                                    checkColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    side: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
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
                              'Total Amount',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '₹${getTotalPrice().toInt()}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  final subtotal =
                                      widget.service.price?.toDouble() ?? 0.0;
                                  double addonsTotal = 0.0;
                                  for (int index in selectedAddOnIndices) {
                                    if (index < _addOnServices.length) {
                                      final priceRaw =
                                          _addOnServices[index]['price'] ?? 0;
                                      addonsTotal +=
                                          double.tryParse(
                                            priceRaw.toString(),
                                          ) ??
                                          0.0;
                                    }
                                  }
                                  final fullAmount = subtotal + addonsTotal;
                                  final serviceDiscount =
                                      double.tryParse(
                                        widget.service.discount.toString(),
                                      ) ??
                                      0;
                                  final discountAmount =
                                      (fullAmount * serviceDiscount) / 100;
                                  final finalTotal =
                                      fullAmount - discountAmount;
                                  return BookingHomePage(
                                    service: widget.service,
                                    totalAmount: finalTotal,
                                    discountAmount: discountAmount,
                                    discountPercent: serviceDiscount,
                                    selectedOption: null,
                                    selectedAddOns: getSelectedAddOns(),
                                  );
                                },
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Book',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
          /// IMAGE SECTION
          SizedBox(
            width: double.infinity,
            height: 140,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade100,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl:
                          (widget.service.attachmentsArray != null &&
                              widget.service.attachmentsArray!.isNotEmpty)
                          ? widget.service.attachmentsArray!.first.url ?? ""
                          : (widget.service.attachments != null &&
                                widget.service.attachments!.isNotEmpty)
                          ? widget.service.attachments!.first
                          : widget.service.providerImage ?? "",
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (context, url) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported, size: 30),
                      ),
                    ),
                  ),
                ),

                /// RATING
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 10,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.service.serviceRating?.toString() ?? "4.0",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// FAVORITE
                Positioned(
                  top: 14,
                  left: 14,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favoritesProvider, child) {
                      final isFav = favoritesProvider.isFavorite(
                        widget.service.id!,
                      );
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          favoritesProvider.toggleFavorite(
                            FavoriteService(
                              id: widget.service.id!,
                              serviceImage: widget.service.providerImage ?? "",
                              serviceTitle: widget.service.name ?? "Service",
                              rating: widget.service.serviceRating ?? 0,
                              reviewsCount: 0,
                              rate: widget.service.price ?? 0,
                              isFavorite: true,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: isFav ? Colors.red : Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          /// CONTENT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                /// ROW 1: Service Name (Left) and Book Now Button (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.service.name ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (_addOnServices.isNotEmpty) {
                          _showAddOnsBottomSheet();
                        } else {
                          final subtotal =
                              widget.service.price?.toDouble() ?? 0;
                          final discountPercent =
                              double.tryParse(
                                widget.service.discount.toString(),
                              ) ??
                              0;
                          final discountAmount =
                              (subtotal * discountPercent) / 100;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingHomePage(
                                service: widget.service,
                                discountAmount: discountAmount,
                                discountPercent: discountPercent,
                                totalAmount: subtotal - discountAmount,
                                selectedOption: null,
                                selectedAddOns: [],
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Book",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                /// ROW 2: Price (Left) and View Details (Right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹${widget.service.price ?? 0}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.serviceDetails,
                          arguments: widget.service,
                        );
                      },
                      child: Text(
                        "view details",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
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