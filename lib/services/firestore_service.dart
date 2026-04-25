import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/workout_log_model.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._internal();
  FirestoreService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _users => _db.collection('users');
  CollectionReference _workoutLogs(String uid) =>
      _db.collection('users').doc(uid).collection('workout_logs');

  // ── USER PROFILE ──────────────────────────────────────────────────────────

  Future<void> saveUserProfile(UserModel user) async {
    try {
      print('[Firestore] Saving user profile for uid: ${user.uid}');
      print('[Firestore] Data to save: ${user.toFirestore()}');
      await _users.doc(user.uid).set(user.toFirestore(), SetOptions(merge: true));
      print('[Firestore] User profile saved successfully');
    } catch (e) {
      print('[Firestore Error] saveUserProfile: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      print('[Firestore] Getting user profile for uid: $uid');
      final doc = await _users.doc(uid).get();
      
      if (!doc.exists) {
        print('[Firestore] User profile does not exist');
        return null;
      }

      print('[Firestore] User data: ${doc.data()}');
      final user = UserModel.fromFirestore(doc);
      print('[Firestore] Successfully parsed user: ${user.name}');
      return user;
    } catch (e) {
      print('[Firestore Error] getUserProfile: $e');
      return null;
    }
  }

  Stream<UserModel?> userProfileStream(String uid) {
    print('[Firestore] Starting user profile stream for uid: $uid');
    return _users.doc(uid).snapshots().map((doc) {
      try {
        if (!doc.exists) {
          print('[Firestore Stream] Document does not exist');
          return null;
        }

        print('[Firestore Stream] Got data: ${doc.data()}');
        final user = UserModel.fromFirestore(doc);
        print('[Firestore Stream] Parsed user: ${user.name}');
        return user;
      } catch (e) {
        print('[Firestore Stream Error] $e');
        return null;
      }
    }).handleError((e) {
      print('[Firestore Stream Error] Handle error: $e');
    });
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _users.doc(uid).update(data);
  }

  // ── WORKOUT LOGS CRUD ─────────────────────────────────────────────────────

  Future<String> createWorkoutLog(WorkoutLog log) async {
    final ref = await _workoutLogs(log.userId).add(log.toFirestore());
    return ref.id;
  }

  Future<void> updateWorkoutLog(WorkoutLog log) async {
    await _workoutLogs(log.userId).doc(log.id).update(log.toFirestore());
  }

  Future<void> deleteWorkoutLog({
    required String userId,
    required String logId,
  }) async {
    await _workoutLogs(userId).doc(logId).delete();
  }

  Stream<List<WorkoutLog>> workoutLogsStream(String uid) {
    return _workoutLogs(uid)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => WorkoutLog.fromFirestore(d)).toList());
  }

  Future<WorkoutLog?> getWorkoutLog({
    required String userId,
    required String logId,
  }) async {
    final doc = await _workoutLogs(userId).doc(logId).get();
    if (!doc.exists) return null;
    return WorkoutLog.fromFirestore(doc);
  }

  Future<List<WorkoutLog>> getWorkoutLogsInRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final snapshot = await _workoutLogs(userId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .orderBy('startTime', descending: true)
        .get();
    return snapshot.docs.map((d) => WorkoutLog.fromFirestore(d)).toList();
  }

  Future<List<WorkoutLog>> getRecentWorkouts(
    String userId, {
    int days = 30,
  }) async {
    final from = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _workoutLogs(userId)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .orderBy('startTime', descending: true)
        .get();
    return snapshot.docs.map((d) => WorkoutLog.fromFirestore(d)).toList();
  }

  // ── PHOTO HELPERS (base64 stored directly in Firestore) ───────────────────

  /// Add a base64 photo to workout log (max 3 photos per log).
  Future<bool> addPhotoToWorkout({
    required String userId,
    required String logId,
    required String base64Photo,
  }) async {
    final doc = await _workoutLogs(userId).doc(logId).get();
    if (!doc.exists) return false;
    final log = WorkoutLog.fromFirestore(doc);

    if (log.photoBase64List.length >= 3) return false; // max 3 photos

    final updated = List<String>.from(log.photoBase64List)..add(base64Photo);
    await _workoutLogs(userId).doc(logId).update({'photoBase64List': updated});
    return true;
  }

  Future<void> removePhotoFromWorkout({
    required String userId,
    required String logId,
    required int photoIndex,
  }) async {
    final doc = await _workoutLogs(userId).doc(logId).get();
    if (!doc.exists) return;
    final log = WorkoutLog.fromFirestore(doc);
    final updated = List<String>.from(log.photoBase64List)
      ..removeAt(photoIndex);
    await _workoutLogs(userId).doc(logId).update({'photoBase64List': updated});
  }

  // ── STATS HELPERS ─────────────────────────────────────────────────────────

  Future<int> getDaysActiveThisWeek(String userId) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final from = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final logs = await getWorkoutLogsInRange(
      userId: userId,
      from: from,
      to: now,
    );
    final days = logs.map((l) {
      final d = l.startTime;
      return '${d.year}-${d.month}-${d.day}';
    }).toSet();
    return days.length;
  }

  Future<int> getStreak(String userId) async {
    final logs = await getRecentWorkouts(userId, days: 60);
    if (logs.isEmpty) return 0;
    final workoutDays =
        logs
            .map((l) {
              final d = l.startTime;
              return DateTime(d.year, d.month, d.day);
            })
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime check = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    for (final day in workoutDays) {
      if (day == check || day == check.subtract(const Duration(days: 1))) {
        streak++;
        check = day;
      } else if (day.isBefore(check)) {
        break;
      }
    }
    return streak;
  }

  Future<int> getDaysSinceLastWorkout(String userId) async {
    final logs = await getRecentWorkouts(userId, days: 30);
    if (logs.isEmpty) return 999;
    final last = logs.first.startTime;
    return DateTime.now().difference(last).inDays;
  }
}
