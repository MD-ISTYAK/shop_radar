import 'package:intl/intl.dart';

class TimeUtils {
  /// Converts a UTC DateTime to Indian Standard Time (IST)
  static DateTime toIST(DateTime utc) {
    // IST is UTC + 5:30
    return utc.toUtc().add(const Duration(hours: 5, minutes: 30));
  }

  /// Formats a DateTime in IST using a specific pattern
  static String formatIST(DateTime utc, {String pattern = 'dd MMM yyyy, hh:mm a'}) {
    final istDate = toIST(utc);
    return DateFormat(pattern).format(istDate);
  }

  /// Returns a "time ago" string relative to IST
  static String timeAgoIST(DateTime utc) {
    final istNow = toIST(DateTime.now().toUtc());
    final istDate = toIST(utc);
    final diff = istNow.difference(istDate);

    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo';
    if (diff.inDays > 7) return '${diff.inDays ~/ 7}w';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}
