import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/emergency_roster.dart';

class EmergencyRosterService {
  static const String _storageKey = 'emergency_rosters';

  static Future<List<EmergencyRoster>> getAll() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(_storageKey);

    if (saved == null || saved.isEmpty) {
      return [];
    }

    final List<dynamic> decoded = jsonDecode(saved);

    return decoded
        .map(
          (item) => EmergencyRoster.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  static Future<void> _saveAll(
    List<EmergencyRoster> rosters,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final data = rosters
        .map((roster) => roster.toJson())
        .toList();

    await prefs.setString(
      _storageKey,
      jsonEncode(data),
    );
  }

  static Future<void> add(
    EmergencyRoster roster,
  ) async {
    final rosters = await getAll();

    rosters.add(roster);

    await _saveAll(rosters);
  }

  static Future<void> delete(
    String id,
  ) async {
    final rosters = await getAll();

    rosters.removeWhere(
      (roster) => roster.id == id,
    );

    await _saveAll(rosters);
  }

  static Future<void> update(
    EmergencyRoster updatedRoster,
  ) async {
    final rosters = await getAll();

    final index = rosters.indexWhere(
      (roster) => roster.id == updatedRoster.id,
    );

    if (index == -1) {
      return;
    }

    rosters[index] = updatedRoster;

    await _saveAll(rosters);
  }

  static Future<EmergencyRoster?> getRosterForDate(
    DateTime date,
  ) async {
    final rosters = await getAll();

    final cleanDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    for (final roster in rosters) {
      final start = DateTime(
        roster.startDate.year,
        roster.startDate.month,
        roster.startDate.day,
      );

      final end = DateTime(
        roster.endDate.year,
        roster.endDate.month,
        roster.endDate.day,
      );

      if (!cleanDate.isBefore(start) &&
          !cleanDate.isAfter(end)) {
        return roster;
      }
    }

    return null;
  }

  static String dateKey(DateTime date) {
    final year = date.year.toString();

    final month =
        date.month.toString().padLeft(2, '0');

    final day =
        date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}