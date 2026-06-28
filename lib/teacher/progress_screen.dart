import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sriwaap/app_theme.dart';
import 'package:sriwaap/auth_provider.dart';
import 'package:sriwaap/teacher/teacher_model.dart';
import 'package:sriwaap/teacher/teacher_provider.dart';
import 'package:sriwaap/user_model.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).value;
    final isManagement = user?.role == UserRole.management;

    // Management sees a teacher picker + that teacher's progress
    // Teacher sees their own progress
    if (isManagement) {
      return const _ManagementProgressView();
    }
    return const _MyProgressView();
  }
}

// ─── Management view: pick a teacher, see their progress ─────────────────────

class _ManagementProgressView extends ConsumerWidget {
  const _ManagementProgressView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearProvider);
    final teachersAsync = ref.watch(teachersListProvider);
    final selectedId = ref.watch(selectedTeacherIdProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teacher Progress',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'View monthly self-evaluation scores for $year.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _YearSelector(year: year),
                ],
              ),
              const SizedBox(height: 14),
              teachersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
                data: (teachers) => DropdownButtonFormField<String>(
                  value: selectedId.isEmpty ? null : selectedId,
                  decoration: const InputDecoration(
                    labelText: 'Select Teacher',
                    isDense: true,
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  hint: const Text('Choose a teacher to view progress'),
                  items: teachers
                      .map(
                        (t) => DropdownMenuItem(
                          value: t['id'],
                          child: Text(
                            '${t['name']}${t['department']!.isNotEmpty ? ' • ${t['department']}' : ''}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (id) {
                    if (id != null) {
                      ref.read(selectedTeacherIdProvider.notifier).state = id;
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: selectedId.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_search_outlined,
                        size: 56,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select a teacher above to view their progress.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              : _ProgressContent(
                  progressAsync: ref.watch(
                    teacherProgressProvider((
                      teacherId: selectedId,
                      year: year,
                    )),
                  ),
                  evalsAsync: ref.watch(
                    teacherSelfEvalsProvider((
                      teacherId: selectedId,
                      year: year,
                    )),
                  ),
                  year: year,
                ),
        ),
      ],
    );
  }
}

// ─── Teacher's own progress view ─────────────────────────────────────────────

class _MyProgressView extends ConsumerWidget {
  const _MyProgressView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearProvider);
    final progressAsync = ref.watch(selfEvalProgressProvider(year));
    final evalsAsync = ref.watch(selfEvalsProvider(year));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Progress',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Monthly self-evaluation scores for $year.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              _YearSelector(year: year),
            ],
          ),
        ),
        Expanded(
          child: _ProgressContent(
            progressAsync: progressAsync,
            evalsAsync: evalsAsync,
            year: year,
          ),
        ),
      ],
    );
  }
}

// ─── Shared progress content ──────────────────────────────────────────────────

class _ProgressContent extends StatelessWidget {
  final AsyncValue<Map<int, double>> progressAsync;
  final AsyncValue<List<SelfEvaluation>> evalsAsync;
  final int year;

  const _ProgressContent({
    required this.progressAsync,
    required this.evalsAsync,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return progressAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (monthlyScores) {
        if (monthlyScores.isEmpty) return _NoData(year: year);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BarChart(monthlyScores: monthlyScores, year: year),
              const SizedBox(height: 24),
              _StatsRow(monthlyScores: monthlyScores),
              const SizedBox(height: 24),
              Text(
                'Monthly Breakdown',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              evalsAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (evals) => Column(
                  children: evals.map((e) => _EvalRow(eval: e)).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Bar chart ────────────────────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final Map<int, double> monthlyScores;
  final int year;

  const _BarChart({required this.monthlyScores, required this.year});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score by Month',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (i) {
                final month = i + 1;
                final score = monthlyScores[month];
                final barHeight = score != null ? (score / 5) * 100 : 0.0;
                final hasScore = score != null;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasScore)
                          Text(
                            score.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teacherColor,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Container(
                          height: hasScore ? barHeight : 4,
                          decoration: BoxDecoration(
                            color: hasScore
                                ? AppColors.teacherColor
                                : AppColors.divider,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kMonthNames[i].substring(0, 3),
                          style: TextStyle(
                            fontSize: 9,
                            color: hasScore
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Map<int, double> monthlyScores;
  const _StatsRow({required this.monthlyScores});

  @override
  Widget build(BuildContext context) {
    final scores = monthlyScores.values.toList();
    final avg = scores.fold(0.0, (a, b) => a + b) / scores.length;
    final best = scores.reduce((a, b) => a > b ? a : b);
    final submitted = scores.length;

    return Row(
      children: [
        _StatCard(
          label: 'Submitted',
          value: '$submitted / 12',
          icon: Icons.check_circle_outline,
          color: AppColors.teacherColor,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Avg Score',
          value: avg.toStringAsFixed(2),
          icon: Icons.bar_chart_outlined,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Best Month',
          value: best.toStringAsFixed(1),
          icon: Icons.star_outline,
          color: AppColors.accent,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Eval row ─────────────────────────────────────────────────────────────────

class _EvalRow extends StatelessWidget {
  final SelfEvaluation eval;
  const _EvalRow({required this.eval});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.teacherColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                kMonthNames[eval.month - 1].substring(0, 3),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teacherColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${kMonthNames[eval.month - 1]} ${eval.year}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (eval.remarks.isNotEmpty)
                  Text(
                    eval.remarks,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.teacherColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              eval.averageScore.toStringAsFixed(1),
              style: TextStyle(
                color: AppColors.teacherColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _NoData extends StatelessWidget {
  final int year;
  const _NoData({required this.year});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bar_chart_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No evaluations submitted for $year.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Monthly self-evaluations will appear here once submitted.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Year selector ────────────────────────────────────────────────────────────

class _YearSelector extends ConsumerWidget {
  final int year;
  const _YearSelector({required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = DateTime.now().year;
    return DropdownButton<int>(
      value: year,
      underline: const SizedBox(),
      items: List.generate(
        3,
        (i) => current - i,
      ).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
      onChanged: (y) {
        if (y != null) ref.read(selectedYearProvider.notifier).state = y;
      },
    );
  }
}
