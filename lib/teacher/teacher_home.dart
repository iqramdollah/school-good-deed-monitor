import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sriwaap/admin/app_shell.dart';
import 'package:sriwaap/app_theme.dart';
import 'package:sriwaap/auth_provider.dart';
import 'package:sriwaap/teacher/annual_eval.dart';
import 'package:sriwaap/teacher/annual_goal.dart';
import 'package:sriwaap/teacher/progress_screen.dart';
import 'package:sriwaap/teacher/self_eval.dart';
import 'package:sriwaap/user_model.dart';
import 'package:sriwaap/student/deed_report_screen.dart';
import 'package:sriwaap/student/leaderboard_screen.dart';
import 'package:sriwaap/student/class_summary_screen.dart';

class TeacherHome extends ConsumerWidget {
  const TeacherHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;
    final isManagement = user?.role == UserRole.management;

    final items = isManagement
        ? [
            // Management only sees Evaluate and Progress
            const NavItem(
              label: 'Evaluate',
              icon: Icons.rate_review_outlined,
              page: AnnualEvalScreen(),
            ),
            const NavItem(
              label: 'Progress',
              icon: Icons.bar_chart_outlined,
              page: ProgressScreen(),
            ),
          ]
        : [
            // Teacher sees Goals, Self-Eval, Progress and Student Module
            const NavItem(
              label: 'Goals',
              icon: Icons.flag_outlined,
              page: AnnualGoalsScreen(),
            ),
            const NavItem(
              label: 'Self-Eval',
              icon: Icons.edit_note_outlined,
              page: SelfEvalScreen(),
            ),
            const NavItem(
              label: 'Progress',
              icon: Icons.bar_chart_outlined,
              page: ProgressScreen(),
            ),
            const NavItem(
              label: 'Report Deed',
              icon: Icons.edit_note_outlined,
              page: ReportDeedScreen(), // ✅ Just the page, no shell
            ),
            const NavItem(
              label: 'Leaderboard',
              icon: Icons.leaderboard_outlined,
              page: LeaderboardScreen(),
            ),
            const NavItem(
              label: 'Summary',
              icon: Icons.bar_chart_outlined,
              page: ClassSummaryScreen(),
            ),
          ];

    return AppShell(
      title: isManagement ? 'Teacher Evaluations' : 'Teacher Module',
      accentColor: isManagement
          ? AppColors.managementColor
          : AppColors.teacherColor,
      items: items,
    );
  }
}

/// Placeholder for management-specific home if needed.
/// Currently management is redirected to TeacherHome via router.
class ManagementHome extends ConsumerWidget {
  const ManagementHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Management can access everything a teacher can + annual eval
    return const TeacherHome();
  }
}
