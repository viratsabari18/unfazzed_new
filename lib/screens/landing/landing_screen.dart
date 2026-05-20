import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zeerah/core/common/app_exports.dart';
import 'package:zeerah/screens/handyman%20services/bookings/booking_history.dart';
import 'package:zeerah/screens/home/home_page.dart';
import 'package:zeerah/screens/profile/help_desk_screen.dart';
import 'package:zeerah/screens/profile/support_ticket_detail_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() =>
      _LandingScreenState();
}

class _LandingScreenState
    extends State<LandingScreen> {
  int currentIndex = 0;

  late PageController _pageController;

  final List<Widget> pages = [
    const HomePage(),
    BookingHistory(),
   HelpDeskScreen()
  ];

  final List<IconData> icons = [
    Icons.home_rounded,
    Icons.calendar_today_rounded,
    Icons.emoji_events_rounded,
  ];

  final List<String> labels = [
    UserMessages.home,
    UserMessages.bookings,
    "Support",
  ];

  @override
  void initState() {
    super.initState();

    _pageController =
        PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void onTabTapped(int index) {
    setState(() => currentIndex = index);

    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor:
            AppColors.naturalWhite,

        body: PageView(
          controller: _pageController,
          physics:
              const NeverScrollableScrollPhysics(),
          children: pages,
        ),

        // ───────────────── NAVBAR ─────────────────
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: EdgeInsets.only(
              left: AppSizes.w(context, 20),
              right: AppSizes.w(context, 20),
              bottom: AppSizes.h(context, 10),
            ),

            height: AppSizes.h(context, 64),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius:
                  BorderRadius.circular(
                AppSizes.w(context, 32),
              ),

              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(
                    0.06,
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),

            child: LayoutBuilder(
              builder:
                  (context, constraints) {
                final itemWidth =
                    constraints.maxWidth /
                        icons.length;

                final pillWidth =
                    itemWidth -
                        AppSizes.w(
                          context,
                          18,
                        );

                final pillHeight =
                    AppSizes.h(
                  context,
                  46,
                );

                return Stack(
                  children: [
                    // ───────── GLASS EFFECT ─────────
                    AnimatedPositioned(
                      duration:
                          const Duration(
                        milliseconds: 260,
                      ),

                      curve:
                          Curves.easeOutCubic,

                      left:
                          currentIndex *
                                  itemWidth +
                              AppSizes.w(
                                context,
                                9,
                              ),

                      top:
                          AppSizes.h(
                        context,
                        9,
                      ),

                      child: _GlassPill(
                        width: pillWidth,
                        height: pillHeight,
                      ),
                    ),

                    // ───────── NAV ITEMS ─────────
                    Row(
                      children:
                          List.generate(
                        icons.length,
                        (index) {
                          final isSelected =
                              currentIndex ==
                                  index;

                          // ───────── THIRD TAB ─────────
                          if (index == 2) {
                            return Expanded(
                              child:
                                  GestureDetector(
                                onTap: () =>
                                    onTabTapped(
                                  index,
                                ),

                                child: Padding(
                                  padding:
                                      EdgeInsets.symmetric(
                                    horizontal:
                                        AppSizes.w(
                                      context,
                                      4,
                                    ),

                                    vertical:
                                        AppSizes.h(
                                      context,
                                      8,
                                    ),
                                  ),

                                  child:
                                      Container(
                                    decoration:
                                        BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(
                                        22,
                                      ),

                                      gradient:
                                          const LinearGradient(
                                        begin:
                                            Alignment.topLeft,
                                        end:
                                            Alignment.bottomRight,
                                        colors: [
                                          Color(
                                            0xFF0B2A89,
                                          ),
                                          Color(
                                            0xFF1239C4,
                                          ),
                                          Color(
                                            0xFF081C68,
                                          ),
                                        ],
                                      ),

                                      border:
                                          Border.all(
                                        color: Colors
                                            .white
                                            .withOpacity(
                                          0.45,
                                        ),
                                        width:
                                            1,
                                      ),

                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors
                                              .blue
                                              .withOpacity(
                                            0.18,
                                          ),
                                          blurRadius:
                                              10,
                                          offset:
                                              const Offset(
                                            0,
                                            4,
                                          ),
                                        ),
                                      ],
                                    ),

                                    child:
                                        ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(
                                        22,
                                      ),

                                      child:
                                          Stack(
                                        children: [
                                          // LEFT CURVE
                                          Positioned(
                                            left:
                                                -14,
                                            top:
                                                -2,

                                            child:
                                                Container(
                                              width:
                                                  40,
                                              height:
                                                  50,

                                              decoration:
                                                  BoxDecoration(
                                                border:
                                                    Border.all(
                                                  color: Colors
                                                      .white
                                                      .withOpacity(
                                                    0.7,
                                                  ),
                                                  width:
                                                      2,
                                                ),

                                                borderRadius:
                                                    BorderRadius.circular(
                                                  50,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // SHINE
                                          Positioned(
                                            top:
                                                2,
                                            left:
                                                16,

                                            child:
                                                Container(
                                              width:
                                                  50,
                                              height:
                                                  10,

                                              decoration:
                                                  BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  50,
                                                ),

                                                gradient:
                                                    LinearGradient(
                                                  colors: [
                                                    Colors.white.withOpacity(
                                                      0.35,
                                                    ),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),

                                          // TEXT
                                          Center(
                                            child:
                                                Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.end,

                                              children: [
                                               

                                                Text(
                                                  "Support",

                                                  style:
                                                      TextStyle(
                                                    color:
                                                        Colors.white,

                                                    fontSize:
                                                        AppSizes.w(
                                                      context,
                                                      15,
                                                    ),

                                                    fontWeight:
                                                        FontWeight.w900,

                                                    letterSpacing:
                                                        0.5,
                                                  ),
                                                ),

                                            
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          // ───────── NORMAL TABS ─────────
                          return Expanded(
                            child:
                                GestureDetector(
                              onTap: () =>
                                  onTabTapped(
                                index,
                              ),

                              behavior:
                                  HitTestBehavior
                                      .translucent,

                              child: SizedBox(
                                height:
                                    AppSizes.h(
                                  context,
                                  64,
                                ),

                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,

                                  children: [
                                    AnimatedScale(
                                      duration:
                                          const Duration(
                                        milliseconds:
                                            220,
                                      ),

                                      scale:
                                          isSelected
                                              ? 1
                                              : 0.86,

                                      child:
                                          Icon(
                                        icons[
                                            index],

                                        size:
                                            AppSizes.w(
                                          context,
                                          22,
                                        ),

                                        color:
                                            isSelected
                                                ? Colors.black
                                                : Colors.black.withOpacity(
                                                    0.38,
                                                  ),
                                      ),
                                    ),

                                    SizedBox(
                                      height:
                                          AppSizes.h(
                                        context,
                                        2,
                                      ),
                                    ),

                                    AnimatedDefaultTextStyle(
                                      duration:
                                          const Duration(
                                        milliseconds:
                                            220,
                                      ),

                                      style:
                                          TextStyle(
                                        fontSize:
                                            AppSizes.w(
                                          context,
                                          10,
                                        ),

                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,

                                        color:
                                            isSelected
                                                ? Colors.black
                                                : Colors.black.withOpacity(
                                                    0.40,
                                                  ),
                                      ),

                                      child:
                                          Text(
                                        labels[
                                            index],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────── GLASS PILL ─────────────────

class _GlassPill extends StatefulWidget {
  final double width;
  final double height;

  const _GlassPill({
    required this.width,
    required this.height,
  });

  @override
  State<_GlassPill> createState() =>
      _GlassPillState();
}

class _GlassPillState
    extends State<_GlassPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();

    _shimmer = AnimationController(
      vsync: this,

      duration: const Duration(
        milliseconds: 1800,
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius =
        BorderRadius.circular(26);

    return ClipRRect(
      borderRadius: radius,

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),

        child: Container(
          width: widget.width,
          height: widget.height,

          decoration: BoxDecoration(
            borderRadius: radius,

            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end:
                  Alignment.bottomRight,

              colors: [
                Colors.white.withOpacity(
                  0.45,
                ),
                Colors.white.withOpacity(
                  0.10,
                ),
              ],
            ),

            border: Border.all(
              color:
                  Colors.white.withOpacity(
                0.45,
              ),
              width: 1,
            ),

            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(
                  0.05,
                ),
                blurRadius: 10,
                offset: const Offset(
                  0,
                  3,
                ),
              ),
            ],
          ),

          child: Stack(
            children: [
              Positioned(
                top: -10,
                left: 6,

                child: Container(
                  width:
                      widget.width * 0.52,
                  height: 20,

                  decoration:
                      BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      50,
                    ),

                    gradient:
                        LinearGradient(
                      colors: [
                        Colors.white
                            .withOpacity(
                          0.60,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              AnimatedBuilder(
                animation: _shimmer,

                builder: (_, __) {
                  return Positioned.fill(
                    child: Container(
                      decoration:
                          BoxDecoration(
                        borderRadius:
                            radius,

                        gradient:
                            SweepGradient(
                          startAngle:
                              _shimmer.value *
                                  2 *
                                  pi,

                          endAngle:
                              (_shimmer.value *
                                      2 *
                                      pi) +
                                  pi,

                          colors: [
                            Colors
                                .transparent,
                            Colors.blue
                                .withOpacity(
                              0.08,
                            ),
                            Colors.purple
                                .withOpacity(
                              0.06,
                            ),
                            Colors
                                .transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,

                child: Container(
                  height:
                      widget.height *
                          0.25,

                  decoration:
                      BoxDecoration(
                    borderRadius:
                        const BorderRadius.only(
                      bottomLeft:
                          Radius.circular(
                        26,
                      ),
                      bottomRight:
                          Radius.circular(
                        26,
                      ),
                    ),

                    gradient:
                        LinearGradient(
                      begin:
                          Alignment
                              .topCenter,
                      end: Alignment
                          .bottomCenter,

                      colors: [
                        Colors
                            .transparent,
                        Colors.black
                            .withOpacity(
                          0.03,
                        ),
                      ],
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
}