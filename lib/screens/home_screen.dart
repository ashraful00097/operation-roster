import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/roster_service.dart';
import 'emergency_roster_screen.dart';
import 'excel_roster_screen.dart';
import 'group_roster_screen.dart';
import 'monthly_roster_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();

  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color backgroundColor = Color(0xFFF4F6F9);

  // ===================================================
  // DATE FORMAT
  // ===================================================

  String formatDate(DateTime date) {
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

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final dayName = weekdays[date.weekday - 1];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year} • $dayName';
  }

  // ===================================================
  // TODAY CHECK
  // ===================================================

  bool get isToday {
    final today = DateTime.now();

    return selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;
  }

  // ===================================================
  // EXIT CONFIRMATION
  // ===================================================

  Future<bool> showExitConfirmation() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.exit_to_app_rounded,
            color: primaryBlue,
            size: 36,
          ),
          title: const Text(
            'Exit App?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Do you want to exit?',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(
                Icons.exit_to_app_rounded,
                size: 18,
              ),
              label: const Text(
                'Exit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    return shouldExit ?? false;
  }

  // ===================================================
  // DATE PICKER
  // ===================================================

  Future<void> selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void previousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(
        const Duration(days: 1),
      );
    });
  }

  void nextDay() {
    setState(() {
      selectedDate = selectedDate.add(
        const Duration(days: 1),
      );
    });
  }

  void goToToday() {
    setState(() {
      selectedDate = DateTime.now();
    });
  }

  // ===================================================
  // OPEN GROUP ROSTER
  // ===================================================

  void openGroupRoster(String group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupRosterScreen(
          group: group,
        ),
      ),
    );
  }

  // ===================================================
  // OPEN EMERGENCY ROSTER
  // ===================================================

  void openEmergencyRoster() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const EmergencyRosterScreen(),
      ),
    );
  }

  // ===================================================
  // OPEN MONTHLY ROSTER
  // ===================================================

  void openMonthlyRoster() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const MonthlyRosterScreen(),
      ),
    );
  }

  // ===================================================
  // OPEN EXCEL ROSTER
  // ===================================================

  void openExcelRoster() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ExcelRosterScreen(),
      ),
    );
  }

  // ===================================================
  // BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {
    final dayGroup =
        RosterService.getDayGroup(selectedDate) ?? '-';

    final nightGroup =
        RosterService.getNightGroup(selectedDate) ?? '-';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }

        final shouldExit =
            await showExitConfirmation();

        if (!mounted || !shouldExit) {
          return;
        }

        SystemNavigator.pop(animated: true);
      },

      child: Scaffold(
        backgroundColor: backgroundColor,

        appBar: AppBar(
          elevation: 0,
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'Operation Duty Roster',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // =========================================
                // PAGE TITLE
                // =========================================

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isToday
                            ? "Today's Duty"
                            : 'Selected Date Duty',
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    if (isToday)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFE3F2FD),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            color: primaryBlue,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // =========================================
                // DATE SELECTOR
                // =========================================

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(
                          alpha: 0.05,
                        ),
                        blurRadius: 12,
                        offset:
                            const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      IconButton(
                        onPressed: previousDay,
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          size: 32,
                        ),
                      ),

                      Expanded(
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(14),
                          onTap: selectDate,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              vertical: 17,
                              horizontal: 6,
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons
                                      .calendar_month_rounded,
                                  color: primaryBlue,
                                  size: 23,
                                ),

                                const SizedBox(width: 9),

                                Flexible(
                                  child: Text(
                                    formatDate(
                                      selectedDate,
                                    ),
                                    textAlign:
                                        TextAlign.center,
                                    style:
                                        const TextStyle(
                                      fontSize: 17,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: nextDay,
                        icon: const Icon(
                          Icons.chevron_right_rounded,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),

                if (!isToday) ...[
                  const SizedBox(height: 7),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: goToToday,
                      icon: const Icon(
                        Icons.today_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Back to Today',
                        style: TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                // =========================================
                // DAY DUTY
                // =========================================

                dutyCard(
                  icon: Icons.wb_sunny_rounded,
                  title: 'DAY DUTY',
                  time: '8:00 AM - 8:00 PM',
                  group: dayGroup,
                  label: '12 HOURS',
                ),

                const SizedBox(height: 14),

                // =========================================
                // NIGHT DUTY
                // =========================================

                dutyCard(
                  icon: Icons.nightlight_round,
                  title: 'NIGHT DUTY',
                  time: '8:00 PM - 8:00 AM',
                  group: nightGroup,
                  label: '12 HOURS',
                ),

                const SizedBox(height: 30),

                // =========================================
                // GROUP STATUS TITLE
                // =========================================

                const Row(
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      color: primaryBlue,
                      size: 25,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Group Status',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                const Text(
                  'Tap any group to view its full roster',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 15),

                groupStatusCard(
                  'G-A',
                  selectedDate,
                ),

                const SizedBox(height: 10),

                groupStatusCard(
                  'G-B',
                  selectedDate,
                ),

                const SizedBox(height: 10),

                groupStatusCard(
                  'G-C',
                  selectedDate,
                ),

                const SizedBox(height: 10),

                groupStatusCard(
                  'G-D',
                  selectedDate,
                ),

                const SizedBox(height: 30),

                // =========================================
                // EMERGENCY ROSTER BUTTON
                // =========================================

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: OutlinedButton.icon(
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor: primaryBlue,
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                        color: primaryBlue,
                        width: 1.5,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    onPressed:
                        openEmergencyRoster,
                    icon: const Icon(
                      Icons.emergency_rounded,
                      size: 23,
                    ),
                    label: const Text(
                      'Emergency Roster',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // =========================================
                // MONTHLY ROSTER BUTTON
                // =========================================

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton.icon(
                    style:
                        FilledButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    onPressed:
                        openMonthlyRoster,
                    icon: const Icon(
                      Icons
                          .calendar_view_month_rounded,
                      size: 23,
                    ),
                    label: const Text(
                      'View Monthly Roster',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // =========================================
                // EXCEL DUTY ROSTER BUTTON
                // =========================================

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: OutlinedButton.icon(
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor: primaryBlue,
                      backgroundColor: Colors.white,
                      side: const BorderSide(
                        color: primaryBlue,
                        width: 1.5,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),
                    onPressed:
                        openExcelRoster,
                    icon: const Icon(
                      Icons.table_chart_rounded,
                      size: 23,
                    ),
                    label: const Text(
                      'Excel Duty Roster',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================================================
  // DUTY CARD
  // ===================================================

  Widget dutyCard({
    required IconData icon,
    required String title,
    required String time,
    required String group,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.055,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,

            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius:
                  BorderRadius.circular(16),
            ),

            child: Icon(
              icon,
              size: 31,
              color: primaryBlue,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  label,
                  style: const TextStyle(
                    color: primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),

            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: Text(
              group,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================
  // GROUP STATUS CARD
  // ===================================================

  Widget groupStatusCard(
    String group,
    DateTime date,
  ) {
    final status =
        RosterService.getStatus(group, date);

    final detailedStatus =
        RosterService.getDetailedStatus(
      group,
      date,
    );

    IconData icon;
    String shortStatus;

    switch (status) {
      case 'D':
        icon = Icons.wb_sunny_rounded;
        shortStatus = 'DAY';
        break;

      case 'N':
        icon = Icons.nightlight_round;
        shortStatus = 'NIGHT';
        break;

      case 'SR':
        icon = Icons.beach_access_rounded;
        shortStatus = 'SR';
        break;

      default:
        icon = Icons.hotel_rounded;
        shortStatus = 'REST';
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),

        onTap: () {
          openGroupRoster(group);
        },

        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 14,
          ),

          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor:
                    const Color(0xFFE3F2FD),

                child: Text(
                  group.replaceFirst('G-', ''),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      group,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      detailedStatus,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF3F6FA),
                  borderRadius:
                      BorderRadius.circular(10),
                ),

                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 17,
                      color: primaryBlue,
                    ),

                    const SizedBox(width: 5),

                    Text(
                      shortStatus,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}