import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sriwaap/teacher/teacher_model.dart';

class TeacherService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ─── Annual Goals ─────────────────────────────────────────────────────────

  Stream<List<AnnualGoal>> watchGoals(int year) {
    return _db
        .collection('annual_goals')
        .where('teacherId', isEqualTo: _uid)
        .where('year', isEqualTo: year)
        .snapshots()
        .map(
          (s) =>
              s.docs
                  .map((d) => AnnualGoal.fromFirestore(d.data(), d.id))
                  .toList()
                ..sort((a, b) => a.category.index.compareTo(b.category.index)),
        );
  }

  Future<void> saveGoal({
    required int year,
    required EvalCategory category,
    required String goalText,
    String? existingId,
  }) async {
    final data = AnnualGoal(
      id: existingId ?? '',
      teacherId: _uid,
      year: year,
      category: category,
      goalText: goalText,
      createdAt: DateTime.now(),
    ).toFirestore();

    if (existingId != null) {
      await _db.collection('annual_goals').doc(existingId).update(data);
    } else {
      await _db.collection('annual_goals').add(data);
    }
  }

  Future<void> deleteGoal(String id) async {
    await _db.collection('annual_goals').doc(id).delete();
  }

  // ─── Self Evaluations (Monthly) ───────────────────────────────────────────

  Stream<List<SelfEvaluation>> watchSelfEvals(int year) {
    return _db
        .collection('self_evaluations')
        .where('teacherId', isEqualTo: _uid)
        .where('year', isEqualTo: year)
        .snapshots()
        .map(
          (s) =>
              s.docs
                  .map((d) => SelfEvaluation.fromFirestore(d.data(), d.id))
                  .toList()
                ..sort((a, b) => a.month.compareTo(b.month)),
        );
  }

  Future<SelfEvaluation?> getSelfEvalForMonth(int year, int month) async {
    final snap = await _db
        .collection('self_evaluations')
        .where('teacherId', isEqualTo: _uid)
        .where('year', isEqualTo: year)
        .where('month', isEqualTo: month)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return SelfEvaluation.fromFirestore(
      snap.docs.first.data(),
      snap.docs.first.id,
    );
  }

  Future<void> submitSelfEval({
    required int year,
    required int month,
    required Map<EvalCategory, int> scores,
    required String remarks,
    String? existingId,
  }) async {
    final data = SelfEvaluation(
      id: existingId ?? '',
      teacherId: _uid,
      year: year,
      month: month,
      remarks: remarks,
      scores: scores,
      submittedAt: DateTime.now(),
    ).toFirestore();

    if (existingId != null) {
      await _db.collection('self_evaluations').doc(existingId).update(data);
    } else {
      await _db.collection('self_evaluations').add(data);
    }
  }

  // ─── Teacher Evaluations (by Management) ─────────────────────────────────

  /// Fetches all teachers — used by management to pick who to evaluate
  Future<List<Map<String, String>>> getTeachersList() async {
    final snap = await _db.collection('teachers').orderBy('name').get();
    return snap.docs
        .map(
          (d) => {
            'id': d.id,
            'name': (d.data()['name'] as String?) ?? '',
            'department': (d.data()['department'] as String?) ?? '',
          },
        )
        .toList();
  }

  Stream<List<TeacherEvaluation>> watchTeacherEvals({
    required String teacherId,
    required int year,
  }) {
    return _db
        .collection('teacher_evaluations')
        .where('teacherId', isEqualTo: teacherId)
        .where('year', isEqualTo: year)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => TeacherEvaluation.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  Future<TeacherEvaluation?> getTeacherEval({
    required String teacherId,
    required int year,
  }) async {
    final snap = await _db
        .collection('teacher_evaluations')
        .where('teacherId', isEqualTo: teacherId)
        .where('year', isEqualTo: year)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return TeacherEvaluation.fromFirestore(
      snap.docs.first.data(),
      snap.docs.first.id,
    );
  }

  Future<void> submitTeacherEval({
    required String teacherId,
    required String evaluatorName,
    required int year,
    required Map<EvalCategory, int> scores,
    required String remarks,
    String? existingId,
  }) async {
    // Compute point gap vs self-eval average for that year
    final selfSnap = await _db
        .collection('self_evaluations')
        .where('teacherId', isEqualTo: teacherId)
        .where('year', isEqualTo: year)
        .get();

    double selfAvg = 0;
    if (selfSnap.docs.isNotEmpty) {
      final allSelfScores = selfSnap.docs
          .map((d) => SelfEvaluation.fromFirestore(d.data(), d.id))
          .map((e) => e.averageScore)
          .toList();
      selfAvg = allSelfScores.fold(0.0, (a, b) => a + b) / allSelfScores.length;
    }

    final evalAvg = scores.values.fold(0, (a, b) => a + b) / scores.length;
    final gap = (evalAvg - selfAvg).round();

    final data = TeacherEvaluation(
      id: existingId ?? '',
      teacherId: teacherId,
      evaluatorId: _uid,
      evaluatorName: evaluatorName,
      year: year,
      remarks: remarks,
      scores: scores,
      pointGap: gap,
      submittedAt: DateTime.now(),
    ).toFirestore();

    if (existingId != null) {
      await _db.collection('teacher_evaluations').doc(existingId).update(data);
    } else {
      await _db.collection('teacher_evaluations').add(data);
    }
  }

  // ─── Progress data (for charts) ───────────────────────────────────────────

  /// Returns monthly average scores for this teacher across a year
  Future<Map<int, double>> getSelfEvalProgress(int year) async {
    final snap = await _db
        .collection('self_evaluations')
        .where('teacherId', isEqualTo: _uid)
        .where('year', isEqualTo: year)
        .get();

    return {
      for (final doc in snap.docs)
        SelfEvaluation.fromFirestore(doc.data(), doc.id).month:
            SelfEvaluation.fromFirestore(doc.data(), doc.id).averageScore,
    };
  }
}
