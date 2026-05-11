import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/services/payment_service.dart';

class ReferralScreen extends StatefulWidget {
  final UserModel user;
  const ReferralScreen({super.key, required this.user});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  late double _currentCashback;
  late double _currentWallet;
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentCashback = widget.user.cashbackBalance;
    // Initial value from user provider, then fetch from API
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _currentWallet = userProvider.walletBalance;
    _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
    setState(() {
      _isLoading = true;
    });
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final history = await _paymentService.fetchWalletHistory(token: userProvider.apiToken);
    
    if (mounted) {
      setState(() {
        final newBalance = (history['available_balance'] ?? _currentWallet).toDouble();
        _currentWallet = newBalance;
        userProvider.updateWalletBalance(newBalance);
        _isLoading = false;
      });
    }
  }

  void _handleRedeem() {
    if (_currentCashback <= 0) return;

    final double redeemedAmount = _currentCashback;

    setState(() {
      _currentWallet += _currentCashback;
      _currentCashback = 0;
    });

    _showRedeemSuccess(context, redeemedAmount);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        Navigator.pop(context, {
          'newWallet': _currentWallet,
          'newCashback': _currentCashback,
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFCC0000),
      appBar: AppBar(
        backgroundColor: const Color(0xFFCC0000),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, {
            'newWallet': _currentWallet,
            'newCashback': _currentCashback,
          }),
        ),
        title: Text(
          'Referral & Loyalty',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildWalletBalanceBadge(),
            const SizedBox(height: 15),
            _buildCashbackCard(context),
            const SizedBox(height: 25),
           
            _buildReferAndEarn(context),
            const SizedBox(height: 25),
            _buildPointsActivity(),
            const SizedBox(height: 25),
            _buildHowItWorks(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildWalletBalanceBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_balance_wallet, color: Color(0xFFFFD700), size: 16),
          const SizedBox(width: 8),
          Text(
            'Total Wallet Balance: ',
            style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.7), fontSize: 12),
          ),
          if (_isLoading)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          else
            Text(
              '₹${_currentWallet.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildCashbackCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Cashback',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${_currentCashback.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'ksb',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Earn more cashback by booking services',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFFFD700).withOpacity(0.8),
                          const Color(0xFFFFA500).withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '${_currentCashback.toStringAsFixed(0)}ksb',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _currentCashback > 0 ? _handleRedeem : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFFCC0000),
                disabledBackgroundColor: Colors.white.withOpacity(0.1),
                disabledForegroundColor: Colors.white.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentCashback > 0 ? 'Redeem' : 'Redeemed',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

 

  Widget _buildTierItem(String name, String cashback, bool isActive) {
    return Column(
      children: [
        Icon(
          name == 'Gold' ? Icons.emoji_events : Icons.military_tech,
          color: isActive ? const Color(0xFFFFD700) : Colors.white.withOpacity(0.5),
          size: 28,
        ),
        const SizedBox(height: 5),
        Text(
          name,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          cashback,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildReferAndEarn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Refer & Earn',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Invite friends and earn 50 Cashback when they complete their first bookings',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white),
                ),
                child: GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.user.referralCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Referral code copied!',
                          style: GoogleFonts.poppins(),
                        ),
                        backgroundColor: const Color(0xFFFFD700),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Referral Code : ${widget.user.referralCode}',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.share, size: 18),
                  label: Text(
                    'Share Invite',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFFCC0000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPointsActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Points Activity',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        ...widget.user.loyaltyActivity.map((activity) {
          final isCredit = activity['type'] == 'credit';
          return _buildActivityRow(
            activity['amount'],
            activity['desc'],
            activity['date'],
            isCredit ? const Color(0xFF00E676) : const Color(0xFFFF5252),
            isStrikethrough: !isCredit && activity['amount'].toString().contains('-'),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildActivityRow(String amount, String desc, String date, Color amountColor, {bool isStrikethrough = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              amount,
              style: GoogleFonts.poppins(
                color: amountColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                decoration: isStrikethrough ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            date,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it Works',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildExpansionTile('How do I earn cashback?'),
              _buildDivider(),
              _buildExpansionTile('When do referral cashback apply?'),
              _buildDivider(),
              _buildExpansionTile('Do cashback expire?'),
              _buildDivider(),
              _buildExpansionTile('Can I withdraw my cashback as cash?'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpansionTile(String title) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: const Color(0xFFCC0000),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFCC0000)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Details will go here. This information is fetched from our help desk database to ensure you have the most up-to-date information.',
              style: GoogleFonts.poppins(
                color: const Color(0xFFCC0000).withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: const Color(0xFFCC0000).withOpacity(0.2),
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  void _showRedeemSuccess(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE7F3E7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 25),
            Text(
              'Redemption Successful!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '₹${amount.toStringAsFixed(0)} ksb has been added to your wallet balance.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'New Balance: ₹${_currentWallet.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFCC0000),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCC0000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Great!',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
