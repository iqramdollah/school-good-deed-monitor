import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sriwaap/admin/admin_provider.dart';
import 'package:sriwaap/app_theme.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);
    final students = ref.watch(studentsStreamProvider);
    final teachers = ref.watch(teachersStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome back, Admin',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Stat cards row
          stats.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (data) => Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Total Students',
                    value: '${data["students"]}',
                    icon: Icons.people_rounded,
                    color: AppColors.studentColor,
                    subtitle: 'Enrolled this year',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    label: 'Total Teachers',
                    value: '${data["teachers"]}',
                    icon: Icons.school_rounded,
                    color: AppColors.teacherColor,
                    subtitle: 'Active staff',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Recent students
          Text(
            'Recent Students',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _RecentList(
            stream: students,
            emptyText: 'No students yet',
            itemBuilder: (context, index, list) {
              final s = list[index];
              return _RecentTile(
                avatar: s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                avatarColor: AppColors.studentColor,
                title: s.name,
                subtitle: s.className,
                trailing: '${s.totalPoints} pts',
                trailingColor: AppColors.primary,
              );
            },
          ),

          const SizedBox(height: 24),

          // Recent teachers
          Text(
            'Recent Teachers',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _RecentList(
            stream: teachers,
            emptyText: 'No teachers yet',
            itemBuilder: (context, index, list) {
              final t = list[index];
              return _RecentTile(
                avatar: t.name.isNotEmpty ? t.name[0].toUpperCase() : '?',
                avatarColor: AppColors.teacherColor,
                title: t.name,
                subtitle: t.department.isNotEmpty ? t.department : t.email,
                trailing: t.email,
                trailingColor: AppColors.textSecondary,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentList<T> extends StatelessWidget {
  final AsyncValue<List<T>> stream;
  final String emptyText;
  final Widget Function(BuildContext, int, List<T>) itemBuilder;

  const _RecentList({
    required this.stream,
    required this.emptyText,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: stream.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e'),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  emptyText,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          final preview = list.take(5).toList();
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: preview.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (ctx, i) => itemBuilder(ctx, i, preview),
          );
        },
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final String avatar;
  final Color avatarColor;
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;

  const _RecentTile({
    required this.avatar,
    required this.avatarColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: avatarColor.withOpacity(0.12),
        child: Text(
          avatar,
          style: TextStyle(color: avatarColor, fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      trailing: Text(
        trailing,
        style: TextStyle(
          color: trailingColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
