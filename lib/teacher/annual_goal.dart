import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sriwaap/app_theme.dart';
import 'package:sriwaap/teacher/teacher_model.dart';
import 'package:sriwaap/teacher/teacher_provider.dart';

class AnnualGoalsScreen extends ConsumerWidget {
  const AnnualGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearProvider);
    final goalsAsync = ref.watch(annualGoalsProvider(year));

    return Column(
      children: [
        // Header
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
                          'Annual Goals',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Set your character development targets for $year.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _YearPicker(year: year),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showGoalDialog(context, ref, year: year),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Goal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teacherColor,
                ),
              ),
            ],
          ),
        ),

        // Goals list
        Expanded(
          child: goalsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (goals) {
              if (goals.isEmpty) {
                return _EmptyGoals(
                  year: year,
                  onAdd: () => _showGoalDialog(context, ref, year: year),
                );
              }

              final completed = goals.where((g) => g.isCompleted).length;

              return Column(
                children: [
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Goals Progress',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              '$completed / ${goals.length} completed',
                              style: TextStyle(
                                color: AppColors.teacherColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: goals.isEmpty ? 0 : completed / goals.length,
                            minHeight: 8,
                            backgroundColor: AppColors.divider,
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.teacherColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: goals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _GoalCard(
                        goal: goals[i],
                        ref: ref,
                        onEdit: () => _showGoalDialog(
                          context,
                          ref,
                          year: year,
                          existing: goals[i],
                        ),
                        onDelete: () => _confirmDelete(context, ref, goals[i]),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showGoalDialog(
    BuildContext context,
    WidgetRef ref, {
    required int year,
    AnnualGoal? existing,
  }) {
    showDialog(
      context: context,
      builder: (_) => _GoalDialog(year: year, existing: existing, ref: ref),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, AnnualGoal goal) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Remove the goal for "${goal.category.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(teacherServiceProvider).deleteGoal(goal.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final AnnualGoal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final WidgetRef ref;

  const _GoalCard({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: goal.isCompleted ? Colors.green.shade50 : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: goal.isCompleted ? Colors.green.shade200 : AppColors.divider,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => ref
                .read(teacherServiceProvider)
                .toggleGoal(goal.id, !goal.isCompleted),
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: goal.isCompleted ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: goal.isCompleted ? Colors.green : AppColors.divider,
                  width: 2,
                ),
              ),
              child: goal.isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teacherColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${goal.category.weightPercent}% — ${goal.category.label}',
                    style: TextStyle(
                      color: AppColors.teacherColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  goal.goalText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: goal.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: goal.isCompleted
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
                if (goal.isCompleted) ...[
                  const SizedBox(height: 4),
                  Text(
                    '✓ Completed',
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  final int year;
  final VoidCallback onAdd;
  const _EmptyGoals({required this.year, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag_outlined, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No goals set for $year yet.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Add goals for each character development category.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add First Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teacherColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _YearPicker extends ConsumerWidget {
  final int year;
  const _YearPicker({required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentYear = DateTime.now().year;
    return DropdownButton<int>(
      value: year,
      underline: const SizedBox(),
      items: List.generate(
        3,
        (i) => currentYear - i,
      ).map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
      onChanged: (y) {
        if (y != null) ref.read(selectedYearProvider.notifier).state = y;
      },
    );
  }
}

// ─── Goal Dialog ──────────────────────────────────────────────────────────────

class _GoalDialog extends ConsumerStatefulWidget {
  final int year;
  final AnnualGoal? existing;
  final WidgetRef ref;

  const _GoalDialog({required this.year, this.existing, required this.ref});

  @override
  ConsumerState<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends ConsumerState<_GoalDialog> {
  late EvalCategory _category;
  late final TextEditingController _text;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _category = widget.existing?.category ?? EvalCategory.tandl;
    _text = TextEditingController(text: widget.existing?.goalText ?? '');
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_text.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await widget.ref
        .read(teacherServiceProvider)
        .saveGoal(
          year: widget.year,
          category: _category,
          goalText: _text.text.trim(),
          existingId: widget.existing?.id,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Goal' : 'New Goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          DropdownButtonFormField<EvalCategory>(
            value: _category,
            decoration: const InputDecoration(isDense: true),
            items: EvalCategory.values
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.label, style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
            onChanged: (c) {
              if (c != null) setState(() => _category = c);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Goal description',
              hintText:
                  'e.g. Achieve Band 5 in T&L assessments by end of year...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
