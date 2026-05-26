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
  String selectedMethod = "cash";
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

  // Helper method to calculate bill details with correct order
  Map<String, double> calculateBillDetails(Map<String, dynamic>? bookingData) {
    final detail = bookingData?['booking_detail'];
    final service = bookingData?['service'];

    // Step 1: Service Price
    final double baseServicePrice = (service?['price'] ?? 0).toDouble();

    // Step 2: Add Addons
    final List bookingAddons = detail?['BookingAddonService'] ?? [];
    final double addonsPrice = bookingAddons.fold(
      0.0,
      (sum, addon) => sum + ((addon['price'] ?? 0).toDouble()),
    );

    // Subtotal after adding addons (before discount)
    final double subtotalAfterAddons = baseServicePrice + addonsPrice;

    // Step 3: Apply Discount on the subtotal (Service + Addons)
    final double discountPercent = (detail?['discount'] ?? 0).toDouble();
    final double discountAmount = (subtotalAfterAddons * discountPercent) / 100;

    // Amount after discount
    final double amountAfterDiscount = subtotalAfterAddons - discountAmount;

    // Step 4: Add Extra Charges after discount
    final List extraCharges = detail?['extra_charges'] ?? [];
    final double extraChargesTotal = extraCharges.fold(
      0.0,
      (sum, charge) => sum + ((charge['price'] ?? 0).toDouble()),
    );

    // Final total after adding extra charges
    final double totalAmount = amountAfterDiscount + extraChargesTotal;

    return {
      'baseServicePrice': baseServicePrice,
      'addonsPrice': addonsPrice,
      'subtotalAfterAddons': subtotalAfterAddons,
      'discountPercent': discountPercent,
      'discountAmount': discountAmount,
      'amountAfterDiscount': amountAfterDiscount,
      'extraChargesTotal': extraChargesTotal,
      'totalAmount': totalAmount,
    };
  }

  Widget paymentTile({
    required String title,
    required String value,
    required dynamic gateway,
  }) {
    final bool isSelected = selectedMethod == value;

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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bookingData = args?['booking_data'];
    final detail = bookingData?['booking_detail'];
    final service = bookingData?['service'];

    // Calculate all bill details
    final billDetails = calculateBillDetails(bookingData);
    
    final serviceName = detail?['service_name'] ??
        service?['name'] ??
        UserMessages.fullHomeCleaning;
    final serviceImage = service?['attchments']?[0] ?? UserMessages.fullHouseCleaningImage;
    final serviceDate = detail?['booking_date'] ?? UserMessages.serviceDateTime;
    
    final extraCharges = detail?['extra_charges'] ?? [];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.reviewBgColor,
        appBar: AppBar(
          backgroundColor: AppColors.primaryRed,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.naturalWhite),
            onPressed: _handleBack,
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
                                    color: AppColors.naturalBlack.withOpacity(0.54),
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
                      
                      // Service Price
                      billRow(
                        "Service Price",
                        "₹${billDetails['baseServicePrice']!.toStringAsFixed(0)}",
                        AppColors.naturalBlack,
                      ),

                      // Addons (if any)
                      if (billDetails['addonsPrice']! > 0)
                        billRow(
                          "Addons",
                          "+ ₹${billDetails['addonsPrice']!.toStringAsFixed(0)}",
                          AppColors.neonGreen,
                        ),

                      // Subtotal after addons (before discount)
                      // Container(
                      //   margin: EdgeInsets.only(top: Insets.xsm, bottom: Insets.xsm),
                      //   child: billRow(
                      //     "Subtotal (Service + Addons)",
                      //     "₹${billDetails['subtotalAfterAddons']!.toStringAsFixed(0)}",
                      //     AppColors.naturalBlack,
                      //   ),
                      // ),

                      // Discount
                      if (billDetails['discountAmount']! > 0)
                        billRow(
                          "Discount (${billDetails['discountPercent']!.toStringAsFixed(0)}%)",
                          "- ₹${billDetails['discountAmount']!.toStringAsFixed(0)}",
                          Colors.red,
                        ),

                      // After Discount
                      // Container(
                      //   margin: EdgeInsets.only(bottom: Insets.xsm),
                      //   child: billRow(
                      //     "After Discount",
                      //     "₹${billDetails['amountAfterDiscount']!.toStringAsFixed(0)}",
                      //     AppColors.billGreen,
                      //   ),
                      // ),

                      // Extra Charges (added after discount)
                      ...extraCharges.map((charge) {
                        final title = charge['title'] ?? "Extra Charge";
                        final value = (charge['price'] ?? 0).toDouble();
                        return billRow(
                          title,
                          "+ ₹${value.toStringAsFixed(0)}",
                          AppColors.neonGreen,
                        );
                      }).toList(),

                      // Divider
                      SizedBox(height: AppSizes.h(context, 12)),
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
                      
                      // Total Amount
                      SizedBox(height: AppSizes.h(context, 12)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            UserMessages.totalAmount,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "₹${billDetails['totalAmount']!.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppSizes.w(context, 18),
                            ),
                          ),
                        ],
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
                        const Center(
                          child: Text("No payment methods available"),
                        )
                      else
                        ..._gateways.map(
                          (g) => paymentTile(
                            title: g['type'] == 'razorPay'
                                ? "Pay Online"
                                : (g['title'] ?? "Payment Method"),
                            value: g['type'] ?? "",
                            gateway: g,
                          ),
                        ).toList(),

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
      ),
    );
  }

  Future<void> _handlePayment() async {
    if (_selectedGateway == null) return;
    _processRazorPay();
  }

  void _processRazorPay() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bookingData = args?['booking_data'];
    final detail = bookingData?['booking_detail'];
    
    // Calculate total amount using the helper method
    final billDetails = calculateBillDetails(bookingData);
    final totalAmount = billDetails['totalAmount']!;

    final value = _selectedGateway['value'];
    final key = value?['razor_key'] ?? "rzp_test_SlXdLiPsjndXjm";

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    var options = {
      'key': key,
      'amount': (totalAmount * 100).toInt(),
      'name': 'Unfazzed Services LLP',
      'description': detail?['service_name'] ?? 'Service Payment',
      'timeout': 300,
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
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bookingData = args?['booking_data'];
    final bookingId = (bookingData?['booking_detail']?['id'] ?? bookingData?['id'])?.toString();

    if (bookingId == null) return;

    // Calculate using helper method
    final billDetails = calculateBillDetails(bookingData);
    final discountAmount = billDetails['discountAmount']!;
    final totalAmount = billDetails['totalAmount']!;

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

  void _handleBack() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.landingPage,
      (route) => false,
    );
  }

  void _showSuccessDialog() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bookingData = args?['booking_data'];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Dialog(
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
                  "Your service booking has been successfully completed, and the payment was received successfully. Thank you for choosing our service.",
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
                      "Continue",
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
}