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

  bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
      );
    });
  }

  void nextMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + 1,
      );
    });
  }

  IconData statusIcon(String status) {
    switch (status) {
      case 'D':
        return Icons.wb_sunny_rounded;

      case 'N':
        return Icons.nightlight_round;

      case 'SR':
        return Icons.beach_access_rounded;

      default:
        return Icons.hotel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          '${widget.group} Roster',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          // MONTH SELECTOR
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

          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child: Text(
                    'Duty Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ROSTER LIST
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                12,
                0,
                12,
                20,
              ),
              itemCount: daysInMonth,

              separatorBuilder: (context, index) =>
                  const SizedBox(height: 7),

              itemBuilder: (context, index) {
                final day = index + 1;

                final date = DateTime(
                  selectedMonth.year,
                  selectedMonth.month,
                  day,
                );

                final status =
                    RosterService.getStatus(
                  widget.group,
                  date,
                );

                final detailedStatus =
                    RosterService.getDetailedStatus(
                  widget.group,
                  date,
                );

                final isToday = isSameDay(
                  date,
                  today,
                );

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),

                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFFE3F2FD)
                        : Colors.white,

                    borderRadius:
                        BorderRadius.circular(12),

                    border: isToday
                        ? Border.all(
                            color:
                                const Color(0xFF1565C0),
                            width: 2,
                          )
                        : null,
                  ),

                  child: Row(
                    children: [
                      // DATE
                      SizedBox(
                        width: 80,
                        child: Row(
                          children: [
                            Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      day.toString().padLeft(2, '0'),
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isToday
            ? const Color(0xFF1565C0)
            : Colors.black,
      ),
    ),

    const SizedBox(height: 2),

    Text(
      shortWeekday(date),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: isToday
            ? const Color(0xFF1565C0)
            : Colors.grey,
      ),
    ),
  ],
),

                            if (isToday) ...[
                              const SizedBox(width: 6),

                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1565C0,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(
                                    5,
                                  ),
                                ),
                                child: const Text(
                                  'TODAY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 7,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // STATUS ICON
                      Icon(
                        statusIcon(status),
                        size: 22,
                        color: isToday
                            ? const Color(0xFF1565C0)
                            : Colors.grey,
                      ),

                      const SizedBox(width: 12),

                      // STATUS
                      Expanded(
                        child: Text(
                          detailedStatus,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.w600,
                            color: isToday
                                ? const Color(
                                    0xFF1565C0,
                                  )
                                : Colors.black,
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