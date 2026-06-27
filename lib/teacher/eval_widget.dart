import 'package:flutter/material.dart';
import 'package:sriwaap/app_theme.dart';
import 'package:sriwaap/teacher/teacher_model.dart';

/// A score slider row for one evaluation category (1–5 scale).
class EvalCategoryRow extends StatelessWidget {
  final EvalCategory category;
  final int score;
  final ValueChanged<int> onChanged;
  final bool readOnly;

  const EvalCategoryRow({
    super.key,
    required this.category,
    required this.score,
    required this.onChanged,
    this.readOnly = false,
  });

  Color _scoreColor(int s) {
    if (s <= 1) return Colors.red.shade400;
    if (s == 2) return Colors.orange.shade400;
    if (s == 3) return Colors.amber.shade600;
    if (s == 4) return Colors.lightGreen.shade600;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _scoreColor(score).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  score == 0 ? '—' : '$score / 5',
                  style: TextStyle(
                    color: score == 0
                        ? AppColors.textMuted
                        : _scoreColor(score),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  '${category.weightPercent}%',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: AppColors.primary.withOpacity(0.08),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ],
          ),
          if (!readOnly) ...[
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (i) {
                final val = i + 1;
                final selected = score == val;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(val),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 6,
                      ),
                      height: 36,
                      decoration: BoxDecoration(
                        color: selected
                            ? _scoreColor(val)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? _scoreColor(val)
                              : AppColors.divider,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$val',
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Needs improvement',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 10),
                  ),
                  Text(
                    'Excellent',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            // Read-only bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 5,
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(_scoreColor(score)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Summary card shown at the bottom of a completed eval form.
class EvalSummaryCard extends StatelessWidget {
  final Map<EvalCategory, int> scores;
  final Color accentColor;

  const EvalSummaryCard({
    super.key,
    required this.scores,
    required this.accentColor,
  });

  double get _avg {
    if (scores.isEmpty) return 0;
    return scores.values.fold(0, (a, b) => a + b) / scores.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average Score',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _avg.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'out of 5.0',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: EvalCategory.values.map((cat) {
                final s = scores[cat] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          cat.label,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$s/5',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
