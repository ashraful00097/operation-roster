import 'package:flutter/material.dart';
import '../services/roster_service.dart';

class MonthlyRosterScreen extends StatefulWidget {
  const MonthlyRosterScreen({super.key});

  @override
  State<MonthlyRosterScreen> createState() =>
      _MonthlyRosterScreenState();
}

class _MonthlyRosterScreenState
    extends State<MonthlyRosterScreen> {
  DateTime selectedMonth = DateTime.now();

  final ScrollController _scrollController =
      ScrollController();

  // Approximate height of each roster row + gap
  static const double _rowHeight = 76;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ===================================================
  // AUTO SCROLL TO TODAY
  // ===================================================

  void _scrollToToday() {
    final today = DateTime.now();

    final isCurrentMonth =
        selectedMonth.year == today.year &&
        selectedMonth.month == today.month;

    if (!isCurrentMonth ||
        !_scrollController.hasClients) {
      return;
    }

    // Keep about 2 dates above today's date visible.
    final targetIndex =
        today.day > 3 ? today.day - 3 : 0;

    final targetOffset =
        targetIndex * _rowHeight;

    final maxOffset =
        _scrollController.position.maxScrollExtent;

    final safeOffset =
        targetOffset.clamp(0.0, maxOffset);

    _scrollController.animateTo(
      safeOffset,
      duration: const Duration(
        milliseconds: 500,
      ),
      curve: Curves.easeOut,
    );
  }

  // ===================================================
  // MONTH CONTROLS
  // ===================================================

  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleMonthChange();
    });
  }

  void nextMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleMonthChange();
    });
  }

  void _handleMonthChange() {
    final today = DateTime.now();

    final isCurrentMonth =
        selectedMonth.year == today.year &&
        selectedMonth.month == today.month;

    if (isCurrentMonth) {
      _scrollToToday();
    } else {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

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
  // WEEKDAY NAME
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
  // CHECK TODAY
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
  // BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF1565C0),
        foregroundColor: Colors.white,

        title: const Text(
          'Monthly Roster',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          // =============================================
          // MONTH SELECTOR
          // =============================================

          Container(
            color: Colors.white,

            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),

            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                IconButton(
                  onPressed: previousMonth,
                  icon: const Icon(
                    Icons.chevron_left,
                    size: 32,
                  ),
                ),

                Text(
                  '${monthName(selectedMonth.month)} '
                  '${selectedMonth.year}',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  onPressed: nextMonth,
                  icon: const Icon(
                    Icons.chevron_right,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          // =============================================
          // TABLE HEADER
          // =============================================

          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),

            child: const Row(
              children: [
                SizedBox(
                  width: 65,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    'Day',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    'Night',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    'Schedule\nRest',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // =============================================
          // MONTHLY ROSTER LIST
          // =============================================

          Expanded(
            child: ListView.separated(
              controller: _scrollController,

              padding: const EdgeInsets.fromLTRB(
                10,
                0,
                10,
                20,
              ),

              itemCount: daysInMonth,

              separatorBuilder:
                  (context, index) =>
                      const SizedBox(height: 7),

              itemBuilder: (context, index) {
                final day = index + 1;

                final date = DateTime(
                  selectedMonth.year,
                  selectedMonth.month,
                  day,
                );

                final isToday =
                    isSameDay(date, today);

                // =======================================
                // DUTY GROUPS
                // =======================================

                final dayGroup =
                    RosterService.getDayGroup(
                  date,
                );

                final nightGroup =
                    RosterService.getNightGroup(
                  date,
                );

                final scheduleRest =
                    RosterService
                        .getScheduleRestGroups(
                  date,
                );

                // =======================================
                // DAY DUTY NUMBER
                // =======================================

                String dayDutyText = '';

                if (dayGroup != null) {
                  final number =
                      RosterService.getDayNumber(
                    dayGroup,
                    date,
                  );

                  if (number != null) {
                    dayDutyText =
                        '${RosterService.ordinal(number)} Day';
                  }
                }

                // =======================================
                // NIGHT DUTY NUMBER
                // =======================================

                String nightDutyText = '';

                if (nightGroup != null) {
                  final number =
                      RosterService.getNightNumber(
                    nightGroup,
                    date,
                  );

                  if (number != null) {
                    nightDutyText =
                        '${RosterService.ordinal(number)} Night';
                  }
                }

                // =======================================
                // ROSTER ROW
                // =======================================

                return Container(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 12,
                  ),

                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(
                            0xFFE3F2FD,
                          )
                        : Colors.white,

                    borderRadius:
                        BorderRadius.circular(12),

                    border: isToday
                        ? Border.all(
                            color:
                                const Color(
                              0xFF1565C0,
                            ),
                            width: 2,
                          )
                        : null,

                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 8,
                              offset:
                                  const Offset(
                                0,
                                3,
                              ),
                            ),
                          ]
                        : null,
                  ),

                  child: Row(
                    children: [
                      // =================================
                      // DATE + WEEKDAY + TODAY
                      // =================================

                      SizedBox(
                        width: 65,

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            Row(
                              children: [
                                Text(
                                  day
                                      .toString()
                                      .padLeft(
                                        2,
                                        '0',
                                      ),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight:
                                        FontWeight.bold,
                                    color: isToday
                                        ? const Color(
                                            0xFF1565C0,
                                          )
                                        : Colors.black,
                                  ),
                                ),

                                // TODAY stays beside date
                                if (isToday) ...[
                                  const SizedBox(
                                    width: 4,
                                  ),

                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 4,
                                      vertical: 2,
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
                                        fontSize: 7,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(
                              height: 2,
                            ),

                            // WEEKDAY stays below date
                            Text(
                              shortWeekday(date),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w600,
                                color: isToday
                                    ? const Color(
                                        0xFF1565C0,
                                      )
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // =================================
                      // DAY DUTY
                      // =================================

                      Expanded(
                        child: Column(
                          children: [
                            Icon(
                              Icons
                                  .wb_sunny_rounded,
                              size: 18,
                              color: isToday
                                  ? const Color(
                                      0xFF1565C0,
                                    )
                                  : null,
                            ),

                            const SizedBox(
                              height: 3,
                            ),

                            Text(
                              dayGroup ?? '-',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.bold,
                                color: isToday
                                    ? const Color(
                                        0xFF1565C0,
                                      )
                                    : Colors.black,
                              ),
                            ),

                            if (dayDutyText
                                .isNotEmpty)
                              Text(
                                dayDutyText,
                                style:
                                    const TextStyle(
                                  fontSize: 11,
                                  color:
                                      Colors.grey,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // =================================
                      // NIGHT DUTY
                      // =================================

                      Expanded(
                        child: Column(
                          children: [
                            Icon(
                              Icons
                                  .nightlight_round,
                              size: 18,
                              color: isToday
                                  ? const Color(
                                      0xFF1565C0,
                                    )
                                  : null,
                            ),

                            const SizedBox(
                              height: 3,
                            ),

                            Text(
                              nightGroup ?? '-',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.bold,
                                color: isToday
                                    ? const Color(
                                        0xFF1565C0,
                                      )
                                    : Colors.black,
                              ),
                            ),

                            if (nightDutyText
                                .isNotEmpty)
                              Text(
                                nightDutyText,
                                style:
                                    const TextStyle(
                                  fontSize: 11,
                                  color:
                                      Colors.grey,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // =================================
                      // SCHEDULE REST
                      // =================================

                      Expanded(
                        child: Column(
                          children: [
                            Icon(
                              Icons
                                  .beach_access_rounded,
                              size: 18,
                              color: isToday
                                  ? const Color(
                                      0xFF1565C0,
                                    )
                                  : null,
                            ),

                            const SizedBox(
                              height: 3,
                            ),

                            Text(
                              scheduleRest,
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.bold,
                                color: isToday
                                    ? const Color(
                                        0xFF1565C0,
                                      )
                                    : Colors.black,
                              ),
                            ),
                          ],
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