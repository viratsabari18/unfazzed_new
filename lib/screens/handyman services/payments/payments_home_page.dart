import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/services/payment_service.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:intl/intl.dart';

class PaymentsHomePage extends StatefulWidget {
  const PaymentsHomePage({super.key});

  @override
  State<PaymentsHomePage> createState() => _PaymentsHomePageState();
}

class _PaymentsHomePageState extends State<PaymentsHomePage> {
  final PaymentService _paymentService = PaymentService();
  late Razorpay _razorpay;
  List<dynamic> _gateways = [];
  bool _isLoading = true;
  String selectedMethod = "cash"; // Default type
  dynamic _selectedGateway;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorPaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorPayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _fetchGateways();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchGateways() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final gateways = await _paymentService.fetchPaymentGateways(
      token: userProvider.apiToken,
    );

    if (mounted) {
      setState(() {
        // Filter out flutterwave and only keep active ones
        // _gateways = gateways.where((g) => g['status'] == 1 && g['type'] != 'flutterwave').toList();

        // // Add manual Wallet option
        // _gateways.add({
        //   "id": 99,
        //   "title": "Wallet",
        //   "type": "wallet",
        //   "status": 1,
        // });

        // Show only Razorpay
        _gateways = gateways
            .where((g) => g['status'] == 1 && g['type'] == 'razorPay')
            .toList();
        if (_gateways.isNotEmpty) {
          _selectedGateway = _gateways.firstWhere(
            (g) => g['type'] == 'cash',
            orElse: () => _gateways.first,
          );
          selectedMethod = _selectedGateway['type'];
        }
        _isLoading = false;
      });
    }
  }

  Widget paymentTile({
    required String title,
    required String value,
    required dynamic gateway,
  }) {
    final bool isSelected = selectedMethod == value;

    // Map gateway types to icons
    String icon = UserMessages.paymentsCashOnDelivery;
    if (value == 'razorPay') icon = UserMessages.paymentsCreditCard;
    if (value == 'wallet') icon = UserMessages.paymentsWallet;
    if (value == 'cash') icon = UserMessages.paymentsCashOnDelivery;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMethod = value;
          _selectedGateway = gateway;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Insets.sm,
          vertical: Insets.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.selectedPaymentBg
              : AppColors.naturalWhite,
          borderRadius: BorderRadius.circular(Insets.sm),
        ),
        child: Row(
          children: [
            Image.asset(icon, height: AppSizes.h(context, 22)),
            SizedBox(width: Insets.xsm),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: AppSizes.w(context, 15),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              height: AppSizes.h(context, 22),
              width: AppSizes.w(context, 22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.naturalBlack),
              ),
              child: isSelected
                  ? Padding(
                      padding: EdgeInsets.all(Insets.xxs),
                      child: Image.asset(UserMessages.paymentsSelected),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget billRow(String title, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.h(context, 4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [const Text("• "), Text(title)]),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bookingData = args?['booking_data'];
    final detail = bookingData?['booking_detail'];
    final service = bookingData?['service'];

    print(   
        service?['attchments']?[0]);

    // Data extraction
    final serviceName =
        detail?['service_name'] ??
        service?['name'] ??
        UserMessages.fullHomeCleaning;
    final serviceImage =
        service?['attchments']?[0] ?? UserMessages.fullHouseCleaningImage;

    
    final serviceDate = detail?['booking_date'] ?? UserMessages.serviceDateTime;

    // Priority: 1. Passed in args, 2. Booking detail price, 3. Base service price
    final double serviceFee = args?['price'] != null
        ? double.tryParse(args!['price'].toString()) ?? 0.0
        : (detail?['price'] ?? service?['price'] ?? 0).toDouble();

    final double discountPercent =
        (detail?['discount'] ?? service?['discount'] ?? 0).toDouble();
    final double discountAmount = (serviceFee * discountPercent) / 100;

    // We keep extraCharges for display if they exist in the detail
    final List extraCharges = detail?['extra_charges'] ?? [];
    final double extraChargesTotal = (detail?['extra_charges_value'] ?? 0)
        .toDouble();

    // Final total is the serviceFee (which includes options/addons) minus discount plus any extra charges
    final double totalAmount = serviceFee  + extraChargesTotal;

    return Scaffold(
      backgroundColor: AppColors.reviewBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.naturalWhite),
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.bookingHistory),
        ),
        centerTitle: true,
        title: Text(
          UserMessages.paymentSummary,
          style: TextStyle(
            fontSize: AppSizes.w(context, 18),
            fontWeight: FontWeight.w600,
            color: AppColors.naturalWhite,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(Insets.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                UserMessages.serviceDetails,
                                style: TextStyle(
                                  color: AppColors.primaryRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: AppSizes.h(context, 6)),
                              Text(
                                serviceName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: AppSizes.h(context, 4)),
                              Text(
                                serviceDate,
                                style: TextStyle(
                                  fontSize: AppSizes.w(context, 11),
                                  color: AppColors.naturalBlack.withOpacity(
                                    0.54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Insets.xs),
                          child: serviceImage.startsWith('http')
                              ? Image.network(
                                  serviceImage,
                                  height: AppSizes.h(context, 80),
                                  width: AppSizes.w(context, 110),
                                  fit: BoxFit.cover,
                                  headers: const {},
                                )
                              : Image.asset(
                                  serviceImage,
                                  height: AppSizes.h(context, 80),
                                  width: AppSizes.w(context, 110),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.h(context, 20)),
                    Text(
                      UserMessages.billBreakdown,
                      style: TextStyle(
                        color: AppColors.billGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSizes.h(context, 10)),
                    billRow(
                      UserMessages.serviceFee,
                      "₹ $serviceFee",
                      AppColors.naturalBlack,
                    ),

                    // Dynamic Extra Charges
                    ...extraCharges.map((charge) {
                      final title = charge['title'] ?? "Extra Charge";
                      final value = charge['price'] ?? 0;
                      return billRow(title, "+ ₹$value", AppColors.neonGreen);
                    }).toList(),

                    // if (discountAmount > 0)
                    //   billRow(
                    //     UserMessages.coupon,
                    //     "- ₹${discountAmount.toStringAsFixed(0)}",
                    //     AppColors.softBlue,
                    //   ),

                    SizedBox(height: AppSizes.h(context, 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          UserMessages.totalAmount,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "₹${totalAmount.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: AppSizes.w(context, 18),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.h(context, 10)),
                    Container(
                      height: AppSizes.h(context, 2),
                      decoration: BoxDecoration(
                        color: AppColors.billGreen.withOpacity(0.3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.billGreen.withOpacity(0.5),
                            blurRadius: AppSizes.w(context, 6),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSizes.h(context, 20)),
                    Text(
                      UserMessages.paymentMethod,
                      style: TextStyle(
                        color: AppColors.billGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSizes.h(context, 12)),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_gateways.isEmpty)
                      const Center(child: Text("No payment methods available"))
                    else
                      ..._gateways
                          .map(
                            (g) => paymentTile(
                              title: g['type'] == 'razorPay'
                                  ? "Pay Online"
                                  : (g['title'] ?? "Payment Method"),
                              value: g['type'] ?? "",
                              gateway: g,
                            ),
                          )
                          .toList(),

                    SizedBox(height: AppSizes.h(context, 20)),
                    GestureDetector(
                      onTap: () {
                        _handlePayment();
                      },
                      child: Container(
                        height: AppSizes.h(context, 55),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.payButtonColor,
                          borderRadius: BorderRadius.circular(Insets.sm),
                        ),
                        child: Center(
                          child: Text(
                            UserMessages.payNow,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppSizes.w(context, 16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (_selectedGateway == null) return;

    _processRazorPay();
    // final type = _selectedGateway['type'];
    // if (type == 'cash') {
    //    _processCashPayment();
    // } else if (type == 'razorPay') {
    //    _processRazorPay();
    // } else if (type == 'wallet') {
    //    _processWalletPayment();
    // } else {
    //    ScaffoldMessenger.of(context).showSnackBar(
    //      SnackBar(content: Text("${_selectedGateway['title']} not implemented yet"))
    //    );
    // }
  }

  void _processCashPayment() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bookingData = args?['booking_data'];
    final bookingId =
        (bookingData?['booking_detail']?['id'] ?? bookingData?['id'])
            ?.toString();

    if (bookingId == null) return;

    // Calculate total amount (same logic as build)
    final detail = bookingData?['booking_detail'];
    final service = bookingData?['service'];
    final double serviceFee = args?['price'] != null
        ? double.tryParse(args!['price'].toString()) ?? 0.0
        : (detail?['price'] ?? service?['price'] ?? 0).toDouble();

    final double discountPercent =
        (detail?['discount'] ?? service?['discount'] ?? 0).toDouble();
    final double discountAmount = (serviceFee * discountPercent) / 100;
    final double extraChargesTotal = (detail?['extra_charges_value'] ?? 0)
        .toDouble();
    final double totalAmount = serviceFee  + extraChargesTotal;

    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await _paymentService.savePayment(
      bookingId: bookingId,
      customerId: userProvider.backendUserId ?? "0",
      discount: discountAmount,
      totalAmount: totalAmount,
      paymentType: 'cash',
      status: 'pending',
      datetime: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      token: userProvider.apiToken,
    );

    setState(() => _isLoading = false);

    if (success) {
      _showCODSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save payment status")),
      );
    }
  }

  void _processRazorPay() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bookingData = args?['booking_data'];
    final detail = bookingData?['booking_detail'];
    final service = bookingData?['service'];

    // Calculate total amount
    final double serviceFee = args?['price'] != null
        ? double.tryParse(args!['price'].toString()) ?? 0.0
        : (detail?['price'] ?? service?['price'] ?? 0).toDouble();

    final double discountPercent =
        (detail?['discount'] ?? service?['discount'] ?? 0).toDouble();
    final double discountAmount = (serviceFee * discountPercent) / 100;
    final double extraChargesTotal = (detail?['extra_charges_value'] ?? 0)
        .toDouble();
    final double totalAmount = serviceFee  + extraChargesTotal;

    final value = _selectedGateway['value'];
    final key = value?['razor_key'] ?? "rzp_test_SlXdLiPsjndXjm";

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    var options = {
      'key': key,
      'amount': (totalAmount * 100)
          .toInt(), // amount in the smallest currency unit
      'name': 'Unfazzed Services LLP',
      'description': detail?['service_name'] ?? 'Service Payment',
      'timeout': 300, // in seconds
      'prefill': {
        'contact': userProvider.user?.phoneNumber ?? '',
        'email': userProvider.user?.email ?? '',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: e');
    }
  }

  void _handleRazorPaySuccess(PaymentSuccessResponse response) async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bookingData = args?['booking_data'];
    final bookingId =
        (bookingData?['booking_detail']?['id'] ?? bookingData?['id'])
            ?.toString();

    if (bookingId == null) return;

    // Recalculate amount
    final detail = bookingData?['booking_detail'];
    final service = bookingData?['service'];
    final double serviceFee = args?['price'] != null
        ? double.tryParse(args!['price'].toString()) ?? 0.0
        : (detail?['price'] ?? service?['price'] ?? 0).toDouble();

    final double discountPercent =
        (detail?['discount'] ?? service?['discount'] ?? 0).toDouble();
    final double discountAmount = (serviceFee * discountPercent) / 100;
    final double extraChargesTotal = (detail?['extra_charges_value'] ?? 0)
        .toDouble();
    final double totalAmount = serviceFee  + extraChargesTotal;

    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final success = await _paymentService.savePayment(
      bookingId: bookingId,
      customerId: userProvider.backendUserId ?? "0",
      discount: discountAmount,
      totalAmount: totalAmount,
      paymentType: 'razorPay',
      status: 'paid',
      transactionId: response.paymentId,
      datetime: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      token: userProvider.apiToken,
    );

    setState(() => _isLoading = false);

    if (success) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(
        "Payment successful but failed to update status on server. Please contact support.",
      );
      // Show success dialog anyway because payment was successful
      _showSuccessDialog();
    }
  }

  void _handleRazorPayError(PaymentFailureResponse response) {
    _showErrorDialog("Payment Failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("External Wallet Selected: ${response.walletName}"),
        backgroundColor: AppColors.primaryRed,
      ),
    );
  }

  void _processWalletPayment() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bookingData = args?['booking_data'];
    final bookingId =
        (bookingData?['booking_detail']?['id'] ?? bookingData?['id'])
            ?.toString();

    if (bookingId == null) return;

    // Calculate total amount
    final detail = bookingData?['booking_detail'];
    final service = bookingData?['service'];
    final double serviceFee = args?['price'] != null
        ? double.tryParse(args!['price'].toString()) ?? 0.0
        : (detail?['price'] ?? service?['price'] ?? 0).toDouble();

    final double discountPercent =
        (detail?['discount'] ?? service?['discount'] ?? 0).toDouble();
    final double discountAmount = (serviceFee * discountPercent) / 100;
    final double extraChargesTotal = (detail?['extra_charges_value'] ?? 0)
        .toDouble();
    final double totalAmount = serviceFee  + extraChargesTotal;

    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // We use the same payment-save API with 'wallet' type
    final success = await _paymentService.savePayment(
      bookingId: bookingId,
      customerId: userProvider.backendUserId ?? "0",
      discount: discountAmount,
      totalAmount: totalAmount,
      paymentType: 'wallet',
      status: 'paid', // Deducted instantly on server
      datetime: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
      token: userProvider.apiToken,
    );

    setState(() => _isLoading = false);

    if (success) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(
        "Insufficient wallet balance or failed to process wallet payment.",
      );
    }
  }

  void _showSuccessDialog() {
      final args =
      ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

  final bookingData = args?['booking_data'];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.2),
                    width: 4,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Payment Successful!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
               "Your service booking has been successfully completed, and the payment was received successfully. Thank you for choosing our service. We hope you had a great experience!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                          onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.ratingsAndReview,
                      arguments: {'booking_data': bookingData},
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "ok",
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
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryRed.withOpacity(0.2),
                    width: 4,
                  ),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.primaryRed,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Payment Failed",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Try Again",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCODSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                    width: 4,
                  ),
                ),
                child: const Icon(
                  Icons.handshake_rounded,
                  color: Colors.blue,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Booking Confirmed!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Your request for Cash on Delivery has been received. Please pay the professional after the service is completed.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.homePage,
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Go to Home",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
