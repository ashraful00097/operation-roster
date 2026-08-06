class EmergencyRoster {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  // Example:
  // {
  //   '2026-06-11': {
  //      'day': 'G-A',
  //      'night': 'G-B'
  //   }
  // }
  final Map<String, Map<String, String>> duties;

  EmergencyRoster({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.duties,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'duties': duties,
    };
  }

  factory EmergencyRoster.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawDuties =
        Map<String, dynamic>.from(json['duties']);

    final duties =
        <String, Map<String, String>>{};

    rawDuties.forEach((date, value) {
      duties[date] = Map<String, String>.from(
        value,
      );
    });

    return EmergencyRoster(
      id: json['id'],
      name: json['name'],
      startDate: DateTime.parse(
        json['startDate'],
      ),
      endDate: DateTime.parse(
        json['endDate'],
      ),
      duties: duties,
    );
  }
}