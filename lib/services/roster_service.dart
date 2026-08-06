import '../models/emergency_roster.dart';
import 'emergency_roster_service.dart';

class RosterService {
  // ===================================================
  // NORMAL 16-DAY CYCLE
  // ===================================================
  //
  // D N R | D N R | D N R | D N R | SR SR SR SR
  //
  // D  = Day Duty
  // N  = Night Duty
  // R  = Normal Rest
  // SR = 4-day Schedule Rest

  static const List<String> cycle = [
    'D',
    'N',
    'R',
    'D',
    'N',
    'R',
    'D',
    'N',
    'R',
    'D',
    'N',
    'R',
    'SR',
    'SR',
    'SR',
    'SR',
  ];

  static final DateTime referenceDate =
      DateTime(2026, 8, 2);

  static const Map<String, int> referencePositions = {
    'G-A': 11,
    'G-B': 15,
    'G-C': 3,
    'G-D': 7,
  };

  // ===================================================
  // EMERGENCY ROSTERS IN MEMORY
  // ===================================================

  static List<EmergencyRoster> _emergencyRosters = [];

  static List<EmergencyRoster> get emergencyRosters =>
      List.unmodifiable(_emergencyRosters);

  // Call this when app starts and whenever an
  // emergency roster is added/deleted.
  static Future<void> reloadEmergencyRosters() async {
    final rosters =
        await EmergencyRosterService.getAll();

    rosters.sort(
      (a, b) => a.startDate.compareTo(b.startDate),
    );

    _emergencyRosters = rosters;
  }

  // ===================================================
  // DATE HELPERS
  // ===================================================

  static DateTime cleanDate(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  static bool sameDay(
    DateTime first,
    DateTime second,
  ) {
    final a = cleanDate(first);
    final b = cleanDate(second);

    return a == b;
  }

  static bool isDateInsideEmergency(
    DateTime date,
    EmergencyRoster roster,
  ) {
    final target = cleanDate(date);
    final start = cleanDate(roster.startDate);
    final end = cleanDate(roster.endDate);

    return !target.isBefore(start) &&
        !target.isAfter(end);
  }

  // ===================================================
  // FIND EMERGENCY ROSTER
  // ===================================================

  static EmergencyRoster? getEmergencyForDate(
    DateTime date,
  ) {
    for (final roster in _emergencyRosters) {
      if (isDateInsideEmergency(date, roster)) {
        return roster;
      }
    }

    return null;
  }

  static bool isEmergencyDate(DateTime date) {
    return getEmergencyForDate(date) != null;
  }

  static String? getEmergencyName(DateTime date) {
    return getEmergencyForDate(date)?.name;
  }

  // ===================================================
  // COUNT EMERGENCY DAYS
  // ===================================================
  //
  // Emergency dates DO NOT advance the normal cycle.
  //
  // Example:
  //
  // 10 Jun = normal cycle position
  // 11-14 Jun = emergency
  // 15 Jun = position that 11 Jun would have had
  //
  // So 4 emergency days are subtracted from the
  // calendar difference.
  // ===================================================

  static int _emergencyDaysBetween(
    DateTime from,
    DateTime to,
  ) {
    final start = cleanDate(from);
    final end = cleanDate(to);

    if (start == end) {
      return 0;
    }

    int count = 0;

    if (end.isAfter(start)) {
      DateTime current = start;

      while (current.isBefore(end)) {
        if (isEmergencyDate(current)) {
          count++;
        }

        current = current.add(
          const Duration(days: 1),
        );
      }

      return count;
    }

    DateTime current = end;

    while (current.isBefore(start)) {
      if (isEmergencyDate(current)) {
        count++;
      }

      current = current.add(
        const Duration(days: 1),
      );
    }

    return -count;
  }

  // ===================================================
  // NORMAL CYCLE POSITION
  // ===================================================

  static int getPosition(
    String group,
    DateTime date,
  ) {
    final target = cleanDate(date);
    final reference = cleanDate(referenceDate);

    final calendarDifference =
        target.difference(reference).inDays;

    final emergencyDays =
        _emergencyDaysBetween(
      reference,
      target,
    );

    final effectiveDifference =
        calendarDifference - emergencyDays;

    final startPosition =
        referencePositions[group]!;

    return ((startPosition +
                    effectiveDifference) %
                cycle.length +
            cycle.length) %
        cycle.length;
  }

  // ===================================================
  // EMERGENCY DUTY
  // ===================================================

  static String? getEmergencyDayGroup(
    DateTime date,
  ) {
    final roster =
        getEmergencyForDate(date);

    if (roster == null) {
      return null;
    }

    final key =
        EmergencyRosterService.dateKey(date);

    return roster.duties[key]?['day'];
  }

  static String? getEmergencyNightGroup(
    DateTime date,
  ) {
    final roster =
        getEmergencyForDate(date);

    if (roster == null) {
      return null;
    }

    final key =
        EmergencyRosterService.dateKey(date);

    return roster.duties[key]?['night'];
  }

  // ===================================================
  // STATUS
  // ===================================================

  static String getStatus(
    String group,
    DateTime date,
  ) {
    final emergency =
        getEmergencyForDate(date);

    if (emergency != null) {
      final key =
          EmergencyRosterService.dateKey(date);

      final duty =
          emergency.duties[key];

      if (duty != null) {
        if (duty['day'] == group) {
          return 'D';
        }

        if (duty['night'] == group) {
          return 'N';
        }
      }

      // During emergency:
      // remaining 2 groups are Rest.
      return 'R';
    }

    return cycle[getPosition(group, date)];
  }

  // ===================================================
  // DAY GROUP
  // ===================================================

  static String? getDayGroup(
    DateTime date,
  ) {
    if (isEmergencyDate(date)) {
      return getEmergencyDayGroup(date);
    }

    for (final group
        in referencePositions.keys) {
      if (getStatus(group, date) == 'D') {
        return group;
      }
    }

    return null;
  }

  // ===================================================
  // NIGHT GROUP
  // ===================================================

  static String? getNightGroup(
    DateTime date,
  ) {
    if (isEmergencyDate(date)) {
      return getEmergencyNightGroup(date);
    }

    for (final group
        in referencePositions.keys) {
      if (getStatus(group, date) == 'N') {
        return group;
      }
    }

    return null;
  }

  // ===================================================
  // SCHEDULE REST
  // ===================================================

  static String getScheduleRestGroups(
    DateTime date,
  ) {
    // Emergency days have no Schedule Rest.
    if (isEmergencyDate(date)) {
      return '-';
    }

    final groups = <String>[];

    for (final group
        in referencePositions.keys) {
      if (getStatus(group, date) == 'SR') {
        groups.add(group);
      }
    }

    return groups.isEmpty
        ? '-'
        : groups.join(', ');
  }

  // ===================================================
  // DAY NUMBER
  // ===================================================

  static int? getDayNumber(
    String group,
    DateTime date,
  ) {
    // Emergency Day is manual duty,
    // not 1st/2nd/3rd/4th normal duty.
    if (isEmergencyDate(date)) {
      return null;
    }

    final position =
        getPosition(group, date);

    switch (position) {
      case 0:
        return 1;

      case 3:
        return 2;

      case 6:
        return 3;

      case 9:
        return 4;

      default:
        return null;
    }
  }

  // ===================================================
  // NIGHT NUMBER
  // ===================================================

  static int? getNightNumber(
    String group,
    DateTime date,
  ) {
    if (isEmergencyDate(date)) {
      return null;
    }

    final position =
        getPosition(group, date);

    switch (position) {
      case 1:
        return 1;

      case 4:
        return 2;

      case 7:
        return 3;

      case 10:
        return 4;

      default:
        return null;
    }
  }

  // ===================================================
  // DETAILED STATUS
  // ===================================================

  static String getDetailedStatus(
    String group,
    DateTime date,
  ) {
    final emergency =
        getEmergencyForDate(date);

    // =================================================
    // EMERGENCY STATUS
    // =================================================

    if (emergency != null) {
      final status =
          getStatus(group, date);

      final emergencyName =
          emergency.name;

      if (status == 'D') {
        return 'Emergency • $emergencyName • Day Duty';
      }

      if (status == 'N') {
        return 'Emergency • $emergencyName • Night Duty';
      }

      return 'Emergency • $emergencyName • Rest';
    }

    // =================================================
    // NORMAL STATUS
    // =================================================

    final status =
        getStatus(group, date);

    if (status == 'D') {
      final number =
          getDayNumber(group, date);

      if (number == null) {
        return 'Day Duty';
      }

      return '${ordinal(number)} Day Duty';
    }

    if (status == 'N') {
      final number =
          getNightNumber(group, date);

      if (number == null) {
        return 'Night Duty';
      }

      return '${ordinal(number)} Night Duty';
    }

    if (status == 'SR') {
      return 'Schedule Rest';
    }

    return 'Rest';
  }

  // ===================================================
  // ORDINAL
  // ===================================================

  static String ordinal(int number) {
    switch (number) {
      case 1:
        return '1st';

      case 2:
        return '2nd';

      case 3:
        return '3rd';

      case 4:
        return '4th';

      default:
        return number.toString();
    }
  }
}