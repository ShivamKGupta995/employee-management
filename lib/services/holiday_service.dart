import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:employee_system/models/holiday_model.dart';

class HolidayService {
  final CollectionReference _ref = FirebaseFirestore.instance.collection('holidays');

  // 1. Get All (Admin)
  Stream<List<HolidayModel>> getAllHolidays() {
    return _ref.orderBy('date').snapshots().map((snapshot) => 
        snapshot.docs.map((doc) => HolidayModel.fromFirestore(doc)).toList());
  }

  // 2. Get By Year (Employee)
  Stream<List<HolidayModel>> getHolidaysForYear(int year) {
    DateTime start = DateTime(year, 1, 1);
    DateTime end = DateTime(year, 12, 31, 23, 59, 59);

    return _ref
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => HolidayModel.fromFirestore(doc)).toList());
  }

  // 3. Save (Smart Handle)
  Future<void> saveHoliday(HolidayModel holiday) async {
    if (holiday.id == null) {
      // ✅ CASE 1: CREATE NEW
      // using .add() lets Firestore generate the Auto-ID
      await _ref.add(holiday.toMap()); 
    } else {
      // ✅ CASE 2: UPDATE EXISTING
      // We use the existing ID to update that specific document
      await _ref.doc(holiday.id).update(holiday.toMap());
    }
  }

  // 4. Delete
  Future<void> deleteHoliday(String id) async {
    await _ref.doc(id).delete();
  }
}