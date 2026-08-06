import 'package:flutter/material.dart';

import '../models/emergency_roster.dart';
import '../services/emergency_roster_service.dart';
import '../services/roster_service.dart';
import 'add_emergency_roster_screen.dart';

class EmergencyRosterScreen extends StatefulWidget {
  const EmergencyRosterScreen({super.key});

  @override
  State<EmergencyRosterScreen> createState() =>
      _EmergencyRosterScreenState();
}

class _EmergencyRosterScreenState
    extends State<EmergencyRosterScreen> {
  List<EmergencyRoster> rosters = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRosters();
  }

  // ===================================================
  // DATE HELPERS
  // ===================================================

  DateTime cleanDate(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  bool isCompleted(EmergencyRoster roster) {
    final today = cleanDate(DateTime.now());
    final endDate = cleanDate(roster.endDate);

    // Completed only AFTER the End Date has passed.
    return today.isAfter(endDate);
  }

  bool isActive(EmergencyRoster roster) {
    final today = cleanDate(DateTime.now());

    final startDate =
        cleanDate(roster.startDate);

    final endDate =
        cleanDate(roster.endDate);

    return !today.isBefore(startDate) &&
        !today.isAfter(endDate);
  }

  bool isUpcoming(EmergencyRoster roster) {
    final today = cleanDate(DateTime.now());

    final startDate =
        cleanDate(roster.startDate);

    return today.isBefore(startDate);
  }

  // ===================================================
  // LOAD ROSTERS
  // ===================================================

  Future<void> loadRosters() async {
    try {
      final savedRosters =
          await EmergencyRosterService.getAll();

      savedRosters.sort(
        (a, b) =>
            b.startDate.compareTo(a.startDate),
      );

      if (!mounted) return;

      setState(() {
        rosters = savedRosters;
        loading = false;
      });
    } catch (e) {
      debugPrint(
        'Emergency roster load error: $e',
      );

      if (!mounted) return;

      setState(() {
        rosters = [];
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Emergency roster load failed: $e',
          ),
        ),
      );
    }
  }

  // ===================================================
  // ADD EMERGENCY
  // ===================================================

  Future<void> addEmergencyRoster() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddEmergencyRosterScreen(),
      ),
    );

    if (result == true) {
      await RosterService.reloadEmergencyRosters();
      await loadRosters();
    }
  }

  // ===================================================
  // DELETE
  // ===================================================

  Future<void> confirmDelete(
    EmergencyRoster roster,
  ) async {
    // Extra protection:
    // completed emergency can NEVER be deleted.
    if (isCompleted(roster)) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completed emergency roster is locked and cannot be deleted.',
          ),
        ),
      );

      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 34,
          ),

          title: const Text(
            'Delete Emergency Roster?',
          ),

          content: Text(
            'Are you sure you want to delete '
            '"${roster.name}"?\n\n'
            'The normal roster will automatically '
            'recalculate after this emergency is removed.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },

              icon: const Icon(
                Icons.delete_outline_rounded,
              ),

              label: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await EmergencyRosterService.delete(
      roster.id,
    );

    // VERY IMPORTANT:
    // refresh emergency data used by normal roster.
    await RosterService.reloadEmergencyRosters();

    await loadRosters();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${roster.name} deleted successfully.',
        ),
      ),
    );
  }

  // ===================================================
  // DATE FORMAT
  // ===================================================

  String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} '
        '${date.year}';
  }

  // ===================================================
  // NUMBER OF DAYS
  // ===================================================

  int emergencyDays(
    EmergencyRoster roster,
  ) {
    final start =
        cleanDate(roster.startDate);

    final end =
        cleanDate(roster.endDate);

    return end.difference(start).inDays + 1;
  }

  // ===================================================
  // BUILD
  // ===================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F6F9),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF1565C0),
        foregroundColor: Colors.white,

        title: const Text(
          'Emergency Roster',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addEmergencyRoster,

        backgroundColor:
            const Color(0xFF1565C0),

        foregroundColor: Colors.white,

        icon: const Icon(
          Icons.add_rounded,
        ),

        label: const Text(
          'Add Emergency',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : rosters.isEmpty
              ? emptyState()
              : rosterList(),
    );
  }

  // ===================================================
  // EMPTY STATE
  // ===================================================

  Widget emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 90,
              height: 90,

              decoration:
                  const BoxDecoration(
                color: Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.event_busy_rounded,
                size: 44,
                color: Color(0xFF1565C0),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No Emergency Roster',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Add an emergency roster when the '
              'normal duty cycle needs to be paused.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: addEmergencyRoster,

              icon: const Icon(
                Icons.add_rounded,
              ),

              label: const Text(
                'Add Emergency Roster',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================================================
  // ROSTER LIST
  // ===================================================

  Widget rosterList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        14,
        16,
        14,
        100,
      ),

      itemCount: rosters.length,

      separatorBuilder:
          (context, index) =>
              const SizedBox(height: 12),

      itemBuilder:
          (context, index) {
        final roster =
            rosters[index];

        return emergencyCard(
          roster,
        );
      },
    );
  }

  // ===================================================
  // EMERGENCY CARD
  // ===================================================

  Widget emergencyCard(
    EmergencyRoster roster,
  ) {
    final days =
        emergencyDays(roster);

    final completed =
        isCompleted(roster);

    final active =
        isActive(roster);

    final upcoming =
        isUpcoming(roster);

    String statusText;
    IconData statusIcon;
    Color statusColor;
    Color statusBackground;

    if (completed) {
      statusText = 'COMPLETED • LOCKED';
      statusIcon = Icons.lock_rounded;
      statusColor = Colors.grey.shade700;
      statusBackground =
          Colors.grey.shade200;
    } else if (active) {
      statusText = 'ACTIVE';
      statusIcon =
          Icons.emergency_rounded;
      statusColor = Colors.red;
      statusBackground =
          const Color(0xFFFFEBEE);
    } else if (upcoming) {
      statusText = 'UPCOMING';
      statusIcon =
          Icons.schedule_rounded;
      statusColor =
          const Color(0xFF1565C0);
      statusBackground =
          const Color(0xFFE3F2FD);
    } else {
      statusText = 'SCHEDULED';
      statusIcon =
          Icons.event_rounded;
      statusColor =
          const Color(0xFF1565C0);
      statusBackground =
          const Color(0xFFE3F2FD);
    }

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border: active
            ? Border.all(
                color: Colors.red
                    .withValues(
                  alpha: 0.35,
                ),
                width: 1.5,
              )
            : null,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 12,
            offset: const Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // =========================================
          // NAME + DELETE/LOCK
          // =========================================

          Row(
            children: [
              Container(
                width: 46,
                height: 46,

                decoration: BoxDecoration(
                  color: active
                      ? const Color(
                          0xFFFFEBEE,
                        )
                      : const Color(
                          0xFFFFF3E0,
                        ),

                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),

                child: Icon(
                  active
                      ? Icons.emergency_rounded
                      : Icons
                          .warning_amber_rounded,

                  color: active
                      ? Colors.red
                      : Colors.orange,

                  size: 27,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      roster.name,

                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      '$days '
                      '${days == 1 ? 'Day' : 'Days'}',

                      style:
                          const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // COMPLETED = LOCK
              if (completed)
                Container(
                  width: 42,
                  height: 42,

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    Icons.lock_rounded,
                    color:
                        Colors.grey.shade600,
                    size: 21,
                  ),
                )
              else
                IconButton(
                  tooltip:
                      'Delete Emergency',

                  onPressed: () {
                    confirmDelete(
                      roster,
                    );
                  },

                  icon: const Icon(
                    Icons
                        .delete_outline_rounded,
                    color: Colors.red,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // =========================================
          // STATUS
          // =========================================

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),

            decoration: BoxDecoration(
              color: statusBackground,

              borderRadius:
                  BorderRadius.circular(10),
            ),

            child: Row(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                Icon(
                  statusIcon,
                  size: 16,
                  color: statusColor,
                ),

                const SizedBox(width: 6),

                Text(
                  statusText,

                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // =========================================
          // DATE RANGE
          // =========================================

          Container(
            width: double.infinity,

            padding:
                const EdgeInsets.all(13),

            decoration: BoxDecoration(
              color:
                  const Color(0xFFF4F6F9),

              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: Row(
              children: [
                const Icon(
                  Icons
                      .calendar_month_rounded,
                  color:
                      Color(0xFF1565C0),
                  size: 21,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    '${formatDate(roster.startDate)}'
                    '  →  '
                    '${formatDate(roster.endDate)}',

                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // =========================================
          // INFO
          // =========================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Icon(
                completed
                    ? Icons.lock_outline_rounded
                    : Icons
                        .pause_circle_outline_rounded,

                size: 18,

                color: completed
                    ? Colors.grey.shade600
                    : const Color(
                        0xFF1565C0,
                      ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  completed
                      ? 'Completed roster is locked. These emergency days remain permanently excluded from the normal duty cycle.'
                      : 'Normal roster is paused during this emergency period.',

                  style: TextStyle(
                    fontSize: 12,
                    color: completed
                        ? Colors.grey.shade600
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}