import 'package:intl/intl.dart';

/// Date/time/number formatting helpers (backed by `intl`).
abstract final class AppFormatters {
  static final DateFormat _date = DateFormat('MMM d, yyyy');
  static final DateFormat _shortDate = DateFormat('MMM d');
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _weekday = DateFormat('EEE');
  static final DateFormat _isoDay = DateFormat('yyyy-MM-dd');

  static String date(DateTime value) => _date.format(value);

  static String shortDate(DateTime value) => _shortDate.format(value);

  static String time(DateTime value) => _time.format(value);

  static String weekday(DateTime value) => _weekday.format(value);

  /// Stable, sortable day key used for Firestore documents and queries.
  static String dayKey(DateTime value) => _isoDay.format(value);

  static String minutes(int totalMinutes) {
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes % 60;
    if (hours == 0) {
      return '${minutes}m';
    }
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }

  static String weight(double kilograms) {
    if (kilograms == kilograms.roundToDouble()) {
      return '${kilograms.round()} kg';
    }
    return '${kilograms.toStringAsFixed(1)} kg';
  }
}
