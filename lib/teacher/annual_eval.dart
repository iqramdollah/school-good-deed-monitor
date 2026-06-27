import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sriwaap/app_theme.dart';
import 'package:sriwaap/auth_provider.dart';
import 'package:sriwaap/teacher/eval_widget.dart';

import 'package:sriwaap/teacher/teacher_model.dart';
import 'package:sriwaap/teacher/teacher_provider.dart';

class AnnualEvalScreen extends ConsumerWidget {
  const AnnualEvalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearProvider);
    final teachersAsync = ref.watch(teachersListProvider);
    final selectedId = ref.watch(selectedTeacherIdProvider);

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
                          'Annual Evaluation',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Evaluate teacher character development for $year.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  _YearPicker(year: year),
                ],
              ),
              const SizedBox(height: 14),

              // Teacher picker
              teachersAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error loading teachers: $e'),
                data: (teachers) {
                  if (teachers.isEmpty) {
                    return const Text('No teachers registered yet.');
                  }
                  return DropdownButtonFormField<String>(
                    value: selectedId.isEmpty ? null : selectedId,
                    decoration: const InputDecoration(
                      labelText: 'Select Teacher',
                      isDense: true,
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    hint: const Text('Choose a teacher to evaluate'),
                    items: teachers
                        .map(
                          (t) => DropdownMenuItem(
                            value: t['id'],
                            child: Text('${t['name']} • ${t['department']}'),
                          ),
                        )
                        .toList(),
                    onChanged: (id) {
                      if (id != null) {
                        ref.read(selectedTeacherIdProvider.notifier).state = id;
                      }
                    },
                  );
                },
              ),
            ],
          ),
        ),

        // Eval content
        Expanded(
          child: selectedId.isEmpty
              ? _NoPick()
              : _TeacherEvalContent(teacherId: selectedId, year: year),
        ),
      ],
    );
  }
}

class _NoPick extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'Select a teacher above to view or submit their evaluation.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TeacherEvalContent extends ConsumerWidget {
  final String teacherId;
  final int year;

  const _TeacherEvalContent({required this.teacherId, required this.year});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evalAsync = ref.watch(
      teacherEvalProvider((teacherId: teacherId, year: year)),
    );

    return evalAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (eval) {
        if (eval != null) {
          return _EvalReadView(
            eval: eval,
            onEdit: () => _openForm(context, ref, eval),
          );
        }
        return _NoEval(onStart: () => _openForm(context, ref, null));
      },
    );
  }

  void _openForm(
    BuildContext context,
    WidgetRef ref,
    TeacherEvaluation? existing,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnnualEvalFormScreen(
          teacherId: teacherId,
          year: year,
          existing: existing,
        ),
      ),
    );
  }
}

// ─── No eval yet ──────────────────────────────────────────────────────────────

class _NoEval extends StatelessWidget {
  final VoidCallback onStart;
  const _NoEval({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No evaluation submitted for this year yet.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('Start Evaluation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.managementColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Read-only view of a submitted eval ───────────────────────────────────────

class _EvalReadView extends StatelessWidget {
  final TeacherEvaluation eval;
  final VoidCallback onEdit;

  const _EvalReadView({required this.eval, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          EvalSummaryCard(
            scores: eval.scores,
            accentColor: AppColors.managementColor,
          ),
          const SizedBox(height: 16),

          // Point gap chip
          Row(
            children: [
              const Icon(Icons.compare_arrows, size: 18),
              const SizedBox(width: 8),
              Text(
                'Point Gap vs Self-Evaluation:',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  '${eval.pointGap >= 0 ? '+' : ''}${eval.pointGap}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: eval.pointGap >= 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
                backgroundColor: eval.pointGap >= 0
                    ? Colors.green.shade50
                    : Colors.red.shade50,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category breakdown
          Text(
            'Detailed Scores',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...EvalCategory.values.map(
            (cat) => EvalCategoryRow(
              category: cat,
              score: eval.scores[cat] ?? 0,
              onChanged: (_) {},
              readOnly: true,
            ),
          ),

          // Remarks
          if (eval.remarks.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Remarks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                eval.remarks,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
          const SizedBox(height: 8),

          Text(
            'Evaluated by ${eval.evaluatorName} on '
            '${eval.submittedAt.day}/${eval.submittedAt.month}/${eval.submittedAt.year}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Evaluation'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Annual Eval Form ─────────────────────────────────────────────────────────

class AnnualEvalFormScreen extends ConsumerStatefulWidget {
  final String teacherId;
  final int year;
  final TeacherEvaluation? existing;

  const AnnualEvalFormScreen({
    super.key,
    required this.teacherId,
    required this.year,
    this.existing,
  });

  @override
  ConsumerState<AnnualEvalFormScreen> createState() =>
      _AnnualEvalFormScreenState();
}

class _AnnualEvalFormScreenState extends ConsumerState<AnnualEvalFormScreen> {
  late Map<EvalCategory, int> _scores;
  late final TextEditingController _remarks;
  bool _loading = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _scores = {
      for (final cat in EvalCategory.values)
        cat: widget.existing?.scores[cat] ?? 0,
    };
    _remarks = TextEditingController(text: widget.existing?.remarks ?? '');
  }

  @override
  void dispose() {
    _remarks.dispose();
    super.dispose();
  }

  bool get _allScored => _scores.values.every((s) => s > 0);

  Future<void> _submit() async {
    if (!_allScored) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please score all categories before submitting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _loading = true);

    final user = ref.read(authNotifierProvider).value;
    await ref
        .read(teacherServiceProvider)
        .submitTeacherEval(
          teacherId: widget.teacherId,
          evaluatorName: user?.name ?? 'Management',
          year: widget.year,
          scores: _scores,
          remarks: _remarks.text.trim(),
          existingId: widget.existing?.id,
        );
    setState(() {
      _loading = false;
      _submitted = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.year} Teacher Evaluation',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: AppColors.managementColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.managementColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.managementColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.managementColor,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Evaluate the teacher on a scale of 1–5 for each character development category.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Evaluation Scores',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            ...EvalCategory.values.map(
              (cat) => EvalCategoryRow(
                category: cat,
                score: _scores[cat] ?? 0,
                onChanged: (v) => setState(() => _scores[cat] = v),
              ),
            ),

            if (_allScored) ...[
              const SizedBox(height: 16),
              Text('Summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              EvalSummaryCard(
                scores: _scores,
                accentColor: AppColors.managementColor,
              ),
            ],

            const SizedBox(height: 16),
            Text('Remarks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _remarks,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Observations, commendations, areas for improvement...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            if (_submitted)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 10),
                    Text(
                      'Evaluation submitted!',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(isEdit ? Icons.save : Icons.send),
                  label: Text(
                    isEdit ? 'Update Evaluation' : 'Submit Evaluation',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.managementColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Year Picker ──────────────────────────────────────────────────────────────

class _YearPicker extends ConsumerWidget {
  final int year;
  const _YearPicker({required this.year});

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
