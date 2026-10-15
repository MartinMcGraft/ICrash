/// Shift periods (design v2 B8 legend: M = manhã 08–16, T = tarde 16–24,
/// N = noite 00–08).
enum ShiftPeriod { morning, afternoon, night }

extension ShiftPeriodHours on ShiftPeriod {
  int get startHour => switch (this) {
        ShiftPeriod.morning => 8,
        ShiftPeriod.afternoon => 16,
        ShiftPeriod.night => 0,
      };

  /// Which period a given time falls in.
  static ShiftPeriod at(DateTime time) {
    if (time.hour >= 8 && time.hour < 16) return ShiftPeriod.morning;
    if (time.hour >= 16) return ShiftPeriod.afternoon;
    return ShiftPeriod.night;
  }
}

/// Proposal D8: a shift = the health professional responsible for a cart in
/// one period of one day. Backed by a local stub repository for now.
class ShiftAssignment {
  const ShiftAssignment({required this.cartId, required this.day, required this.period, required this.uid});

  final String cartId;

  /// Calendar day (time part ignored).
  final DateTime day;
  final ShiftPeriod period;
  final String uid;

  String get key => '$cartId|${dayKey(day)}|${period.name}';

  static String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Map<String, Object?> toJson() => {'cartId': cartId, 'day': dayKey(day), 'period': period.name, 'uid': uid};

  factory ShiftAssignment.fromJson(Map<String, Object?> json) => ShiftAssignment(
        cartId: json['cartId'] as String,
        day: DateTime.parse(json['day'] as String),
        period: ShiftPeriod.values.byName(json['period'] as String),
        uid: json['uid'] as String,
      );
}
