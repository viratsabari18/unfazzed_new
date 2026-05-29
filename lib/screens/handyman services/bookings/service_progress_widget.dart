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
    "",
    "Professional has started the work",
    ""
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
   
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          const Text(
            "Service Progress",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 13),
          /// STEPS
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
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// LEFT SIDE INDICATOR
              Column(
                children: [
                  /// CIRCLE
                  Container(
                    width: 28,
                    height: 35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFFE9F9EE)
                          : isActive
                          ? const Color(0xFFFFF6E1)
                          : Colors.white,
                    ),
                    child: Center(
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? const Color(0xFF22C55E)
                              : isActive
                              ? const Color(0xFFFFC107)
                              : Colors.white,
                          border: Border.all(
                            color: isCompleted || isActive
                                ? Colors.transparent
                                : Colors.black45,
                            width: 1.5,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 12,
                              )
                            : isActive
                            ? const Icon(
                                Icons.sensors,
                                color: Colors.white,
                                size: 11,
                              )
                            : null,
                      ),
                    ),
                  ),

                  /// CONNECTING LINE
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 12,
                      color: isCompleted || isActive
                          ? const Color(0xFFD7F3DF)
                          : Colors.black12,
                    ),
                ],
              ),

              const SizedBox(width: 10),

              /// RIGHT CONTENT
              Expanded(
                child: Container(
                  padding: isActive
                      ? const EdgeInsets.symmetric(horizontal: 14)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFFFF6E1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// TITLE + SUBTITLE
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isCompleted || isActive
                                    ? Colors.black
                                    : Colors.black87,
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFB7791F),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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

        /// DIVIDER BETWEEN STEPS
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.black12,
            ),
          ),
      ],
    );
  }
}