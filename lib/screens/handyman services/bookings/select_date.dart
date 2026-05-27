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
  String selectedTime = "";

  // Time slots organized by period
  final Map<String, List<String>> slotsByPeriod = {
    UserMessages.morning: ["8:00 AM", "9:00 AM", "10:00 AM", "11:00 AM"],
    UserMessages.afternoon: ["12:00 PM", "1:00 PM", "2:00 PM", "3:00 PM"],
    UserMessages.evening: ["4:00 PM", "5:00 PM", "6:00 PM", "7:00 PM"],
  };

  List<String> get timeSlots => slotsByPeriod[selectedSlot] ?? [];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    _updateCurrentTime();
    
    // Initial callback with current date and time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDateSelected(selectedDate);
      widget.onTimeSelected(selectedSlot, selectedTime);
    });
  }
  
  void _updateCurrentTime() {
    selectedTime = DateFormat('h:mm a').format(DateTime.now());
  }

  // Time slot card with shadow design
  Widget timeSlotCard({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: Insets.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : AppColors.naturalWhite,
          borderRadius: BorderRadius.circular(Insets.md),
          border: isSelected 
              ? null 
              : Border.all(width: 0.5, color: AppColors.darkGray.withOpacity(0.2)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: AppSizes.w(context, 8),
                    spreadRadius: 1,
                  ),
                ]
              : [
                  // Outer shadow (bottom-right)
                  BoxShadow(
                    color: AppColors.naturalBlack.withOpacity(0.08),
                    offset: const Offset(3, 3),
                    blurRadius: AppSizes.w(context, 6),
                    spreadRadius: 1,
                  ),
                  // Inner shadow effect (top-left)
                  BoxShadow(
                    color: AppColors.naturalWhite.withOpacity(0.8),
                    offset: const Offset(-2, -2),
                    blurRadius: AppSizes.w(context, 4),
                  ),
                ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? AppColors.naturalWhite : AppColors.naturalBlack,
            fontWeight: FontWeight.w500,
            fontSize: AppSizes.w(context, 14),
          ),
        ),
      ),
    );
  }

  // Period category chip with shadow
  Widget periodChip({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.sm,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.primaryRed,
                    AppColors.primaryRed.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : AppColors.naturalWhite,
          borderRadius: BorderRadius.circular(Insets.lg),
          border: isSelected
              ? null
              : Border.all(width: 0.8, color: AppColors.darkGray.withOpacity(0.15)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryRed.withOpacity(0.4),
                    offset: const Offset(0, 4),
                    blurRadius: AppSizes.w(context, 8),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.naturalBlack.withOpacity(0.06),
                    offset: const Offset(2, 2),
                    blurRadius: AppSizes.w(context, 5),
                  ),
                  BoxShadow(
                    color: AppColors.naturalWhite,
                    offset: const Offset(-1, -1),
                    blurRadius: AppSizes.w(context, 3),
                  ),
                ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? AppColors.naturalWhite : AppColors.naturalBlack,
            fontWeight: FontWeight.w600,
            fontSize: AppSizes.w(context, 14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: AppSizes.h(context, 10)),
        
        // Header Section
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Insets.sm),
          child: Text(
            UserMessages.availableTimeSlots,
            style: TextStyle(
              fontSize: AppSizes.w(context, 20),
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
        ),
        
        SizedBox(height: AppSizes.h(context, 16)),
        
        // // Period Category Selection
        // Padding(
        //   padding: EdgeInsets.symmetric(horizontal: Insets.sm),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //     children: UserMessages.timeSlotsCategory.map((slot) {
        //       return Expanded(
        //         child: Padding(
        //           padding: EdgeInsets.symmetric(horizontal: Insets.xxs),
        //           child: periodChip(
        //             text: slot,
        //             isSelected: selectedSlot == slot,
        //             onTap: () {
        //               setState(() {
        //                 selectedSlot = slot;
        //                 selectedTime = timeSlots.first;
        //               });
        //               widget.onTimeSelected(selectedSlot, selectedTime);
        //             },
        //           ),
        //         ),
        //       );
        //     }).toList(),
        //   ),
        // ),
        
        // SizedBox(height: AppSizes.h(context, 20)),
        
        // Time Slots Grid
        // Padding(
        //   padding: EdgeInsets.symmetric(horizontal: Insets.sm),
        //   child: GridView.builder(
        //     shrinkWrap: true,
        //     physics: const NeverScrollableScrollPhysics(),
        //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        //       crossAxisCount: 4,
        //       crossAxisSpacing: Insets.sm,
        //       mainAxisSpacing: Insets.sm,
        //       childAspectRatio: 1.3,
        //     ),
        //     itemCount: timeSlots.length,
        //     itemBuilder: (context, index) {
        //       String time = timeSlots[index];
        //       bool isSelected = selectedTime == time;
              
        //       return timeSlotCard(
        //         text: time,
        //         isSelected: isSelected,
        //         onTap: () {
        //           setState(() => selectedTime = time);
        //           widget.onTimeSelected(selectedSlot, selectedTime);
        //         },
        //       );
        //     },
        //   ),
        // ),
        
        // SizedBox(height: AppSizes.h(context, 24)),
        
        // Selected Info Card with Shadow
        Container(
          margin: EdgeInsets.symmetric(horizontal: Insets.sm),
          padding: EdgeInsets.all(Insets.sm),
          decoration: BoxDecoration(
            color: AppColors.naturalWhite,
            borderRadius: BorderRadius.circular(Insets.lg),
            boxShadow: [
              // Main shadow
              BoxShadow(
                color: AppColors.naturalBlack.withOpacity(0.1),
                offset: const Offset(0, 4),
                blurRadius: AppSizes.w(context, 12),
                spreadRadius: 0,
              ),
              // Inner top shadow for depth
              BoxShadow(
                color: AppColors.naturalWhite,
                offset: const Offset(-1, -1),
                blurRadius: AppSizes.w(context, 4),
              ),
              // Subtle bottom shadow
              BoxShadow(
                color: AppColors.naturalBlack.withOpacity(0.05),
                offset: const Offset(1, 1),
                blurRadius: AppSizes.w(context, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Time Icon Container
              Stack(
                children: [
                  Container(
                    width: AppSizes.w(context, 52),
                    height: AppSizes.h(context, 52),
                    decoration: BoxDecoration(
                      color: AppColors.calendarBg,
                      borderRadius: BorderRadius.circular(Insets.md),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryRed.withOpacity(0.15),
                          offset: const Offset(0, 2),
                          blurRadius: AppSizes.w(context, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.access_time_filled,
                      color: AppColors.primaryRed,
                      size: 28,
                    ),
                  ),
                  Positioned(
                    bottom: AppSizes.h(context, 4),
                    right: AppSizes.w(context, 4),
                    child: Container(
                      width: AppSizes.w(context, 18),
                      height: AppSizes.h(context, 18),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryRed.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: AppColors.naturalWhite,
                      ),
                    ),
                  )
                ],
              ),
              
              SizedBox(width: Insets.md),
              
              // Selected Info Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      UserMessages.selected,
                      style: TextStyle(
                        fontSize: AppSizes.w(context, 12),
                        color: AppColors.naturalBlack.withOpacity(0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: AppSizes.h(context, 4)),
                    Text(
                      "Today, ${DateFormat("d MMM").format(DateTime.now())} · $selectedTime",
                      style: TextStyle(
                        fontSize: AppSizes.w(context, 15),
                        fontWeight: FontWeight.w700,
                        color: AppColors.naturalBlack,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Check Icon
              Container(
                width: AppSizes.w(context, 44),
                height: AppSizes.h(context, 44),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryRed,
                      AppColors.primaryRed.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRed.withOpacity(0.4),
                      offset: const Offset(0, 4),
                      blurRadius: AppSizes.w(context, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.naturalWhite,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: AppSizes.h(context, 16)),
      ],
    );
  }
}