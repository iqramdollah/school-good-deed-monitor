import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sriwaap/admin/admin_home.dart';
import 'package:sriwaap/auth_provider.dart';
import 'package:sriwaap/login_screen.dart';
import 'package:sriwaap/student/student_home.dart';
import 'package:sriwaap/teacher/teacher_home.dart';
import 'package:sriwaap/user_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoading = authState.isLoading;
      final onLogin = state.matchedLocation == '/login';

      if (isLoading) return null;
      if (!isLoggedIn && !onLogin) return '/login';
      if (isLoggedIn && onLogin) {
        final user = authState.value;
        if (user == null) return '/login';
        return _homeRouteForRole(user.role);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/student', builder: (_, __) => const StudentHome()),
      GoRoute(path: '/teacher', builder: (_, __) => const TeacherHome()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminHome()),
      GoRoute(path: '/management', builder: (_, __) => const ManagementHome()),
    ],
  );
});

String _homeRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.student:
      return '/student';
    case UserRole.teacher:
      return '/teacher';
    case UserRole.admin:
      return '/admin';
    case UserRole.management:
      return '/management';
  }
}
