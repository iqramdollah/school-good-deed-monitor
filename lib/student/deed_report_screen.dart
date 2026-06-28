import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sriwaap/app_theme.dart';
import 'package:sriwaap/student/good_deed_model.dart';
import 'package:sriwaap/student/student_provider.dart';
import 'package:sriwaap/user_model.dart';

class ReportDeedScreen extends ConsumerStatefulWidget {
  const ReportDeedScreen({super.key});

  @override
  ConsumerState<ReportDeedScreen> createState() => _ReportDeedScreenState();
}

class _ReportDeedScreenState extends ConsumerState<ReportDeedScreen> {
  String? _selectedClass;
  Student? _selectedStudent;
  GoodDeedCategory? _selectedCategory;
  final _remarksController = TextEditingController();
  bool _loading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _submitted = false;
      _selectedStudent = null;
      _selectedCategory = null;
      _remarksController.clear();
    });
  }

  Future<void> _submit() async {
    if (_selectedStudent == null || _selectedCategory == null) return;
    setState(() => _loading = true);
    await ref
        .read(studentServiceProvider)
        .reportGoodDeed(
          student: _selectedStudent!,
          category: _selectedCategory!,
          remarks: _remarksController.text.trim(),
        );
    setState(() {
      _loading = false;
      _submitted = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) _reset();
  }

  @override
  Widget build(BuildContext context) {
    final classes = ref.watch(classesProvider);

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
                      'Report Good Deed',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Record a student\'s good deed and award points.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              // Reset button
              if (_selectedClass != null)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _selectedClass = null;
                    _selectedStudent = null;
                    _selectedCategory = null;
                    _remarksController.clear();
                  }),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                ),
            ],
          ),
        ),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left panel — class + student picker
              Container(
                width: 220,
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: AppColors.divider)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Class picker
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Class',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: classes.map((c) {
                          final selected = _selectedClass == c;
                          return InkWell(
                            onTap: () => setState(() {
                              _selectedClass = c;
                              _selectedStudent = null;
                              _selectedCategory = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              color: selected
                                  ? AppColors.primary.withOpacity(0.08)
                                  : null,
                              child: Row(
                                children: [
                                  if (selected)
                                    const Icon(
                                      Icons.chevron_right,
                                      size: 16,
                                      color: AppColors.primary,
                                    )
                                  else
                                    const SizedBox(width: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      c,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: selected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Right panel — student + category + submit
              Expanded(
                child: _selectedClass == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.class_outlined,
                              size: 48,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Select a class to get started',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Step 1 — Student
                            _SectionTitle(number: '1', label: 'Select Student'),
                            const SizedBox(height: 10),
                            ref
                                .watch(studentsByClassProvider(_selectedClass!))
                                .when(
                                  loading: () =>
                                      const CircularProgressIndicator(),
                                  error: (e, _) => Text('Error: $e'),
                                  data: (students) => students.isEmpty
                                      ? Text(
                                          'No students in $_selectedClass.',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        )
                                      : Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: students.map((s) {
                                            final sel =
                                                _selectedStudent?.id == s.id;
                                            return ChoiceChip(
                                              label: Text(s.name),
                                              selected: sel,
                                              onSelected: (_) => setState(() {
                                                _selectedStudent = s;
                                                _selectedCategory = null;
                                              }),
                                              selectedColor: AppColors
                                                  .studentColor
                                                  .withOpacity(0.15),
                                            );
                                          }).toList(),
                                        ),
                                ),

                            if (_selectedStudent != null) ...[
                              const SizedBox(height: 24),
                              _SectionTitle(
                                number: '2',
                                label: 'Good Deed Category',
                              ),
                              const SizedBox(height: 10),
                              ...kDeedCategories.map((cat) {
                                final sel = _selectedCategory?.id == cat.id;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedCategory = cat),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppColors.primary.withOpacity(0.08)
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: sel
                                            ? AppColors.primary
                                            : AppColors.divider,
                                        width: sel ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            cat.name,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: sel
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            '+${cat.points} pts',
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],

                            if (_selectedCategory != null) ...[
                              const SizedBox(height: 24),
                              _SectionTitle(
                                number: '3',
                                label: 'Remarks (optional)',
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _remarksController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Add a note about this good deed...',
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Summary
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedStudent!.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            _selectedClass!,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedCategory!.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '+${_selectedCategory!.points} pts',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Submit button
                              if (_submitted)
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.green.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade600,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Good deed recorded! +${_selectedCategory!.points} pts',
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
                                        : const Icon(Icons.check),
                                    label: Text(
                                      'Submit (+${_selectedCategory!.points} pts)',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String number;
  final String label;
  const _SectionTitle({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
