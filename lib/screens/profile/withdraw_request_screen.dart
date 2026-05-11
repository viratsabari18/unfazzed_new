import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/services/payment_service.dart';

class WithdrawRequestScreen extends StatefulWidget {
  final double currentBalance;
  const WithdrawRequestScreen({super.key, required this.currentBalance});

  @override
  State<WithdrawRequestScreen> createState() => _WithdrawRequestScreenState();
}

class _WithdrawRequestScreenState extends State<WithdrawRequestScreen> {
  final TextEditingController _amountController = TextEditingController();
  final PaymentService _paymentService = PaymentService();
  
  String? _selectedBankType = 'Bank';
  Map<String, dynamic>? _selectedBank;
  List<dynamic> _userBanks = [];
  bool _isLoadingBanks = true;
  
  final List<String> _bankTypes = ['Bank'];

  @override
  void initState() {
    super.initState();
    _fetchBanks();
  }

  Future<void> _fetchBanks() async {
    setState(() => _isLoadingBanks = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final response = await _paymentService.fetchUserBanks(
      userId: userProvider.backendUserId ?? "166",
      token: userProvider.apiToken,
    );
    
    if (mounted) {
      setState(() {
        _userBanks = response['data'] ?? [];
        _isLoadingBanks = false;
        if (_userBanks.isNotEmpty) {
          _selectedBank = _userBanks[0];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryRed,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Withdraw Request',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Available Balance Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Balance',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${widget.currentBalance.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Enter Amount Section
              Text(
                'Enter Amount',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'eg" 3000"',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryRed),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),

              // Bank Type Selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBankType,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                    items: _bankTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBankType = newValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Choose Bank Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose Bank',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(context, AppRoutes.addBank);
                      _fetchBanks(); // Refresh after adding
                    },
                    child: Text(
                      'Add bank',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: _isLoadingBanks 
                  ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryRed))),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        value: _selectedBank,
                        hint: Text(
                          _userBanks.isEmpty ? 'No banks added' : 'Select your bank',
                          style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black),
                        items: _userBanks.map((dynamic bank) {
                          final accNo = bank['account_no']?.toString() ?? "";
                          final maskedAcc = accNo.length > 4 
                            ? accNo.substring(accNo.length - 4).padLeft(accNo.length, '*')
                            : accNo;
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: bank as Map<String, dynamic>,
                            child: Text(
                              '${bank['bank_name']} ($maskedAcc)',
                              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black),
                            ),
                          );
                        }).toList(),
                        onChanged: (Map<String, dynamic>? newValue) {
                          setState(() {
                            _selectedBank = newValue;
                          });
                        },
                      ),
                    ),
              ),
              const SizedBox(height: 60),

              // Withdraw Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(_amountController.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a valid amount"))
                      );
                    } else if (amount > widget.currentBalance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Insufficient balance"))
                      );
                    } else if (_selectedBank == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a bank"))
                      );
                    } else {
                      _showSuccessDialog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Withdraw',
                    style: GoogleFonts.poppins(
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Request Submitted!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text("Your withdrawal request has been submitted successfully and will be processed soon.", textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to wallet history
            },
            child: const Text("OK", style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
