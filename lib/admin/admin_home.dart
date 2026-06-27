import 'package:flutter/material.dart';
import 'package:sriwaap/admin/admin_dashboard.dart';
import 'package:sriwaap/admin/admin_studentlist.dart';
import 'package:sriwaap/admin/admin_teacherlist.dart';
import 'package:sriwaap/admin/annual_update.dart';
import 'package:sriwaap/admin/app_shell.dart';
import 'package:sriwaap/app_theme.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Admin',
      accentColor: AppColors.adminColor,
      items: const [
        NavItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          page: AdminDashboard(),
        ),
        NavItem(
          label: 'Students',
          icon: Icons.people_outlined,
          page: StudentListScreen(),
        ),
        NavItem(
          label: 'Teachers',
          icon: Icons.person_outlined,
          page: TeacherListScreen(),
        ),
        NavItem(
          label: 'Annual Update',
          icon: Icons.update_outlined,
          page: AnnualUpdateScreen(),
        ),
      ],
    );
  }
}
