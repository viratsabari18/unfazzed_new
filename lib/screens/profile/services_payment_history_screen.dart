import 'package:google_fonts/google_fonts.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/models/user_model.dart';
import 'package:zeerah/core/services/payment_service.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ServicesPaymentHistoryScreen extends StatefulWidget {
  const ServicesPaymentHistoryScreen({super.key});

  @override
  State<ServicesPaymentHistoryScreen> createState() => _ServicesPaymentHistoryScreenState();
}

class _ServicesPaymentHistoryScreenState extends State<ServicesPaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  String _selectedFilter = 'All';
  bool _isLoading = true;
  List<dynamic> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final history = await _paymentService.fetchPaymentList(token: userProvider.apiToken);
    
    if (mounted) {
      setState(() {
        _allTransactions = history['data'] ?? [];
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredTransactions {
    if (_selectedFilter == 'All') return _allTransactions;
    
    return _allTransactions.where((tx) {
      final status = tx['payment_status']?.toString().toLowerCase() ?? '';
      
      if (_selectedFilter == 'Success') return status == 'paid' || status == 'success';
      if (_selectedFilter == 'Failed') return status == 'failed' || status == 'cancelled';
      if (_selectedFilter == 'Pending') return status == 'pending' || status == 'waiting';
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Services Payment History',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildFilters(),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
              : _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Success', 'Failed', 'Pending'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryRed : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryRed : const Color(0xFFEEEEEE),
                    width: 1,
                  ),
                ),
                child: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactions = _filteredTransactions;
    
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No payment records found',
              style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final double amount = (tx['total_amount'] ?? 0).toDouble();
        final String status = tx['payment_status']?.toString().toLowerCase() ?? 'pending';
        final String paymentMethod = tx['payment_method'] ?? tx['payment_type'] ?? 'Cash';
        final String serviceName = tx['service_name'] ?? "Service";
        
        final attachments = tx['service_attchments'];
        final String? imageUrl = (attachments is List && attachments.isNotEmpty) ? attachments.first : null;
        
        final bool isSuccess = status == 'paid' || status == 'success';
        
        // Date formatting
        String dateStr = tx['date'] ?? "";
        try {
          if (dateStr.isNotEmpty) {
             final dt = DateTime.parse(dateStr);
             dateStr = DateFormat('dd MMM, yyyy • hh:mm a').format(dt);
          }
        } catch (_) {}

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  image: imageUrl != null ? DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ) : null,
                ),
                child: imageUrl == null ? const Icon(Icons.cleaning_services_outlined, color: AppColors.primaryRed) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Method: $paymentMethod',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSuccess ? Colors.green.withOpacity(0.1) : 
                             (status == 'pending' ? Colors.orange.withOpacity(0.1) : AppColors.primaryRed.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSuccess ? Colors.green : 
                               (status == 'pending' ? Colors.orange : AppColors.primaryRed),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
