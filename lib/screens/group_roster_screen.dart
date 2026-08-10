import 'package:flutter/material.dart';
import '../services/roster_service.dart';

class GroupRosterScreen extends StatefulWidget {
  final String group;

  const GroupRosterScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupRosterScreen> createState() =>
      _GroupRosterScreenState();
}

class _GroupRosterScreenState
    extends State<GroupRosterScreen> {
  DateTime selectedMonth = DateTime.now();

  final ScrollController _scrollController =
      ScrollController();

  // ===================================================
  // MONTH NAME
  // ===================================================

  String monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  // ===================================================
  // WEEKDAY
  // ===================================================

  String shortWeekday(DateTime date) {
    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return weekdays[date.weekday - 1];
  }

  // ===================================================
  // SAME DAY
  // ===================================================

  bool isSameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  // ===================================================
  // CURRENT MONTH
  // ===================================================

  bool get isCurrentMonth {
    final now = DateTime.now();

    return selectedMonth.year == now.year &&
        selectedMonth.month == now.month;
  }

  // ===================================================
  // SCROLL TO TODAY
  // ===================================================

  void scrollToToday({
    bool animated = true,
  }) {
    if (!isCurrentMonth) {
      return;
    }

    final today = DateTime.now();

    const rowHeight = 73.0;
    const separatorHeight = 7.0;

    final targetOffset =
        (today.day - 1) *
            (rowHeight + separatorHeight);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted ||
            !_scrollController.hasClients) {
          return;
        }

        final maxOffset =
            _scrollController
                .position
                .maxScrollExtent;

        final safeOffset =
            targetOffset.clamp(
          0.0,
          maxOffset,
        );

        if (animated) {
          _scrollController.animateTo(
            safeOffset,
            duration:
                const Duration(
              milliseconds: 500,
            ),
            curve:
                Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(
            safeOffset,
          );
        }
      },
    );
  }

  // ===================================================
  // PREVIOUS MONTH
  // ===================================================

  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
      );
    });

    scrollToToday();
  }

  // ===================================================
  // NEXT MONTH
  // ===================================================

  void nextMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
      );
    });

    scrollToToday();
  }

  // ===================================================
  // STATUS ICON
  // ===================================================

  IconData statusIcon(
    String status,
  ) {
    switch (status) {
      case 'D':
        return Icons.wb_sunny_rounded;

      case 'N':
        return Icons.nightlight_round;

      case 'SR':
        return Icons.beach_access_rounded;

      case 'R':
        return Icons.hotel_rounded;

      default:
        return Icons.hotel_rounded;
    }
  }

  // ===================================================
  // IS SCHEDULED REST
  // ===================================================

  bool isScheduledRestStatus(
    String status,
    String detailedStatus,
  ) {
    final detailed =
        detailedStatus
            .trim()
            .toLowerCase();

    return status == 'SR' ||
        detailed == 'scheduled rest';
  }

  // ===================================================
  // IS NORMAL REST
  // ===================================================

  bool isNormalRestStatus(
    String status,
    String detailedStatus,
  ) {
    final detailed =
        detailedStatus
            .trim()
            .toLowerCase();

    return status == 'R' ||
        detailed == 'rest';
  }

  // ===================================================
  // INIT STATE
  // ===================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        scrollToToday(
          animated: false,
        );
      },
    );
  }

  // ===================================================
  // DISPOSE
  // ===================================================

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ===================================================
  // BUILD
  // ===================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final today = DateTime.now();

    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF1565C0),

        foregroundColor:
            Colors.white,

        centerTitle: true,

        title: Text(
          '${widget.group} Roster',

          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          // =================================================
          // MONTH SELECTOR
          // =================================================

          Container(
            color:
                Colors.white,

            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),

            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,

              children: [
                IconButton(
                  onPressed:
                      previousMonth,

                  icon:
                      const Icon(
                    Icons.chevron_left,
                    size: 32,
                  ),
                ),

                Column(
                  children: [
                    Text(
                      '${monthName(selectedMonth.month)} '
                      '${selectedMonth.year}',

                      style:
                          const TextStyle(
                        fontSize:
                            21,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    if (isCurrentMonth)
                      const Padding(
                        padding:
                            EdgeInsets.only(
                          top: 3,
                        ),

                        child:
                            Text(
                          'TODAY',
                          style:
                              TextStyle(
                            fontSize:
                                10,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(
                              0xFF1565C0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                IconButton(
                  onPressed:
                      nextMonth,

                  icon:
                      const Icon(
                    Icons.chevron_right,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          // =================================================
          // HEADER
          // =================================================

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),

            child:
                const Row(
              children: [
                SizedBox(
                  width: 80,

                  child:
                      Text(
                    'Date',

                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child:
                      Text(
                    'Duty Status',

                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // =================================================
          // ROSTER LIST
          // =================================================

          Expanded(
            child:
                ListView.separated(
              controller:
                  _scrollController,

              padding:
                  const EdgeInsets.fromLTRB(
                12,
                0,
                12,
                20,
              ),

              itemCount:
                  daysInMonth,

              separatorBuilder:
                  (
                context,
                index,
              ) {
                return const SizedBox(
                  height: 7,
                );
              },

              itemBuilder:
                  (
                context,
                index,
              ) {
                final day =
                    index + 1;

                final date =
                    DateTime(
                  selectedMonth.year,
                  selectedMonth.month,
                  day,
                );

                // =========================================
                // CURRENT DAY STATUS
                // =========================================

                final status =
                    RosterService
                        .getStatus(
                  widget.group,
                  date,
                );

                final detailedStatus =
                    RosterService
                        .getDetailedStatus(
                  widget.group,
                  date,
                );

                // =========================================
                // TODAY
                // =========================================

                final isToday =
                    isSameDay(
                  date,
                  today,
                );

                // =========================================
                // SCHEDULED REST
                // =========================================

                final isScheduledRest =
                    isScheduledRestStatus(
                  status,
                  detailedStatus,
                );

                // =========================================
                // PREVIOUS DAY
                // =========================================

                final nextDate =
                    date.add(
                  const Duration(
                    days: 1,
                  ),
                );

                final nextStatus =
                    RosterService
                        .getStatus(
                  widget.group,
                  nextDate,
                );

                final nextDetailedStatus =
                    RosterService
                        .getDetailedStatus(
                  widget.group,
                  nextDate,
                );

                // =========================================
                // NORMAL REST
                // =========================================

                final isNormalRest =
                    isNormalRestStatus(
                  status,
                  detailedStatus,
                );

                // =========================================
                // REST IMMEDIATELY BEFORE SCHEDULED REST
                // =========================================

                final isRestBeforeScheduledRest =
                    isNormalRest &&
                    isScheduledRestStatus(
                      nextStatus,
                      nextDetailedStatus,
                    );

                // =========================================
                // FINAL REST HIGHLIGHT
                // =========================================

                final isRestBlock =
                    isScheduledRest ||
                    isRestBeforeScheduledRest;

                // =========================================
                // BACKGROUND
                // =========================================

                final backgroundColor =
                    isToday
                        ? const Color(
                            0xFFE3F2FD,
                          )
                        : isRestBlock
                            ? const Color(
                                0xFFF0F0F0,
                              )
                            : Colors.white;

                // =========================================
                // BORDER
                // =========================================

                final Border? border =
                    isToday
                        ? Border.all(
                            color:
                                const Color(
                              0xFF1565C0,
                            ),
                            width: 2,
                          )
                        : isRestBlock
                            ? Border.all(
                                color:
                                    const Color(
                                  0xFFD0D0D0,
                                ),
                                width: 1,
                              )
                            : null;

                // =========================================
                // ROW
                // =========================================

                return Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        backgroundColor,

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),

                    border:
                        border,

                    boxShadow:
                        isToday
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(
                                    0xFF1565C0,
                                  ).withValues(
                                    alpha:
                                        0.08,
                                  ),
                                  blurRadius:
                                      6,
                                  offset:
                                      const Offset(
                                    0,
                                    2,
                                  ),
                                ),
                              ]
                            : null,
                  ),

                  child:
                      Row(
                    children: [
                      // ===================================
                      // DATE
                      // ===================================

                      SizedBox(
                        width: 80,

                        child:
                            Row(
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                Text(
                                  day
                                      .toString()
                                      .padLeft(
                                        2,
                                        '0',
                                      ),

                                  style:
                                      TextStyle(
                                    fontSize:
                                        18,
                                    fontWeight:
                                        FontWeight
                                            .bold,

                                    color:
                                        isToday
                                            ? const Color(
                                                0xFF1565C0,
                                              )
                                            : Colors
                                                .black,
                                  ),
                                ),

                                const SizedBox(
                                  height: 2,
                                ),

                                Text(
                                  shortWeekday(
                                    date,
                                  ),

                                  style:
                                      TextStyle(
                                    fontSize:
                                        11,
                                    fontWeight:
                                        FontWeight
                                            .w600,

                                    color:
                                        isToday
                                            ? const Color(
                                                0xFF1565C0,
                                              )
                                            : Colors
                                                .grey,
                                  ),
                                ),
                              ],
                            ),

                            // =================================
                            // TODAY BADGE
                            // =================================

                            if (isToday) ...[
                              const SizedBox(
                                width: 6,
                              ),

                              Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal:
                                      5,
                                  vertical:
                                      2,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color:
                                      const Color(
                                    0xFF1565C0,
                                  ),

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    5,
                                  ),
                                ),

                                child:
                                    const Text(
                                  'TODAY',

                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        7,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ===================================
                      // STATUS ICON
                      // ===================================

                      Icon(
                        statusIcon(
                          status,
                        ),

                        size:
                            22,

                        color:
                            isToday
                                ? const Color(
                                    0xFF1565C0,
                                  )
                                : isRestBlock
                                    ? const Color(
                                        0xFF757575,
                                      )
                                    : Colors.grey,
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      // ===================================
                      // STATUS
                      // ===================================

                      Expanded(
                        child:
                            Text(
                          detailedStatus,

                          style:
                              TextStyle(
                            fontSize:
                                16,

                            fontWeight:
                                FontWeight
                                    .w600,

                            color:
                                isToday
                                    ? const Color(
                                        0xFF1565C0,
                                      )
                                    : isRestBlock
                                        ? const Color(
                                            0xFF555555,
                                          )
                                        : Colors
                                            .black,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}