import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sriwaap/constant.dart';

import 'package:sriwaap/student/student_service.dart';
import 'package:sriwaap/user_model.dart';

final studentServiceProvider = Provider<StudentService>(
  (ref) => StudentService(),
);

// Selected class filter for leaderboard
final selectedClassProvider = StateProvider<String>((ref) => '');

// Use kClasses from constants — no Firestore read needed
final classesProvider = Provider<List<String>>((ref) => kClasses);

// Live leaderboard stream
final leaderboardProvider = StreamProvider.family<List<Student>, String>(
  (ref, className) =>
      ref.watch(studentServiceProvider).watchLeaderboard(className: className),
);

// Class summary (top3/bottom3 per class)
final classSummaryProvider =
    StreamProvider<Map<String, Map<String, List<Student>>>>((ref) {
      return ref.watch(studentServiceProvider).watchClassSummary();
    });

// Students by class (for deed reporting)
final studentsByClassProvider = StreamProvider.family<List<Student>, String>((
  ref,
  className,
) {
  if (className.isEmpty) return const Stream.empty();
  return ref.watch(studentServiceProvider).watchStudentsByClass(className);
});
