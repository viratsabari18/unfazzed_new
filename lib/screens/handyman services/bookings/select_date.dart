import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zeerah/core/common/app_exports.dart';

class SelectDate extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final Function(String, String) onTimeSelected;

  const SelectDate({
    required this.onDateSelected,
    required this.onTimeSelected,
    super.key,
  });

  @override
  State<SelectDate> createState() => _SelectDateState();
}

class _SelectDateState extends State<SelectDate> {
  DateTime currentMonth = DateTime.now();
  late DateTime selectedDate;

  String selectedSlot = UserMessages.morning;
  late String selectedTime;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    selectedTime = slotsByPeriod[selectedSlot]?.first ?? "10:00 AM";
    
    // Initial callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDateSelected(selectedDate);
      widget.onTimeSelected(selectedSlot, selectedTime);
    });
  }

  final Map<String, List<String>> slotsByPeriod = {
    UserMessages.morning: ["8:00 AM", "9:00 AM", "10:00 AM", "11:00 AM"],
    UserMessages.afternoon: ["12:00 PM", "1:00 PM", "2:00 PM", "3:00 PM"],
    UserMessages.evening: ["4:00 PM", "5:00 PM", "6:00 PM", "7:00 PM"],
  };

  List<String> get timeSlots => slotsByPeriod[selectedSlot] ?? [];

  Widget innerShadowChip({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Insets.md, vertical: Insets.xs),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : AppColors.naturalWhite,
          border: Border.all(width: 0.5, color: AppColors.darkGray),
          borderRadius: BorderRadius.circular(Insets.md),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? AppColors.naturalWhite : AppColors.naturalBlack,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateUtils.getDaysInMonth(currentMonth.year, currentMonth.month);
    int firstDay = DateTime(currentMonth.year, currentMonth.month, 1).weekday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSizes.h(context, 10)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Insets.sm),
          child: Text(
            UserMessages.availableTimeSlots,
            style: TextStyle(
              fontSize: AppSizes.w(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: AppSizes.h(context, 4)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Insets.sm),
          child: Text(
            "Booking for Today (${DateFormat("d MMM, yyyy").format(DateTime.now())})",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        SizedBox(height: AppSizes.h(context, 16)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: UserMessages.timeSlotsCategory.map((slot) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: Insets.xxs),
              child: innerShadowChip(
                text: slot,
                isSelected: selectedSlot == slot,
                onTap: () {
                  setState(() {
                    selectedSlot = slot;
                    selectedTime = timeSlots.first;
                  });
                  widget.onTimeSelected(selectedSlot, selectedTime);
                },
              ),
            );
          }).toList(),
        ),
        SizedBox(height: AppSizes.h(context, 12)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Insets.sm),
          child: Wrap(
            spacing: Insets.xs,
            runSpacing: Insets.xs,
            children: timeSlots.map((time) {
              bool isSelected = selectedTime == time;

              return GestureDetector(
                onTap: () {
                  setState(() => selectedTime = time);
                  widget.onTimeSelected(selectedSlot, selectedTime);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: Insets.sm, vertical: Insets.xs),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryRed : AppColors.naturalWhite,
                    borderRadius: BorderRadius.circular(Insets.md),
                    boxShadow: isSelected
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.naturalBlack.withOpacity(0.1),
                              offset: const Offset(2, 2),
                              blurRadius: AppSizes.w(context, 6),
                            ),
                            BoxShadow(
                              color: AppColors.naturalWhite.withOpacity(0.9),
                              offset: const Offset(-2, -2),
                              blurRadius: AppSizes.w(context, 6),
                            ),
                          ],
                  ),
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isSelected ? AppColors.naturalWhite : AppColors.naturalBlack,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: AppSizes.h(context, 20)),
        Container(
          padding: EdgeInsets.symmetric(horizontal: Insets.sm, vertical: Insets.xsm),
          decoration: BoxDecoration(
            color: AppColors.naturalWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(Insets.sm)),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: AppSizes.w(context, 48),
                    height: AppSizes.h(context, 48),
                    decoration: BoxDecoration(
                      color: AppColors.calendarBg,
                      borderRadius: BorderRadius.circular(Insets.xsm),
                    ),
                    child: const Icon(Icons.access_time_filled, color: AppColors.primaryRed),
                  ),
                  Positioned(
                    bottom: AppSizes.h(context, 5),
                    right: AppSizes.w(context, 5),
                    child: Container(
                      width: AppSizes.w(context, 16),
                      height: AppSizes.h(context, 16),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 10, color: AppColors.naturalWhite),
                    ),
                  )
                ],
              ),
              SizedBox(width: Insets.xsm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      UserMessages.selected,
                      style: TextStyle(fontSize: AppSizes.w(context, 12)),
                    ),
                    Text(
                      "Today, ${DateFormat("d MMM").format(DateTime.now())} · $selectedTime",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                width: AppSizes.w(context, 40),
                height: AppSizes.h(context, 40),
                decoration: const BoxDecoration(
                  color: AppColors.primaryRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.naturalWhite),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
