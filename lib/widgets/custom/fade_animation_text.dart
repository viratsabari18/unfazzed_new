import 'package:zeerah/core/common/app_exports.dart';

class BlinkingText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const BlinkingText({super.key, required this.text, this.style});

  @override
  State<BlinkingText> createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<BlinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: controller,
      child: Text(widget.text, style: widget.style),
    );
  }
}
