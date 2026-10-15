import 'package:flutter/widgets.dart';

import '../../common/l10n/app_localizations.dart';

/// Date formats used across design v2 ("02 out", "12 out 2026, 15:40",
/// "Hoje, 14:32", "28/10/2026", "Seg 12"). Month/weekday names are kept
/// here rather than taken from intl, whose PT abbreviations carry trailing
/// dots ("out.") that the design does not use.
class IcFormat {
  IcFormat._(this._pt, this._l10n);

  factory IcFormat.of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return IcFormat._(locale.languageCode == 'pt', AppLocalizations.of(context));
  }

  final bool _pt;
  final AppLocalizations _l10n;

  static const _monthsPt = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
  static const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _monthsLongPt = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
  ];
  static const _monthsLongEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdaysPt = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  static const _weekdaysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _weekdaysLongPt = ['segunda-feira', 'terça-feira', 'quarta-feira', 'quinta-feira', 'sexta-feira', 'sábado', 'domingo'];
  static const _weekdaysLongEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  static String _two(int n) => n.toString().padLeft(2, '0');

  String _month(DateTime d) => (_pt ? _monthsPt : _monthsEn)[d.month - 1];

  /// "02 out"
  String dayMonth(DateTime d) => '${_two(d.day)} ${_month(d)}';

  /// "12 out 2026"
  String date(DateTime d) => '${_two(d.day)} ${_month(d)} ${d.year}';

  /// "12 out 2026, 15:40"
  String dateTime(DateTime d) => '${date(d)}, ${time(d)}';

  /// "15:40"
  String time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  /// "28/10/2026" (or 10/28/2026 is never used: the app shows day first in EN too).
  String numeric(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

  /// "outubro 2026"
  String monthYear(DateTime d) => '${(_pt ? _monthsLongPt : _monthsLongEn)[d.month - 1]} ${d.year}';

  /// "Seg 12"
  String weekdayDay(DateTime d) => '${(_pt ? _weekdaysPt : _weekdaysEn)[d.weekday - 1]} ${d.day}';

  /// "segunda-feira, 12 out 2026"
  String longDate(DateTime d) => '${(_pt ? _weekdaysLongPt : _weekdaysLongEn)[d.weekday - 1]}, ${date(d)}';

  /// "Hoje, 14:32" / "Ontem, 18:40" / "10 out, 16:20"
  String relative(DateTime d, {DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    final day = _day(d);
    if (day == today) return _l10n.formatToday(time(d));
    if (day == today.subtract(const Duration(days: 1))) return _l10n.formatYesterday(time(d));
    return '${dayMonth(d)}, ${time(d)}';
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// "−2" / "+2" with a real minus sign.
  static String signed(int value) => value > 0 ? '+$value' : value < 0 ? '−${-value}' : '0';
}
