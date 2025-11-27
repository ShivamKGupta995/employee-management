import 'package:intl/intl.dart';

/// DateFormatter - Utility class for formatting dates and times
class DateFormatter {
  DateFormatter._();

  // ==========================================
  // DATE FORMATS
  // ==========================================
  static final DateFormat _dateShort = DateFormat('MMM d');
  static final DateFormat _dateMedium = DateFormat('MMM d, yyyy');
  static final DateFormat _dateFull = DateFormat('EEEE, d MMMM yyyy');
  static final DateFormat _dateFile = DateFormat('yyyy-MM-dd');
  
  // ==========================================
  // TIME FORMATS
  // ==========================================
  static final DateFormat _time12h = DateFormat('hh:mm a');
  static final DateFormat _time24h = DateFormat('HH:mm');
  static final DateFormat _timeWithSeconds = DateFormat('hh:mm:ss a');
  
  // ==========================================
  // DATE + TIME FORMATS
  // ==========================================
  static final DateFormat _dateTime = DateFormat('MMM d, h:mm a');
  static final DateFormat _dateTimeFull = DateFormat('MMM d, yyyy h:mm a');

  // ==========================================
  // FORMAT METHODS
  // ==========================================
  
  /// Format: "Nov 26"
  static String formatShort(DateTime date) => _dateShort.format(date);
  
  /// Format: "Nov 26, 2025"
  static String formatMedium(DateTime date) => _dateMedium.format(date);
  
  /// Format: "Wednesday, 26 November 2025"
  static String formatFull(DateTime date) => _dateFull.format(date);
  
  /// Format: "2025-11-26" (for file names, IDs)
  static String formatForFile(DateTime date) => _dateFile.format(date);
  
  /// Format: "03:45 PM"
  static String formatTime(DateTime date) => _time12h.format(date);
  
  /// Format: "15:45"
  static String formatTime24(DateTime date) => _time24h.format(date);
  
  /// Format: "03:45:30 PM"
  static String formatTimeWithSeconds(DateTime date) => _timeWithSeconds.format(date);
  
  /// Format: "Nov 26, 3:45 PM"
  static String formatDateTime(DateTime date) => _dateTime.format(date);
  
  /// Format: "Nov 26, 2025 3:45 PM"
  static String formatDateTimeFull(DateTime date) => _dateTimeFull.format(date);

  // ==========================================
  // RELATIVE TIME
  // ==========================================
  
  /// Get relative time string (e.g., "2h ago", "Just now")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return formatShort(date);
    }
  }

  /// Get smart date string (Today, Yesterday, or date)
  static String getSmartDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    final difference = today.difference(dateOnly).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return formatMedium(date);
    }
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================
  
  /// Get current date formatted
  static String get currentDate => formatFull(DateTime.now());
  
  /// Get current time formatted
  static String get currentTime => formatTimeWithSeconds(DateTime.now());
  
  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Get month name from month number
  static String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  /// Get all month names
  static List<String> get monthNames => [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
}
