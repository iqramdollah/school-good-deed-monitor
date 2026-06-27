import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sriwaap/user_model.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Students ─────────────────────────────────────────────────────────────

  Stream<List<Student>> watchStudents() {
    return _db
        .collection('students')
        .orderBy('className')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => Student.fromFirestore(d.data(), d.id)).toList(),
        );
  }

  Future<void> addStudent(String name, String className) async {
    await _db.collection('students').add({
      'name': name,
      'className': className,
      'totalPoints': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStudent(String id, String name, String className) async {
    await _db.collection('students').doc(id).update({
      'name': name,
      'className': className,
    });
  }

  Future<void> deleteStudent(String id) async {
    await _db.collection('students').doc(id).delete();
  }

  Future<void> addStudentAccount(
    String studentId,
    String email, {
    String password = '123456',
  }) async {
    // Create Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    // Write to users collection with student role
    await _db.collection('users').doc(uid).set({
      'name':
          (await _db.collection('students').doc(studentId).get())
              .data()?['name'] ??
          '',
      'email': email,
      'role': UserRole.student.name,
      'studentId': studentId, // link to student record
    });
  }
  // ─── Teachers ─────────────────────────────────────────────────────────────

  Stream<List<Teacher>> watchTeachers() {
    return _db
        .collection('teachers')
        .orderBy('name')
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => Teacher.fromFirestore(d.data(), d.id)).toList(),
        );
  }

  Future<void> addTeacher(
    String name,
    String email,
    String department, {
    String password = '123456',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    // Write to teachers collection
    await _db.collection('teachers').doc(uid).set({
      'name': name,
      'email': email,
      'department': department,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Write to users collection for role-based auth
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'role': UserRole.teacher.name,
    });
  }

  Future<void> updateTeacher(String id, String name, String department) async {
    await _db.collection('teachers').doc(id).update({
      'name': name,
      'department': department,
    });
    await _db.collection('users').doc(id).update({'name': name});
  }

  Future<void> deleteTeacher(String id) async {
    await _db.collection('teachers').doc(id).delete();
    await _db.collection('users').doc(id).delete();
    // Note: Firebase Auth account deletion requires Admin SDK on backend
    // For now we just remove Firestore records
  }

  // ─── Annual Update ────────────────────────────────────────────────────────
  // Promotes all students to the next class and resets points

  Future<int> runAnnualUpdate(Map<String, String> classPromotionMap) async {
    // classPromotionMap: { 'Year 1': 'Year 2', 'Year 2': 'Year 3', ... }
    final batch = _db.batch();
    final students = await _db.collection('students').get();
    int count = 0;

    for (final doc in students.docs) {
      final currentClass = doc.data()['className'] as String? ?? '';
      final nextClass = classPromotionMap[currentClass];
      if (nextClass != null) {
        batch.update(doc.reference, {'className': nextClass, 'totalPoints': 0});
        count++;
      }
    }

    await batch.commit();
    return count;
  }

  // ─── Stats ────────────────────────────────────────────────────────────────

  Future<Map<String, int>> getStats() async {
    final students = await _db.collection('students').count().get();
    final teachers = await _db.collection('teachers').count().get();
    return {'students': students.count ?? 0, 'teachers': teachers.count ?? 0};
  }
}
