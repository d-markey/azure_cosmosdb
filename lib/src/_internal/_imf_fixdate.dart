import 'package:meta/meta.dart';

const _days = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
const _months = [
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
  'Dec'
];

@internal
extension DateTimeFormatExt on DateTime {
  // ignore: non_constant_identifier_names
  static String _00(int n) =>
      (n < 10) ? n.toString().padLeft(2, '0') : n.toString();

  String toTimeString() => '${_00(hour)}:${_00(minute)}:${_00(second)}';

  String toImfFixedString() {
    final date = isUtc ? this : toUtc();
    final dayStr = _days[date.weekday - 1];
    final monthStr = _months[date.month - 1];
    final timeStr = date.toTimeString();
    return '$dayStr, ${_00(date.day)} $monthStr ${date.year} $timeStr GMT'
        .toLowerCase();
  }
}
