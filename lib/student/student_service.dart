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

  Future<List<String>> getClasses() async {
    final snap = await _db.collection('students').get();
    final classes =
        snap.docs
            .map((d) => d.data()['className'] as String? ?? '')
            .toSet()
            .toList()
          ..sort();
    return classes;
  }

  // ─── Good Deeds ───────────────────────────────────────────────────────────

  Future<void> reportGoodDeed({
    required Student student,
    required GoodDeedCategory category,
    required String remarks,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    final batch = _db.batch();

    // Write good deed record
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

    // Increment student total points
    final studentRef = _db.collection('students').doc(student.id);
    batch.update(studentRef, {
      'totalPoints': FieldValue.increment(category.points),
    });

    await batch.commit();
  }

  // ─── Leaderboard ──────────────────────────────────────────────────────────

  Stream<List<Student>> watchLeaderboard({String? className}) {
    Query<Map<String, dynamic>> query = _db
        .collection('students')
        .orderBy('totalPoints', descending: true);

    if (className != null && className.isNotEmpty) {
      query = query.where('className', isEqualTo: className);
    }

    return query.snapshots().map(
      (s) => s.docs.map((d) => Student.fromFirestore(d.data(), d.id)).toList(),
    );
  }

  // ─── Class Summary ────────────────────────────────────────────────────────

  Future<Map<String, Map<String, List<Student>>>> getClassSummary() async {
    final snap = await _db
        .collection('students')
        .orderBy('totalPoints', descending: true)
        .get();

    final all = snap.docs
        .map((d) => Student.fromFirestore(d.data(), d.id))
        .toList();

    // Group by class
    final Map<String, List<Student>> byClass = {};
    for (final s in all) {
      byClass.putIfAbsent(s.className, () => []).add(s);
    }

    // Build top3 / bottom3 per class
    final Map<String, Map<String, List<Student>>> result = {};
    byClass.forEach((className, students) {
      result[className] = {
        'top': students.take(3).toList(),
        'bottom': students.reversed.take(3).toList(),
      };
    });

    return result;
  }
}
