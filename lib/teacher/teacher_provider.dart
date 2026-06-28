import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sriwaap/teacher/teacher_model.dart';
import 'package:sriwaap/teacher/teacher_service.dart';

final teacherServiceProvider = Provider<TeacherService>(
  (ref) => TeacherService(),
);

// ─── Selected year / month state ─────────────────────────────────────────────

final selectedYearProvider = StateProvider<int>((ref) => DateTime.now().year);

final selectedMonthProvider = StateProvider<int>((ref) => DateTime.now().month);

// ─── Annual Goals ─────────────────────────────────────────────────────────────

final annualGoalsProvider = StreamProvider.family<List<AnnualGoal>, int>((
  ref,
  year,
) {
  return ref.watch(teacherServiceProvider).watchGoals(year);
});

// ─── Self Evaluations ─────────────────────────────────────────────────────────

final selfEvalsProvider = StreamProvider.family<List<SelfEvaluation>, int>((
  ref,
  year,
) {
  return ref.watch(teacherServiceProvider).watchSelfEvals(year);
});

final selfEvalForMonthProvider =
    FutureProvider.family<SelfEvaluation?, ({int year, int month})>((
      ref,
      args,
    ) {
      return ref
          .watch(teacherServiceProvider)
          .getSelfEvalForMonth(args.year, args.month);
    });

// ─── Teachers list (for management) — StreamProvider so it stays live ─────────

final teachersListProvider = StreamProvider<List<Map<String, String>>>((ref) {
  return ref.watch(teacherServiceProvider).watchTeachersList();
});

// Selected teacher ID (reset to '' when switching screens)
final selectedTeacherIdProvider = StateProvider<String>((ref) => '');

// ─── Teacher Evaluations (by management) ─────────────────────────────────────

final teacherEvalProvider =
    FutureProvider.family<TeacherEvaluation?, ({String teacherId, int year})>((
      ref,
      args,
    ) {
      return ref
          .watch(teacherServiceProvider)
          .getTeacherEval(teacherId: args.teacherId, year: args.year);
    });

// ─── Progress chart data ───────────────────────────────────────────────────────

final selfEvalProgressProvider = FutureProvider.family<Map<int, double>, int>((
  ref,
  year,
) {
  return ref.watch(teacherServiceProvider).getSelfEvalProgress(year);
});

// ─── Management: progress for a specific teacher ──────────────────────────────

final teacherProgressProvider =
    FutureProvider.family<Map<int, double>, ({String teacherId, int year})>((
      ref,
      args,
    ) {
      return ref
          .watch(teacherServiceProvider)
          .getTeacherProgress(args.teacherId, args.year);
    });

final teacherSelfEvalsProvider =
    StreamProvider.family<List<SelfEvaluation>, ({String teacherId, int year})>(
      (ref, args) {
        return ref
            .watch(teacherServiceProvider)
            .watchTeacherSelfEvals(args.teacherId, args.year);
      },
    );
