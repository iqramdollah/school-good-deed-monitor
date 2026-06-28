import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sriwaap/firebase_options.dart';
import 'package:sriwaap/user_model.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Secondary app used to create accounts without logging out the admin
  Future<FirebaseAuth> _secondaryAuth() async {
    try {
      final secondary = await Firebase.initializeApp(
        name: 'secondary',
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return FirebaseAuth.instanceFor(app: secondary);
    } catch (e) {
      // Already initialized — reuse it
      return FirebaseAuth.instanceFor(app: Firebase.app('secondary'));
    }
  }

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

  Future<void> addStudent(String name, String ic, String className) async {
    await _db.collection('students').add({
      'name': name,
      'ic': ic,
      'className': className,
      'totalPoints': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStudent(
    String id,
    String name,
    String ic,
    String className,
  ) async {
    await _db.collection('students').doc(id).update({
      'name': name,
      'ic': ic,
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
    final auth = await _secondaryAuth();
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    await auth.signOut(); // sign out of secondary only

    await _db.collection('users').doc(uid).set({
      'name':
          (await _db.collection('students').doc(studentId).get())
              .data()?['name'] ??
          '',
      'email': email,
      'role': UserRole.student.name,
      'studentId': studentId,
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
    String password = 'Turquoise@2024',
  }) async {
    final auth = await _secondaryAuth();
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    await auth.signOut(); // sign out of secondary only

    await _db.collection('teachers').doc(uid).set({
      'name': name,
      'email': email,
      'department': department,
      'createdAt': FieldValue.serverTimestamp(),
    });

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
  }

  // ─── Annual Update ────────────────────────────────────────────────────────

  Future<int> runAnnualUpdate(Map<String, String> classPromotionMap) async {
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
