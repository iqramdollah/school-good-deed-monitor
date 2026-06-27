import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sriwaap/admin/admin_service.dart';
import 'package:sriwaap/user_model.dart';

final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

final studentsStreamProvider = StreamProvider<List<Student>>((ref) {
  return ref.watch(adminServiceProvider).watchStudents();
});

final teachersStreamProvider = StreamProvider<List<Teacher>>((ref) {
  return ref.watch(adminServiceProvider).watchTeachers();
});

final adminStatsProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(adminServiceProvider).getStats();
});

// Search filter state
final studentSearchProvider = StateProvider<String>((ref) => '');
final teacherSearchProvider = StateProvider<String>((ref) => '');

// Filtered lists
final filteredStudentsProvider = Provider<AsyncValue<List<Student>>>((ref) {
  final students = ref.watch(studentsStreamProvider);
  final query = ref.watch(studentSearchProvider).toLowerCase();
  return students.whenData(
    (list) => query.isEmpty
        ? list
        : list
              .where(
                (s) =>
                    s.name.toLowerCase().contains(query) ||
                    s.className.toLowerCase().contains(query),
              )
              .toList(),
  );
});

final filteredTeachersProvider = Provider<AsyncValue<List<Teacher>>>((ref) {
  final teachers = ref.watch(teachersStreamProvider);
  final query = ref.watch(teacherSearchProvider).toLowerCase();
  return teachers.whenData(
    (list) => query.isEmpty
        ? list
        : list
              .where(
                (t) =>
                    t.name.toLowerCase().contains(query) ||
                    t.email.toLowerCase().contains(query) ||
                    t.department.toLowerCase().contains(query),
              )
              .toList(),
  );
});
