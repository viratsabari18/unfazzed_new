import 'package:flutter/material.dart';
import 'package:zeerah/core/common/app_exports.dart';

class ServiceProgressWidget extends StatefulWidget {
  final int currentStep;
  const ServiceProgressWidget({this.currentStep = 4, super.key});

  @override
  State<ServiceProgressWidget> createState() => _ServiceProgressWidgetState();
}

class _ServiceProgressWidgetState extends State<ServiceProgressWidget> {
  final List<String> steps = [
    UserMessages.bookingConfirmed,
    UserMessages.professionalAssigned,
    UserMessages.onTheWay,
    UserMessages.serviceStarted,
    UserMessages.serviceCompleted
  ];

  final List<String> subtitles = [
    "",
    "",
    "On their way to your location",
    "Professional has started the work",
    ""
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSizes.h(context, 16)),
      padding: EdgeInsets.all(Insets.sm),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.naturalWhite,
        borderRadius: BorderRadius.circular(Insets.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            UserMessages.serviceProgress,
            style: TextStyle(
              color: const Color(0xFFD90000),
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.w(context, 18),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (index) {
            final bool isCompleted = index < widget.currentStep;
            final bool isActive = index == widget.currentStep;
            final bool isLast = index == steps.length - 1;

            return _buildProgressStep(
              steps[index],
              subtitle: subtitles[index],
              isCompleted: isCompleted,
              isActive: isActive,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProgressStep(String title, {required String subtitle, required bool isCompleted, bool isActive = false, required bool isLast}) {
    Color bgColor = Colors.white;
    if (isCompleted) {
      bgColor = const Color(0xFFE8F5E9); // Light Green
    } else if (isActive) {
      bgColor = const Color(0xFFFEDC85); // Light Yellow
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? const Color(0xFFC8E6C9) : (isActive ? const Color(0xFFFEDC85) : Colors.white),
                border: Border.all(color: (isCompleted || isActive) ? Colors.transparent : Colors.black26),
              ),
              child: Icon(
                isCompleted ? Icons.check : (isActive ? Icons.sensors : null),
                size: 14,
                color: isCompleted ? Colors.green[800] : (isActive ? Colors.orange[800] : Colors.transparent),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green[200] : Colors.black12,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: (isCompleted || isActive) ? Colors.black : Colors.black54,
                            ),
                          ),
                          if (isActive && subtitle.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                subtitle,
                                style: const TextStyle(fontSize: 10, color: Colors.black54),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isActive) const Icon(Icons.sensors, color: Color(0xFFD90000), size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
