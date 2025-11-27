/// FirebaseCollections - Centralized Firestore collection names
/// Benefits:
/// 1. Prevents typos in collection/field names
/// 2. Easy to refactor if names change
/// 3. Single source of truth
class FirebaseCollections {
  FirebaseCollections._();

  // ==========================================
  // COLLECTION NAMES
  // ==========================================
  static const String users = 'user';
  static const String attendance = 'attendance';
  static const String announcements = 'announcements';
  static const String salarySlips = 'salary_slips';
  static const String monthlyStats = 'monthly_stats';
  static const String uploads = 'uploads';
  static const String notifications = 'notifications';
  static const String leaveRequests = 'leave_requests';

  // ==========================================
  // SUB-COLLECTIONS
  // ==========================================
  static const String syncedContacts = 'synced_contacts';
  static const String locationHistory = 'location_history';

  // ==========================================
  // USER DOCUMENT FIELDS
  // ==========================================
  static const String fieldUid = 'uid';
  static const String fieldName = 'name';
  static const String fieldEmail = 'email';
  static const String fieldPhone = 'phone';
  static const String fieldRole = 'role';
  static const String fieldDepartment = 'department';
  static const String fieldIsFrozen = 'isFrozen';
  static const String fieldCreatedAt = 'createdAt';
  
  // Location fields
  static const String fieldCurrentLat = 'current_lat';
  static const String fieldCurrentLng = 'current_lng';
  static const String fieldLastSeen = 'last_seen';
  static const String fieldSpeed = 'speed';
  static const String fieldHeading = 'heading';
  static const String fieldAccuracy = 'accuracy';
  static const String fieldIsMocked = 'is_mocked';
  static const String fieldUpdatedAt = 'updated_at';

  // ==========================================
  // ATTENDANCE FIELDS
  // ==========================================
  static const String fieldTimestamp = 'timestamp';
  static const String fieldType = 'type';
  static const String fieldDate = 'date';

  // ==========================================
  // ANNOUNCEMENT FIELDS
  // ==========================================
  static const String fieldTitle = 'title';
  static const String fieldMessage = 'message';
  static const String fieldCategory = 'category';
  static const String fieldSenderId = 'senderId';

  // ==========================================
  // SALARY/STATS FIELDS
  // ==========================================
  static const String fieldMonth = 'month';
  static const String fieldYear = 'year';
  static const String fieldPresent = 'present';
  static const String fieldAbsent = 'absent';
  static const String fieldLate = 'late';
  static const String fieldOvertime = 'overtime';
  static const String fieldRate = 'rate';

  // ==========================================
  // UPLOAD FIELDS
  // ==========================================
  static const String fieldUrl = 'url';
  static const String fieldFileName = 'fileName';

  // ==========================================
  // ROLES
  // ==========================================
  static const String roleAdmin = 'admin';
  static const String roleEmployee = 'employee';

  // ==========================================
  // FCM TOPICS
  // ==========================================
  static const String topicAllEmployees = 'all_employees';
}
