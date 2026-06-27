import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sriwaap/admin/app_shell.dart';
import 'package:sriwaap/app_theme.dart';
import 'package:sriwaap/auth_provider.dart';
import 'package:sriwaap/student/class_summary_screen.dart';
import 'package:sriwaap/student/deed_report_screen.dart';
import 'package:sriwaap/student/leaderboard_screen.dart';
import 'package:sriwaap/user_model.dart';

class StudentHome extends ConsumerWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;
    final isStudentRole = user?.role == UserRole.student;

    final items = isStudentRole
        ? [
            // Students/parents: read-only
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
          ]
        : [
            // Teachers: full access
            const NavItem(
              label: 'Report Deed',
              icon: Icons.edit_note_outlined,
              page: ReportDeedScreen(),
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
      title: 'Student Module',
      accentColor: AppColors.studentColor,
      items: items,
    );
  }
}