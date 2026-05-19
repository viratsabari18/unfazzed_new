
import 'package:zeerah/core/common/app_exports.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountry = '(+91) India';

  static const Color primaryOrange = Color(0xFFE8A040);
  static const Color lightOrange = Color(0xFFF5C06A);
  static const Color backgroundOrange = Color(0xFFE8A040);

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundOrange,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'OTP Verification',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                ],
              ),
            ),

            // Icon Section with decorative dots
            Expanded(
              flex: 4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Decorative circles
                  Positioned(
                    top: 20,
                    left: 60,
                    child: _buildDecoCircle(6, false),
                  ),
                  Positioned(
                    top: 10,
                    left: 120,
                    child: _buildDecoPlus(),
                  ),
                  Positioned(
                    top: 8,
                    right: 100,
                    child: _buildDecoPlus(),
                  ),
                  Positioned(
                    top: 50,
                    right: 55,
                    child: _buildDecoCircle(10, true),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 50,
                    child: _buildDecoCircle(14, true),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 60,
                    child: _buildDecoCircle(8, false),
                  ),

                  // Phone + Message Icon
                  _buildPhoneMessageIcon(),
                ],
              ),
            ),

            // Bottom white card
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative blob bottom-left
                    Positioned(
                      bottom: -20,
                      left: -30,
                      child: _buildBlob(130, 100, const Color(0xFFEDD9B5).withOpacity(0.5)),
                    ),
                    // Decorative blob bottom-right
                    Positioned(
                      bottom: -10,
                      right: -20,
                      child: _buildBlob(120, 90, const Color(0xFFEDD9B5).withOpacity(0.4)),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Country Dropdown
                          _buildCountryDropdown(),
                          const SizedBox(height: 6),
                          const Divider(color: Color(0xFFDDDDDD), thickness: 1),
                          const SizedBox(height: 20),

                          // Phone Number Field
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF333333),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter your mobile number',
                              hintStyle: TextStyle(
                                color: Color(0xFFAAAAAA),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const Divider(color: Color(0xFFDDDDDD), thickness: 1),
                          const SizedBox(height: 28),

                          // Info text
                          const Center(
                            child: Column(
                              children: [
                                Text(
                                  'We will send you one time',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333),
                                    height: 1.5,
                                  ),
                                ),
                                Text(
                                  'password (OTP)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF333333),
                                    height: 1.5,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Carrier rates may apply',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: primaryOrange,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          // Arrow Button
                          Center(
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: primaryOrange,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryOrange.withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
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

  Widget _buildPhoneMessageIcon() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          // Phone outline
          Container(
            width: 85,
            height: 115,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.black, width: 3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          // Notch at top
          Positioned(
            top: 0,
            left: 22,
            child: Container(
              width: 30,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
            ),
          ),
          // Message bubble
          Positioned(
            top: 28,
            right: 0,
            child: Container(
              width: 55,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.black, width: 2.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.all(7),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 3,
                    width: 22,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return GestureDetector(
      onTap: () {},
      child: Row(
        children: [
          Text(
            _selectedCountry,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, color: Color(0xFF666666), size: 20),
        ],
      ),
    );
  }

  Widget _buildDecoCircle(double size, bool outlined) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
        border: outlined
            ? Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)
            : null,
      ),
    );
  }

  Widget _buildDecoPlus() {
    return SizedBox(
      width: 14,
      height: 14,
      child: CustomPaint(
        painter: PlusPainter(color: Colors.white.withOpacity(0.6)),
      ),
    );
  }

  Widget _buildBlob(double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(60),
      ),
    );
  }
}

class PlusPainter extends CustomPainter {
  final Color color;
  PlusPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}