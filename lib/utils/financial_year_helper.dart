class FinancialYearHelper {
  // Private constructor
  FinancialYearHelper._();

  /// Returns the start year of the current Financial Year.
  /// Example: If today is Nov 2025, returns 2025.
  /// Example: If today is Jan 2026, returns 2025 (because FY is 2025-26).
  static int getCurrentFYStartYear() {
    final now = DateTime.now();
    // If month is Jan, Feb, Mar (1, 2, 3), we are in the previous year's cycle
    if (now.month < 4) {
      return now.year - 1;
    }
    return now.year;
  }

  /// Returns "2025-2026" string for display
  static String getFYString(int startYear) {
    return "$startYear-${startYear + 1}";
  }

  /// Get April 1st of the start year
  static DateTime getStartDate(int startYear) {
    return DateTime(startYear, 4, 1); // April 1st
  }

  /// Get March 31st of the next year
  static DateTime getEndDate(int startYear) {
    return DateTime(startYear + 1, 3, 31, 23, 59, 59); // March 31st, End of day
  }

  /// Generate a list of FY options for the Dropdown
  /// Returns [2024, 2025, 2026] (representing 24-25, 25-26, 26-27)
  static List<int> getAvailableYears() {
    int current = getCurrentFYStartYear();
    return [
      current - 1, // Previous FY
      current,     // Current FY
      current + 1  // Next FY
    ];
  }
}