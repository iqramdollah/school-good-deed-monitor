import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sriwaap/student/good_deed_model.dart';
import 'package:sriwaap/user_model.dart';

class StudentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Students ─────────────────────────────────────────────────────────────

  Stream<List<Student>> watchStudentsByClass(String className) {
    return _db
        .collection('students')
        .where('className', isEqualTo: className)
        .orderBy('name')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => Student.fromFirestore(d.data(), d.id)).toList(),
        );
  }

  // ─── Good Deeds ───────────────────────────────────────────────────────────

  Future<void> reportGoodDeed({
    required Student student,
    required GoodDeedCategory category,
    required String remarks,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    final batch = _db.batch();

    final deedRef = _db.collection('good_deeds').doc();
    batch.set(deedRef, {
      'studentId': student.id,
      'studentName': student.name,
      'className': student.className,
      'categoryId': category.id,
      'categoryName': category.name,
      'points': category.points,
      'remarks': remarks,
      'date': FieldValue.serverTimestamp(),
      'reportedBy': uid,
    });

    final studentRef = _db.collection('students').doc(student.id);
    batch.update(studentRef, {
      'totalPoints': FieldValue.increment(category.points),
    });

    await batch.commit();
  }

  // ─── Leaderboard ──────────────────────────────────────────────────────────
  // Fetch all students sorted by points, filter in-memory to avoid
  // needing a Firestore composite index on className + totalPoints

  Stream<List<Student>> watchLeaderboard({String? className}) {
    return _db
        .collection('students')
        .orderBy('totalPoints', descending: true)
        .snapshots()
        .map((s) {
          final all = s.docs
              .map((d) => Student.fromFirestore(d.data(), d.id))
              .toList();
          if (className == null || className.isEmpty) return all;
          return all.where((s) => s.className == className).toList();
        });
  }

  // ─── Class Summary (live stream) ──────────────────────────────────────────

  Stream<Map<String, Map<String, List<Student>>>> watchClassSummary() {
    return _db
        .collection('students')
        .orderBy('totalPoints', descending: true)
        .snapshots()
        .map((s) {
          final all = s.docs
              .map((d) => Student.fromFirestore(d.data(), d.id))
              .toList();

          final Map<String, List<Student>> byClass = {};
          for (final student in all) {
            byClass.putIfAbsent(student.className, () => []).add(student);
          }

          final Map<String, Map<String, List<Student>>> result = {};
          byClass.forEach((className, students) {
            // already sorted descending by totalPoints from Firestore
            result[className] = {
              'top': students.take(3).toList(),
              'bottom': students.reversed.take(3).toList(),
            };
          });

          return result;
        });
  }
}
