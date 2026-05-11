import 'package:google_fonts/google_fonts.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/models/user_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:zeerah/core/services/payment_service.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class WalletHistoryScreen extends StatefulWidget {
  final UserModel user;
  const WalletHistoryScreen({super.key, required this.user});

  @override
  State<WalletHistoryScreen> createState() => _WalletHistoryScreenState();
}

class _WalletHistoryScreenState extends State<WalletHistoryScreen> {
  late Razorpay _razorpay;
  final PaymentService _paymentService = PaymentService();
  String _selectedFilter = 'All';
  bool _isLoading = true;
  double _currentBalance = 0;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _currentBalance = widget.user.walletBalance;
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final history = await _paymentService.fetchWalletHistory(token: userProvider.apiToken);
    
    if (mounted) {
      setState(() {
        // Exclude service payments from wallet history
        final data = history['data'] ?? [];
        _transactions = data.where((tx) {
          final type = tx['activity_type']?.toString().toLowerCase() ?? '';
          // Only show Top-ups and Withdrawals, strictly excluding all service payments
          return type.contains('top_up') || type.contains('withdraw');
        }).toList();
        
        _currentBalance = (history['available_balance'] ?? _currentBalance).toDouble();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  List<dynamic> get _filteredTransactions {
    if (_selectedFilter == 'All') return _transactions;
    return _transactions.where((tx) {
      final type = tx['activity_type']?.toString().toLowerCase() ?? '';
      if (_selectedFilter == 'Deposit') return type.contains('top_up') || type.contains('credit');
      if (_selectedFilter == 'Withdraw') return type.contains('withdraw');
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    
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
          'Wallet History',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildBalanceCard(context, _currentBalance),
            const SizedBox(height: 25),
            _buildFilters(),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Recent Transactions',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 15),
            _buildTransactionList(context),
            const SizedBox(height: 40),
            _buildSupportFooter(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryRed,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryRed,
            AppColors.primaryRed.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Balance',
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${balance.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildBalanceAction(
                Icons.add_circle_outline, 
                'Add Money', 
                onTap: () => _showAddMoneySheet(context),
              ),
              const SizedBox(width: 12),
              _buildBalanceAction(
                Icons.account_balance_outlined, 
                'Withdraw',
                onTap: () {
                  Navigator.pushNamed(
                    context, 
                    AppRoutes.withdrawRequest,
                    arguments: _currentBalance,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceAction(IconData icon, String label, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Deposit', 'Withdraw'];
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

  Widget _buildTransactionList(BuildContext context) {
    final transactions = _filteredTransactions;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'No transactions found',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final actData = tx['activity_data'] ?? {};
        final double amount = (actData['credit_debit_amount'] ?? 0).toDouble();
        final bool isCredit = (actData['transaction_type']?.toString().toLowerCase() == 'credit');
        
        // Format date
        String subtitle = tx['datetime'] ?? "";
        try {
          if (subtitle.isNotEmpty) {
             final dt = DateTime.parse(subtitle);
             subtitle = DateFormat('dd MMMM, yyyy • hh:mm a').format(dt);
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFFF0ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCredit ? Icons.add_circle_outline : Icons.shopping_bag_outlined,
                  color: isCredit ? Colors.green : AppColors.primaryRed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['activity_message'] ?? "Transaction",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${isCredit ? '+' : '-'}₹${amount.abs().toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isCredit ? Colors.green : AppColors.primaryRed,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportFooter() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: 'Having issues? ',
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 13,
          ),
          children: [
            TextSpan(
              text: 'Contact Support',
              style: GoogleFonts.poppins(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showAddMoneySheet(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Money to Wallet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the amount you want to add',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryRed,
              ),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRed,
                ),
                hintText: '0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primaryRed),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [500, 1000, 2000, 5000].map((amt) {
                return GestureDetector(
                  onTap: () => amountController.text = amt.toString(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEEEE)),
                    ),
                    child: Text(
                      '₹$amt',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && amount > 0) {
                    Navigator.pop(context);
                    _startRazorpayCheckoutWithTrackedAmount(amount);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a valid amount"))
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Proceed to Pay',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _startRazorpayCheckout(double amount) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // Using test key as fallback, but ideally should be fetched from API
    var options = {
      'key': 'rzp_test_SlXdLiPsjndXjm',
      'amount': (amount * 100).toInt(),
      'name': 'Zeerah Wallet',
      'description': 'Add Money to Wallet',
      'prefill': {
        'contact': userProvider.user?.phoneNumber ?? '',
        'email': userProvider.user?.email ?? ''
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final amountText = "0"; // We need to track the amount
    // Let's assume we store the pending top-up amount somewhere
    // For now I'll just use a small hack or pass it via a variable
    
    _processTopUp(response.paymentId!);
    _fetchHistory(); // Refresh history after top-up
  }

  // We need to store the requested amount to use it in success callback
  double _pendingAmount = 0;
  
  void _startRazorpayCheckoutWithTrackedAmount(double amount) {
    _pendingAmount = amount;
    _startRazorpayCheckout(amount);
  }
  
  // Need to update the call in _showAddMoneySheet
  // Replace: _startRazorpayCheckout(amount);
  // With: _startRazorpayCheckoutWithTrackedAmount(amount);

  void _processTopUp(String paymentId) async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final success = await _paymentService.topUpWallet(
      userId: userProvider.backendUserId ?? "166", // Fallback to example ID
      amount: _pendingAmount,
      transactionId: paymentId,
      transactionType: 'razorPay',
      token: userProvider.apiToken,
    );

    setState(() => _isLoading = false);

    if (success) {
      _showTopUpSuccessDialog();
    }
    // Removed the error dialog as per user request to avoid confusion 
    // when the server update response might be unreliable despite payment success.
  }

  void _handlePaymentError(PaymentFailureResponse response) {
     _showTopUpErrorDialog("Payment failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}"))
    );
  }

  void _showTopUpSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Top-up Successful!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text("₹${_pendingAmount.toStringAsFixed(0)} has been added to your wallet."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showTopUpErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.error_outline, color: AppColors.primaryRed, size: 64),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }
}
