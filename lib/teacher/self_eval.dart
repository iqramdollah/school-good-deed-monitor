import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sriwaap/app_theme.dart';
import 'package:sriwaap/teacher/eval_widget.dart';
import 'package:sriwaap/teacher/teacher_model.dart';
import 'package:sriwaap/teacher/teacher_provider.dart';

class SelfEvalScreen extends ConsumerWidget {
  const SelfEvalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedYearProvider);
    final evalsAsync = ref.watch(selfEvalsProvider(year));

    return Column(
      children: [
        // Header
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
                      'Monthly Self-Evaluation',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Track your character development each month.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              _YearSelector(year: year),
            ],
          ),
        ),

        // Month grid
        Expanded(
          child: evalsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (evals) {
              final evalsByMonth = {for (final e in evals) e.month: e};
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: 12,
                itemBuilder: (context, i) {
                  final month = i + 1;
                  final eval = evalsByMonth[month];
                  return _MonthCard(
                    month: month,
                    year: year,
                    eval: eval,
                    onTap: () => _openEvalForm(
                      context,
                      ref,
                      year: year,
                      month: month,
                      existing: eval,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _openEvalForm(
    BuildContext context,
    WidgetRef ref, {
    required int year,
    required int month,
    SelfEvaluation? existing,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SelfEvalFormScreen(year: year, month: month, existing: existing),
      ),
    );
  }
}

// ─── Month Card ───────────────────────────────────────────────────────────────

class _MonthCard extends StatelessWidget {
  final int month;
  final int year;
  final SelfEvaluation? eval;
  final VoidCallback onTap;

  const _MonthCard({
    required this.month,
    required this.year,
    required this.eval,
    required this.onTap,
  });

  bool get _isFuture {
    final now = DateTime.now();
    return DateTime(year, month).isAfter(DateTime(now.year, now.month));
  }

  @override
  Widget build(BuildContext context) {
    final submitted = eval != null;
    final future = _isFuture;

    Color cardColor;
    Color borderColor;
    if (submitted) {
      cardColor = AppColors.teacherColor.withOpacity(0.08);
      borderColor = AppColors.teacherColor.withOpacity(0.4);
    } else if (future) {
      cardColor = AppColors.surface;
      borderColor = AppColors.divider;
    } else {
      cardColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
    }

    return GestureDetector(
      onTap: future ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  submitted
                      ? Icons.check_circle
                      : future
                      ? Icons.lock_outline
                      : Icons.edit_note_outlined,
                  size: 18,
                  color: submitted
                      ? AppColors.teacherColor
                      : future
                      ? AppColors.textMuted
                      : Colors.orange.shade600,
                ),
                const Spacer(),
                if (submitted && eval != null)
                  Text(
                    eval!.averageScore.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.teacherColor,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              kMonthNames[month - 1],
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: future ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
            Text(
              submitted
                  ? 'Submitted'
                  : future
                  ? 'Not yet'
                  : 'Pending',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                color: submitted
                    ? AppColors.teacherColor
                    : future
                    ? AppColors.textMuted
                    : Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Year Selector ────────────────────────────────────────────────────────────

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

// ─── Self Eval Form Screen ────────────────────────────────────────────────────

class SelfEvalFormScreen extends ConsumerStatefulWidget {
  final int year;
  final int month;
  final SelfEvaluation? existing;

  const SelfEvalFormScreen({
    super.key,
    required this.year,
    required this.month,
    this.existing,
  });

  @override
  ConsumerState<SelfEvalFormScreen> createState() => _SelfEvalFormScreenState();
}

class _SelfEvalFormScreenState extends ConsumerState<SelfEvalFormScreen> {
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
    await ref
        .read(teacherServiceProvider)
        .submitSelfEval(
          year: widget.year,
          month: widget.month,
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
    final monthName = kMonthNames[widget.month - 1];
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$monthName ${widget.year} — Self-Evaluation',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: AppColors.teacherColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teacherColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.teacherColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.teacherColor,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Rate yourself 1 (needs improvement) to 5 (excellent) in each area.',
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

            // Category rows
            ...EvalCategory.values.map(
              (cat) => EvalCategoryRow(
                category: cat,
                score: _scores[cat] ?? 0,
                onChanged: (v) => setState(() => _scores[cat] = v),
              ),
            ),

            const SizedBox(height: 16),

            // Summary
            if (_allScored) ...[
              Text('Summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              EvalSummaryCard(
                scores: _scores,
                accentColor: AppColors.teacherColor,
              ),
              const SizedBox(height: 16),
            ],

            // Remarks
            Text('Remarks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _remarks,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText:
                    'Activities attended, achievements, challenges faced...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),

            // Submit / success
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
                    backgroundColor: AppColors.teacherColor,
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
