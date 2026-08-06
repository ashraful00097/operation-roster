import 'package:flutter/material.dart';

import '../models/emergency_roster.dart';
import '../services/emergency_roster_service.dart';
import '../services/roster_service.dart';

class AddEmergencyRosterScreen extends StatefulWidget {
  const AddEmergencyRosterScreen({super.key});

  @override
  State<AddEmergencyRosterScreen> createState() =>
      _AddEmergencyRosterScreenState();
}

class _AddEmergencyRosterScreenState
    extends State<AddEmergencyRosterScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  final List<String> groups = [
    'G-A',
    'G-B',
    'G-C',
    'G-D',
  ];

  final Map<String, String?> dayGroups = {};
  final Map<String, String?> nightGroups = {};

  bool saving = false;

  // ===============================================
  // DATE KEY
  // ===============================================

  String dateKey(DateTime date) {
    return EmergencyRosterService.dateKey(date);
  }

  // ===============================================
  // FORMAT DATE
  // ===============================================

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
        '${months[date.month - 1]} ${date.year}';
  }

  // ===============================================
  // SELECT START DATE
  // ===============================================

  Future<void> selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() {
      startDate = picked;

      if (endDate != null &&
          endDate!.isBefore(picked)) {
        endDate = null;
      }

      _resetDutySelections();
    });
  }

  // ===============================================
  // SELECT END DATE
  // ===============================================

  Future<void> selectEndDate() async {
    if (startDate == null) {
      showMessage(
        'Please select Start Date first.',
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate!,
      firstDate: startDate!,
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    setState(() {
      endDate = picked;
      _resetDutySelections();
    });
  }

  // ===============================================
  // RESET DUTIES WHEN DATE RANGE CHANGES
  // ===============================================

  void _resetDutySelections() {
    dayGroups.clear();
    nightGroups.clear();

    if (startDate == null || endDate == null) {
      return;
    }

    DateTime current = startDate!;

    while (!current.isAfter(endDate!)) {
      final key = dateKey(current);

      dayGroups[key] = null;
      nightGroups[key] = null;

      current = current.add(
        const Duration(days: 1),
      );
    }
  }

  // ===============================================
  // DATE LIST
  // ===============================================

  List<DateTime> get emergencyDates {
    if (startDate == null || endDate == null) {
      return [];
    }

    final dates = <DateTime>[];

    DateTime current = startDate!;

    while (!current.isAfter(endDate!)) {
      dates.add(current);

      current = current.add(
        const Duration(days: 1),
      );
    }

    return dates;
  }

  // ===============================================
  // REST GROUPS
  // ===============================================

  String getRestGroups(DateTime date) {
    final key = dateKey(date);

    final day = dayGroups[key];
    final night = nightGroups[key];

    final rest = groups.where((group) {
      return group != day && group != night;
    }).toList();

    if (day == null || night == null) {
      return '-';
    }

    return rest.join(', ');
  }

  // ===============================================
  // SAVE
  // ===============================================

  Future<void> saveEmergencyRoster() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      showMessage(
        'Please enter Emergency Roster name.',
      );
      return;
    }

    if (startDate == null || endDate == null) {
      showMessage(
        'Please select Start Date and End Date.',
      );
      return;
    }

    final duties =
        <String, Map<String, String>>{};

    for (final date in emergencyDates) {
      final key = dateKey(date);

      final day = dayGroups[key];
      final night = nightGroups[key];

      if (day == null || night == null) {
        showMessage(
          'Please select Day and Night duty for ${formatDate(date)}.',
        );
        return;
      }

      if (day == night) {
        showMessage(
          'Day and Night group cannot be the same on ${formatDate(date)}.',
        );
        return;
      }

      duties[key] = {
        'day': day,
        'night': night,
      };
    }

    setState(() {
      saving = true;
    });

    final roster = EmergencyRoster(
      id: DateTime.now()
          .microsecondsSinceEpoch
          .toString(),
      name: name,
      startDate: startDate!,
      endDate: endDate!,
      duties: duties,
    );

    await EmergencyRosterService.add(
      roster,
    );

    await RosterService.reloadEmergencyRosters();

    if (!mounted) return;

    setState(() {
      saving = false;
    });

    Navigator.pop(
      context,
      true,
    );
  }

  // ===============================================
  // MESSAGE
  // ===============================================

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ===============================================
  // BUILD
  // ===============================================

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
          'Add Emergency Roster',
          style: TextStyle(
            fontWeight: FontWeight.bold,
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
              // =====================================
              // EMERGENCY NAME
              // =====================================

              const Text(
                'Emergency Name',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _nameController,

                decoration: InputDecoration(
                  hintText:
                      'Example: Eid Duty',

                  prefixIcon: const Icon(
                    Icons.warning_amber_rounded,
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // =====================================
              // START / END DATE
              // =====================================

              const Text(
                'Emergency Period',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: dateButton(
                      title: 'Start Date',
                      date: startDate,
                      onTap: selectStartDate,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: dateButton(
                      title: 'End Date',
                      date: endDate,
                      onTap: selectEndDate,
                    ),
                  ),
                ],
              ),

              if (emergencyDates.isNotEmpty) ...[
                const SizedBox(height: 28),

                const Text(
                  'Duty Assignment',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Select one Day group and one Night group for each date. The other two groups will automatically be Rest.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 15),

                ...emergencyDates.map(
                  (date) => dutyAssignmentCard(
                    date,
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 56,

                  child: FilledButton.icon(
                    onPressed:
                        saving
                            ? null
                            : saveEmergencyRoster,

                    style: FilledButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF1565C0,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),

                    icon: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.save_rounded,
                          ),

                    label: Text(
                      saving
                          ? 'Saving...'
                          : 'Save Emergency Roster',

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================
  // DATE BUTTON
  // ===============================================

  Widget dateButton({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),

        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 15,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 5),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF1565C0),
                    size: 20,
                  ),

                  const SizedBox(width: 7),

                  Expanded(
                    child: Text(
                      date == null
                          ? 'Select'
                          : formatDate(date),

                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================
  // DUTY ASSIGNMENT CARD
  // ===============================================

  Widget dutyAssignmentCard(
    DateTime date,
  ) {
    final key = dateKey(date);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            formatDate(date),

            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              // DAY
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: dayGroups[key],

                  decoration: InputDecoration(
                    labelText: 'Day',
                    prefixIcon: const Icon(
                      Icons.wb_sunny_rounded,
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  items: groups
                      .map(
                        (group) =>
                            DropdownMenuItem(
                          value: group,
                          child: Text(group),
                        ),
                      )
                      .toList(),

                  onChanged: (value) {
                    setState(() {
                      dayGroups[key] = value;

                      if (nightGroups[key] ==
                          value) {
                        nightGroups[key] = null;
                      }
                    });
                  },
                ),
              ),

              const SizedBox(width: 10),

              // NIGHT
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue:
                      nightGroups[key],

                  decoration: InputDecoration(
                    labelText: 'Night',
                    prefixIcon: const Icon(
                      Icons.nightlight_round,
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),

                  items: groups
                      .where(
                        (group) =>
                            group !=
                            dayGroups[key],
                      )
                      .map(
                        (group) =>
                            DropdownMenuItem(
                          value: group,
                          child: Text(group),
                        ),
                      )
                      .toList(),

                  onChanged: (value) {
                    setState(() {
                      nightGroups[key] = value;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,

            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),

            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F9),
              borderRadius: BorderRadius.circular(10),
            ),

            child: Row(
              children: [
                const Icon(
                  Icons.hotel_rounded,
                  size: 18,
                  color: Colors.grey,
                ),

                const SizedBox(width: 8),

                const Text(
                  'Rest: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Expanded(
                  child: Text(
                    getRestGroups(date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}