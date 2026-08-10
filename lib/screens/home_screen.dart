import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/roster_service.dart';
import 'emergency_roster_screen.dart';
import 'excel_roster_screen.dart';
import 'group_roster_screen.dart';
import 'interchange_requests_screen.dart';
import 'interchange_screen.dart';
import 'monthly_roster_screen.dart';
import 'profile_setup_screen.dart';

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
  // LOGOUT CONFIRMATION
  // ===================================================

  Future<void> logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.logout_rounded,
            color: primaryBlue,
            size: 36,
          ),
          title: const Text(
            'Logout?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Do you want to logout from this account?',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancel',
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
                Icons.logout_rounded,
                size: 18,
              ),
              label: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await FirebaseAuth.instance.signOut();
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
  // OPEN INTERCHANGE
  // ===================================================

  void openInterchange() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const InterchangeScreen(),
      ),
    );
  }

  // ===================================================
  // OPEN INTERCHANGE REQUESTS
  // ===================================================

  void openInterchangeRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const InterchangeRequestsScreen(),
      ),
    );
  }

  // ===================================================
  // OPEN PROFILE
  // ===================================================

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ProfileSetupScreen(),
      ),
    );
  }

  // ===================================================
  // PROFILE HEADER
  // ===================================================

  Widget profileHeader(
    Map<String, dynamic>? data,
  ) {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    final name =
        (data?['name'] ?? '').toString().trim();

    final group =
        (data?['group'] ?? '').toString().trim();

    final dutyType =
        (data?['dutyType'] ?? 'shift')
            .toString()
            .trim()
            .toLowerCase();

    final displayName =
        name.isNotEmpty
            ? name
            : (currentUser?.email ?? 'User');

    final isRegular =
        dutyType == 'regular';

    final displayGroup =
        isRegular
            ? 'Regular'
            : (group.isNotEmpty
                ? 'Group $group'
                : 'Group -');

    final firstLetter =
        displayName.isNotEmpty
            ? displayName[0].toUpperCase()
            : 'U';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          18,
          10,
          18,
          16,
        ),
        child: Row(
          children: [
            // =========================================
            // PROFILE AVATAR
            // =========================================

            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE3F2FD),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.10,
                    ),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  firstLetter,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            // =========================================
            // NAME + DUTY TYPE
            // =========================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Row(
                    children: [
                      Icon(
                        isRegular
                            ? Icons
                                .person_outline_rounded
                            : Icons
                                .groups_rounded,
                        size: 17,
                        color: primaryBlue,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Flexible(
                        child: Text(
                          displayGroup,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w600,
                            color:
                                primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // =========================================
            // PROFILE BUTTON
            // =========================================

            FilledButton.icon(
              onPressed: openProfile,
              icon: const Icon(
                Icons.person_rounded,
                size: 16,
              ),
              label: const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFFE3F2FD),
                foregroundColor:
                    primaryBlue,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {
    final dayGroup =
        RosterService.getDayGroup(
              selectedDate,
            ) ??
            '-';

    final nightGroup =
        RosterService.getNightGroup(
              selectedDate,
            ) ??
            '-';

    final currentUser =
        FirebaseAuth.instance.currentUser;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult:
          (didPop, result) async {
        if (didPop) {
          return;
        }

        final shouldExit =
            await showExitConfirmation();

        if (!mounted || !shouldExit) {
          return;
        }

        SystemNavigator.pop(
          animated: true,
        );
      },
      child: Scaffold(
        backgroundColor:
            backgroundColor,

        // =================================================
        // APP BAR
        // =================================================

        appBar: AppBar(
          elevation: 0,
          backgroundColor:
              primaryBlue,
          foregroundColor:
              Colors.white,
          centerTitle: true,

          title: const Text(
            'Operation Duty Roster',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontSize: 20,
            ),
          ),

          actions: [
            // =============================================
            // NOTIFICATION
            // =============================================

            if (currentUser != null)
              StreamBuilder<
                  QuerySnapshot<
                      Map<String, dynamic>>>(
                stream:
                    FirebaseFirestore
                        .instance
                        .collection(
                          'interchange_requests',
                        )
                        .where(
                          'toUserId',
                          isEqualTo:
                              currentUser.uid,
                        )
                        .where(
                          'status',
                          isEqualTo:
                              'pending',
                        )
                        .snapshots(),

                builder: (
                  context,
                  snapshot,
                ) {
                  final count =
                      snapshot.data
                              ?.docs.length ??
                          0;

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      right: 2,
                    ),
                    child: Stack(
                      clipBehavior:
                          Clip.none,
                      children: [
                        IconButton(
                          tooltip:
                              'Interchange Requests',
                          onPressed:
                              openInterchangeRequests,
                          icon:
                              const Icon(
                            Icons
                                .notifications_rounded,
                            size: 27,
                          ),
                        ),

                        if (count > 0)
                          Positioned(
                            right: 2,
                            top: 5,
                            child:
                                Container(
                              constraints:
                                  const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 4,
                              ),
                              decoration:
                                  BoxDecoration(
                                color:
                                    Colors.red,
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),
                                border:
                                    Border.all(
                                  color:
                                      primaryBlue,
                                  width:
                                      1.5,
                                ),
                              ),
                              child:
                                  Text(
                                count > 99
                                    ? '99+'
                                    : count
                                        .toString(),
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    const TextStyle(
                                  color:
                                      Colors.white,
                                  fontSize:
                                      10,
                                  fontWeight:
                                      FontWeight
                                          .bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

            // =============================================
            // LOGOUT
            // =============================================

            IconButton(
              tooltip:
                  'Logout',
              onPressed:
                  logout,
              icon:
                  const Icon(
                Icons.logout_rounded,
                size: 25,
              ),
            ),

            const SizedBox(
              width: 4,
            ),
          ],
        ),

        // =================================================
        // BODY
        // =================================================

        body: SafeArea(
          child:
              currentUser == null
                  ? const Center(
                      child:
                          CircularProgressIndicator(),
                    )
                  : StreamBuilder<
                      DocumentSnapshot<
                          Map<String, dynamic>>>(
                      stream:
                          FirebaseFirestore
                              .instance
                              .collection(
                                'users',
                              )
                              .doc(
                                currentUser.uid,
                              )
                              .snapshots(),

                      builder: (
                        context,
                        profileSnapshot,
                      ) {
                        final profileData =
                            profileSnapshot
                                .data
                                ?.data();

                        final dutyType =
                            (profileData?[
                                        'dutyType'] ??
                                    'shift')
                                .toString()
                                .trim()
                                .toLowerCase();

                        final isRegular =
                            dutyType ==
                                'regular';

                        return SingleChildScrollView(
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            16,
                            0,
                            16,
                            16,
                          ),

                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,

                            children: [
                              // =================================
                              // PROFILE HEADER
                              // =================================

                              profileHeader(
                                profileData,
                              ),

                              const SizedBox(
                                height: 20,
                              ),

                              // =================================
                              // PAGE TITLE
                              // =================================

                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        Text(
                                      isToday
                                          ? "Today's Duty"
                                          : 'Selected Date Duty',
                                      style:
                                          const TextStyle(
                                        fontSize:
                                            27,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                        letterSpacing:
                                            -0.5,
                                      ),
                                    ),
                                  ),

                                  if (isToday)
                                    Container(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal:
                                            10,
                                        vertical:
                                            6,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            const Color(
                                          0xFFE3F2FD,
                                        ),
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          20,
                                        ),
                                      ),
                                      child:
                                          const Text(
                                        'TODAY',
                                        style:
                                            TextStyle(
                                          color:
                                              primaryBlue,
                                          fontSize:
                                              11,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(
                                height: 16,
                              ),

                              // =================================
                              // DATE SELECTOR
                              // =================================

                              Container(
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.white,
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    18,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors
                                          .black
                                          .withValues(
                                        alpha:
                                            0.05,
                                      ),
                                      blurRadius:
                                          12,
                                      offset:
                                          const Offset(
                                        0,
                                        4,
                                      ),
                                    ),
                                  ],
                                ),
                                child:
                                    Row(
                                  children: [
                                    IconButton(
                                      onPressed:
                                          previousDay,
                                      icon:
                                          const Icon(
                                        Icons
                                            .chevron_left_rounded,
                                        size:
                                            32,
                                      ),
                                    ),

                                    Expanded(
                                      child:
                                          InkWell(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          14,
                                        ),
                                        onTap:
                                            selectDate,
                                        child:
                                            Padding(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                            vertical:
                                                17,
                                            horizontal:
                                                6,
                                          ),
                                          child:
                                              Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .center,
                                            children: [
                                              const Icon(
                                                Icons
                                                    .calendar_month_rounded,
                                                color:
                                                    primaryBlue,
                                                size:
                                                    23,
                                              ),
                                              const SizedBox(
                                                width:
                                                    9,
                                              ),
                                              Flexible(
                                                child:
                                                    Text(
                                                  formatDate(
                                                    selectedDate,
                                                  ),
                                                  textAlign:
                                                      TextAlign
                                                          .center,
                                                  style:
                                                      const TextStyle(
                                                    fontSize:
                                                        17,
                                                    fontWeight:
                                                        FontWeight
                                                            .bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    IconButton(
                                      onPressed:
                                          nextDay,
                                      icon:
                                          const Icon(
                                        Icons
                                            .chevron_right_rounded,
                                        size:
                                            32,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (!isToday) ...[
                                const SizedBox(
                                  height: 7,
                                ),
                                Align(
                                  alignment:
                                      Alignment
                                          .centerRight,
                                  child:
                                      TextButton.icon(
                                    onPressed:
                                        goToToday,
                                    icon:
                                        const Icon(
                                      Icons
                                          .today_rounded,
                                      size:
                                          18,
                                    ),
                                    label:
                                        const Text(
                                      'Back to Today',
                                      style:
                                          TextStyle(
                                        fontWeight:
                                            FontWeight
                                                .w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(
                                height: 18,
                              ),

                              // =================================
                              // DAY DUTY
                              // =================================

                              dutyCard(
                                icon:
                                    Icons
                                        .wb_sunny_rounded,
                                title:
                                    'DAY DUTY',
                                time:
                                    '8:00 AM - 8:00 PM',
                                group:
                                    dayGroup,
                                label:
                                    '12 HOURS',
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              // =================================
                              // NIGHT DUTY
                              // =================================

                              dutyCard(
                                icon:
                                    Icons
                                        .nightlight_round,
                                title:
                                    'NIGHT DUTY',
                                time:
                                    '8:00 PM - 8:00 AM',
                                group:
                                    nightGroup,
                                label:
                                    '12 HOURS',
                              ),

                              const SizedBox(
                                height: 30,
                              ),

                              // =================================
                              // GROUP STATUS
                              // =================================

                              const Row(
                                children: [
                                  Icon(
                                    Icons
                                        .groups_rounded,
                                    color:
                                        primaryBlue,
                                    size:
                                        25,
                                  ),
                                  SizedBox(
                                    width:
                                        8,
                                  ),
                                  Text(
                                    'Group Status',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          22,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              const Text(
                                'Tap any group to view its full roster',
                                style:
                                    TextStyle(
                                  fontSize:
                                      13,
                                  color:
                                      Colors.grey,
                                ),
                              ),

                              const SizedBox(
                                height: 15,
                              ),

                              groupStatusCard(
                                'G-A',
                                selectedDate,
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              groupStatusCard(
                                'G-B',
                                selectedDate,
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              groupStatusCard(
                                'G-C',
                                selectedDate,
                              ),

                              const SizedBox(
                                height: 10,
                              ),

                              groupStatusCard(
                                'G-D',
                                selectedDate,
                              ),

                              const SizedBox(
                                height: 30,
                              ),

                              // =================================
                              // EMERGENCY ROSTER
                              // =================================

                              SizedBox(
                                width:
                                    double.infinity,
                                height:
                                    58,
                                child:
                                    OutlinedButton
                                        .icon(
                                  style:
                                      OutlinedButton
                                          .styleFrom(
                                    foregroundColor:
                                        primaryBlue,
                                    backgroundColor:
                                        Colors.white,
                                    side:
                                        const BorderSide(
                                      color:
                                          primaryBlue,
                                      width:
                                          1.5,
                                    ),
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        16,
                                      ),
                                    ),
                                  ),
                                  onPressed:
                                      openEmergencyRoster,
                                  icon:
                                      const Icon(
                                    Icons
                                        .emergency_rounded,
                                    size:
                                        23,
                                  ),
                                  label:
                                      const Text(
                                    'Emergency Roster',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          17,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              // =================================
                              // MONTHLY ROSTER
                              // =================================

                              SizedBox(
                                width:
                                    double.infinity,
                                height:
                                    58,
                                child:
                                    FilledButton
                                        .icon(
                                  style:
                                      FilledButton
                                          .styleFrom(
                                    backgroundColor:
                                        primaryBlue,
                                    foregroundColor:
                                        Colors.white,
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        16,
                                      ),
                                    ),
                                  ),
                                  onPressed:
                                      openMonthlyRoster,
                                  icon:
                                      const Icon(
                                    Icons
                                        .calendar_view_month_rounded,
                                    size:
                                        23,
                                  ),
                                  label:
                                      const Text(
                                    'View Monthly Roster',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          17,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              // =================================
                              // EXCEL DUTY ROSTER
                              // =================================

                              SizedBox(
                                width:
                                    double.infinity,
                                height:
                                    58,
                                child:
                                    OutlinedButton
                                        .icon(
                                  style:
                                      OutlinedButton
                                          .styleFrom(
                                    foregroundColor:
                                        primaryBlue,
                                    backgroundColor:
                                        Colors.white,
                                    side:
                                        const BorderSide(
                                      color:
                                          primaryBlue,
                                      width:
                                          1.5,
                                    ),
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        16,
                                      ),
                                    ),
                                  ),
                                  onPressed:
                                      openExcelRoster,
                                  icon:
                                      const Icon(
                                    Icons
                                        .table_chart_rounded,
                                    size:
                                        23,
                                  ),
                                  label:
                                      const Text(
                                    'Excel Duty Roster',
                                    style:
                                        TextStyle(
                                      fontSize:
                                          17,
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                ),
                              ),

                              // =================================
                              // PERSON INTERCHANGE
                              // SHIFT USER ONLY
                              // =================================

                              if (!isRegular) ...[
                                const SizedBox(
                                  height: 12,
                                ),

                                SizedBox(
                                  width:
                                      double.infinity,
                                  height:
                                      58,
                                  child:
                                      OutlinedButton
                                          .icon(
                                    style:
                                        OutlinedButton
                                            .styleFrom(
                                      foregroundColor:
                                          primaryBlue,
                                      backgroundColor:
                                          Colors.white,
                                      side:
                                          const BorderSide(
                                        color:
                                            primaryBlue,
                                        width:
                                            1.5,
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          16,
                                        ),
                                      ),
                                    ),
                                    onPressed:
                                        openInterchange,
                                    icon:
                                        const Icon(
                                      Icons
                                          .swap_horiz_rounded,
                                      size:
                                          23,
                                    ),
                                    label:
                                        const Text(
                                      'Person Interchange',
                                      style:
                                          TextStyle(
                                        fontSize:
                                            17,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(
                                height: 25,
                              ),
                            ],
                          ),
                        );
                      },
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
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(19),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.055,
            ),
            blurRadius: 14,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFE3F2FD),
              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),
            child: Icon(
              icon,
              size: 31,
              color: primaryBlue,
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  time,
                  style:
                      const TextStyle(
                    color:
                        Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  label,
                  style:
                      const TextStyle(
                    color:
                        primaryBlue,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFE3F2FD),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child:
                Text(
              group,
              style:
                  const TextStyle(
                fontSize: 23,
                fontWeight:
                    FontWeight.bold,
                color:
                    primaryBlue,
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
        RosterService.getStatus(
      group,
      date,
    );

    final detailedStatus =
        RosterService.getDetailedStatus(
      group,
      date,
    );

    IconData icon;
    String shortStatus;

    switch (status) {
      case 'D':
        icon =
            Icons.wb_sunny_rounded;
        shortStatus =
            'DAY';
        break;

      case 'N':
        icon =
            Icons.nightlight_round;
        shortStatus =
            'NIGHT';
        break;

      case 'SR':
        icon =
            Icons.beach_access_rounded;
        shortStatus =
            'SR';
        break;

      default:
        icon =
            Icons.hotel_rounded;
        shortStatus =
            'REST';
    }

    return Material(
      color:
          Colors.white,
      borderRadius:
          BorderRadius.circular(
        16,
      ),
      child:
          InkWell(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        onTap: () {
          openGroupRoster(
            group,
          );
        },
        child:
            Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 15,
            vertical: 14,
          ),
          child:
              Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor:
                    const Color(
                  0xFFE3F2FD,
                ),
                child:
                    Text(
                  group.replaceFirst(
                    'G-',
                    '',
                  ),
                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        primaryBlue,
                  ),
                ),
              ),

              const SizedBox(
                width: 13,
              ),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      group,
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      detailedStatus,
                      style:
                          const TextStyle(
                        fontSize: 13,
                        color:
                            Colors.grey,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF3F6FA,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
                child:
                    Row(
                  children: [
                    Icon(
                      icon,
                      size: 17,
                      color:
                          primaryBlue,
                    ),

                    const SizedBox(
                      width: 5,
                    ),

                    Text(
                      shortStatus,
                      style:
                          const TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 5,
              ),

              const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}