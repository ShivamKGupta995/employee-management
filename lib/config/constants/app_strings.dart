/// AppStrings - All static text strings used in the app
/// Benefits:
/// 1. Easy to change text in one place
/// 2. Supports future localization (i18n)
/// 3. No typos from copy-pasting strings
class AppStrings {
  AppStrings._();

  // ==========================================
  // APP INFO
  // ==========================================
  static const String appName = 'Employee System';
  static const String appVersion = '1.0.0';
  static const String companyName = 'OSC Atelier';

  // ==========================================
  // AUTH SCREENS
  // ==========================================
  static const String welcomeBack = 'Welcome Back';
  static const String signInToContinue = 'Sign in to continue';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String login = 'LOGIN';
  static const String rememberEmail = 'Remember Email';
  static const String forgotPassword = 'Forgot Password?';
  static const String logout = 'Logout';
  static const String logoutConfirm = 'Are you sure you want to logout?';

  // ==========================================
  // VALIDATION MESSAGES
  // ==========================================
  static const String invalidEmail = 'Please enter a valid email';
  static const String passwordMinLength = 'Password must be at least 6 characters';
  static const String fieldRequired = 'This field is required';
  static const String userNotFound = 'No user found with this email';
  static const String wrongPassword = 'Incorrect password';
  static const String accountFrozen = 'Your account has been suspended. Contact Admin.';
  static const String roleNotAssigned = 'Role not assigned. Contact Admin.';

  // ==========================================
  // DASHBOARD
  // ==========================================
  static const String dashboard = 'Dashboard';
  static const String overview = 'Overview';
  static const String quickActions = 'Quick Actions';
  static const String totalStaff = 'Total Staff';
  static const String notices = 'Notices';
  static const String presentToday = 'Present Today';
  static const String onLeave = 'On Leave';

  // ==========================================
  // EMPLOYEE SCREENS
  // ==========================================
  static const String home = 'Home';
  static const String report = 'Report';
  static const String profile = 'Profile';
  static const String clockIn = 'Clock In';
  static const String clockOut = 'Clock Out';
  static const String clockedInSuccess = 'Clocked IN Successfully';
  static const String clockedOutSuccess = 'Clocked OUT Successfully';
  static const String salarySlip = 'Salary Slip';
  static const String uploadEvidence = 'Upload Evidence';
  static const String applyLeave = 'Apply Leave';
  static const String emergency = 'Emergency';
  static const String syncContacts = 'Sync Contacts';
  static const String backupPhonebook = 'Backup phonebook to cloud';

  // ==========================================
  // ADMIN SCREENS
  // ==========================================
  static const String employees = 'Employees';
  static const String manageEmployees = 'Manage Employees';
  static const String addEmployee = 'Add Employee';
  static const String editEmployee = 'Edit Employee';
  static const String deleteEmployee = 'Delete Employee';
  static const String notifications = 'Notifications';
  static const String attendance = 'Attendance';
  static const String generateSalary = 'Generate Salary';
  static const String monitoring = 'Monitoring';
  static const String reports = 'Reports';
  static const String settings = 'Settings';
  static const String postNotice = 'Post Notice';

  // ==========================================
  // NOTIFICATIONS
  // ==========================================
  static const String composeAnnouncement = '📢 Compose Announcement';
  static const String postToDashboard = 'POST TO DASHBOARD';
  static const String noAnnouncements = 'No announcements yet';
  static const String announcementSent = '✅ Announcement Broadcasted!';
  static const String noticeDeleted = 'Notice Deleted';

  // ==========================================
  // CATEGORIES
  // ==========================================
  static const String categoryGeneral = 'General';
  static const String categoryUrgent = 'Urgent';
  static const String categoryHoliday = 'Holiday';
  static const String categoryPolicy = 'Policy';
  static const String categoryEvent = 'Event';

  // ==========================================
  // LOCATION TRACKING
  // ==========================================
  static const String trackingActive = '📍 Tracking Active';
  static const String trackingStarted = '✅ Location tracking started successfully!';
  static const String gpsRequired = 'GPS Required';
  static const String enableGps = 'Please enable GPS/Location Services to use tracking.';
  static const String permissionsRequired = 'Permissions Required';
  static const String weakGpsSignal = '⚠️ Weak GPS Signal';
  static const String locationError = '❌ Location Error';

  // ==========================================
  // ATTENDANCE
  // ==========================================
  static const String monthlyReport = 'Monthly Report';
  static const String present = 'Present';
  static const String absent = 'Absent';
  static const String late = 'Late';
  static const String days = 'Days';
  static const String noReportFound = 'No report found for this month.';

  // ==========================================
  // UPLOAD
  // ==========================================
  static const String takePhoto = 'Take Photo';
  static const String gallery = 'Gallery';
  static const String uploadDocument = 'Upload Document';
  static const String uploadSuccessful = '✅ Upload Successful!';

  // ==========================================
  // COMMON ACTIONS
  // ==========================================
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String update = 'Update';
  static const String delete = 'Delete';
  static const String add = 'Add';
  static const String edit = 'Edit';
  static const String openSettings = 'Open Settings';
  static const String retry = 'Retry';
  static const String loading = 'Loading...';

  // ==========================================
  // ERROR MESSAGES
  // ==========================================
  static const String somethingWentWrong = 'Something went wrong';
  static const String networkError = 'Network error. Please check your connection.';
  static const String permissionDenied = 'Permission denied';
  static const String noDataFound = 'No data found';

  // ==========================================
  // SUCCESS MESSAGES
  // ==========================================
  static const String savedSuccessfully = 'Saved successfully';
  static const String updatedSuccessfully = 'Updated successfully';
  static const String deletedSuccessfully = 'Deleted successfully';

  // ==========================================
  // TIME FORMATS
  // ==========================================
  static const String justNow = 'Just now';
  static const String minutesAgo = 'm ago';
  static const String hoursAgo = 'h ago';
}
