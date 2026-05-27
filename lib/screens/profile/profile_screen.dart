import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/core/models/user_model.dart';
import 'package:zeerah/core/providers/address_provider.dart';
import 'package:zeerah/core/providers/user_provider.dart';
import 'package:zeerah/core/services/auth_service.dart';
import 'package:zeerah/core/services/payment_service.dart';
import 'package:zeerah/core/common/notification_switch.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user;
  const ProfileScreen({super.key, this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late double _currentWallet;
  final AuthService _authService = AuthService();
  final PaymentService _paymentService = PaymentService();
  bool _isWalletLoading = true;

  @override
  void initState() {
    super.initState();
    // Use the balance already stored in UserProvider for instant display
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _currentWallet = userProvider.walletBalance;
    _isWalletLoading = userProvider.walletBalance == 0.0;
    _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final history = await _paymentService.fetchWalletHistory(
      token: userProvider.apiToken,
    );

    if (mounted) {
      setState(() {
        final newBalance = (history['available_balance'] ?? _currentWallet)
            .toDouble();
        _currentWallet = newBalance;
        userProvider.updateWalletBalance(newBalance);
        _isWalletLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildTopProfileCard(context),
            const SizedBox(height: 20),
            _buildMenuSection(
              context,
              title: 'General',
              items: [
                // _ProfileMenuItem(
                //   icon: Icons.account_balance_wallet_outlined,
                //   title: 'Wallet History',
                //   onTap: () => Navigator.pushNamed(
                //     context,
                //     AppRoutes.walletHistory,
                //     arguments: widget.user ?? UserModel.mock(),
                //   ),
                // ),
                _ProfileMenuItem(
                  icon: Icons.history_outlined,
                  title: 'Services Payment History',
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.servicesPaymentHistory,
                    );
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.favorite_border_outlined,
                  title: 'Favourite Services',
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.favoitesHistory);
                  },
                ),

                _ProfileMenuItem(
                  icon: Icons.person_outline,
                  title: 'Referral & Loyalty',
                  onTap: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      AppRoutes.referral,
                      arguments: widget.user ?? UserModel.mock(),
                    );

                    if (result != null && result is Map<String, dynamic>) {
                      setState(() {
                        _currentWallet = result['newWallet'] ?? _currentWallet;
                      });
                    }
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.star_border_outlined,
                  title: 'Rate Us',
                  onTap: () {},
                ),
                _ProfileMenuItem(
                  icon: Icons.message_outlined,
                  title: 'My reviews',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.myReviews),
                ),
                _ProfileMenuItem(
                  icon: Icons.help_outline,
                  title: 'Help Desk',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.helpDesk),
                ),
                _ProfileMenuItem(
                  icon: Icons.description_outlined,
                  title: 'Terms And Conditions',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.termsAndCondtions),
                ),

                _ProfileMenuItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy),
                ),

                  _ProfileMenuItem(
                  icon: Icons.support_agent_outlined,
                  title: 'Help And Support',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.helpAndSupport),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildMenuSection(
              context,
              title: 'About App',
              items: [
                _ProfileMenuItem(
                  icon: Icons.phone_outlined,
                  title: 'Helpline Number',
                  onTap: () async {
                    final Uri launchUri = Uri(
                      scheme: 'tel',
                      path: '7986544683',
                    );
                    if (await canLaunchUrl(launchUri)) {
                      await launchUrl(launchUri);
                    }
                  },
                ),
                _ProfileMenuItem(
                  icon: Icons.notifications_none_outlined,
                  title: 'Push Notifications',
                  trailing: const NotificationSwitch(),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 30),
            _buildLogoutButton(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProfileCard(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;
        final name = userProvider.displayName;
        final email = userProvider.email;
        final photoUrl = user?.photoURL;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Profile Info Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEEEEEE),
                          width: 1,
                        ),
                        image: DecorationImage(
                          image: photoUrl != null
                              ? NetworkImage(photoUrl) as ImageProvider
                              : const AssetImage(UserMessages.profileImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            email,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                      size: 16,
                    ),
                  ],
                ),
              ),

              const Divider(
                height: 1,
                color: Color(0xFFEEEEEE),
                indent: 20,
                endIndent: 20,
              ),

              // Wallet Section
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              //   child: Row(
              //     children: [
              //       Container(
              //         padding: const EdgeInsets.all(10),
              //         decoration: BoxDecoration(
              //           color: const Color(0xFFFFF0ED),
              //           borderRadius: BorderRadius.circular(12),
              //         ),
              //         child: const Icon(Icons.account_balance_wallet, color: AppColors.primaryRed, size: 24),
              //       ),
              //       const SizedBox(width: 16),
              //       Expanded(
              //         child: Text(
              //           'Wallet Balance',
              //           style: GoogleFonts.poppins(
              //             fontSize: 15,
              //             fontWeight: FontWeight.w600,
              //             color: Colors.black,
              //           ),
              //         ),
              //       ),
              //       _isWalletLoading
              //         ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              //         : Text(
              //             '₹${_currentWallet.toStringAsFixed(0)}',
              //             style: GoogleFonts.poppins(
              //               fontSize: 18,
              //               fontWeight: FontWeight.bold,
              //               color: AppColors.primaryRed,
              //             ),
              //           ),
              //     ],
              //   ),
              // ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required List<_ProfileMenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 30, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        color: AppColors.primaryRed,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    trailing:
                        item.trailing ??
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey,
                          size: 16,
                        ),
                    onTap: item.onTap,
                  ),
                  if (index != items.length - 1)
                    const Divider(
                      height: 1,
                      indent: 70,
                      endIndent: 20,
                      color: Color(0xFFEEEEEE),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await _authService.signOut();
          if (mounted) {
            Provider.of<UserProvider>(context, listen: false).clearUser();
            // User Request: Keep addresses persistent across login/logout
            // Provider.of<AddressProvider>(context, listen: false).clearAddressData();
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.signIn,
              (route) => false,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryRed,
          elevation: 0,
          side: const BorderSide(color: Color(0xFFEEEEEE)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 20),
            const SizedBox(width: 10),
            Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });
}
