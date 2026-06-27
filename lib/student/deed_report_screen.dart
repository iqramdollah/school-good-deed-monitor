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
    if (mounted) {
      setState(() {
        _submitted = false;
        _selectedStudent = null;
        _selectedCategory = null;
        _remarksController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Good Deed',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Record a student\'s good deed and award points.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),

          // Step 1 — Select Class
          _StepLabel(number: '1', label: 'Select Class'),
          const SizedBox(height: 8),
          classesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (classes) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: classes
                  .map(
                    (c) => ChoiceChip(
                      label: Text(c),
                      selected: _selectedClass == c,
                      onSelected: (_) => setState(() {
                        _selectedClass = c;
                        _selectedStudent = null;
                      }),
                      selectedColor: AppColors.primary.withOpacity(0.15),
                    ),
                  )
                  .toList(),
            ),
          ),

          if (_selectedClass != null) ...[
            const SizedBox(height: 24),

            // Step 2 — Select Student
            _StepLabel(number: '2', label: 'Select Student'),
            const SizedBox(height: 8),
            ref
                .watch(studentsByClassProvider(_selectedClass!))
                .when(
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                  data: (students) => students.isEmpty
                      ? Text(
                          'No students in $_selectedClass.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: students
                              .map(
                                (s) => ChoiceChip(
                                  label: Text(s.name),
                                  selected: _selectedStudent?.id == s.id,
                                  onSelected: (_) =>
                                      setState(() => _selectedStudent = s),
                                  selectedColor: AppColors.studentColor
                                      .withOpacity(0.15),
                                ),
                              )
                              .toList(),
                        ),
                ),
          ],

          if (_selectedStudent != null) ...[
            const SizedBox(height: 24),

            // Step 3 — Select Category
            _StepLabel(number: '3', label: 'Good Deed Category'),
            const SizedBox(height: 8),
            ...kDeedCategories.map(
              (cat) => _CategoryTile(
                category: cat,
                selected: _selectedCategory?.id == cat.id,
                onTap: () => setState(() => _selectedCategory = cat),
              ),
            ),
          ],

          if (_selectedCategory != null) ...[
            const SizedBox(height: 24),

            // Step 4 — Remarks (optional)
            _StepLabel(number: '4', label: 'Remarks (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add a note about this good deed...',
              ),
            ),
            const SizedBox(height: 24),

            // Summary card
            _SummaryCard(
              student: _selectedStudent!,
              category: _selectedCategory!,
            ),
            const SizedBox(height: 20),

            // Submit
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
                  label: Text('Submit (+${_selectedCategory!.points} pts)'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String number;
  final String label;
  const _StepLabel({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
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

class _CategoryTile extends StatelessWidget {
  final GoodDeedCategory category;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                category.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${category.points} pts',
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
  }
}

class _SummaryCard extends StatelessWidget {
  final Student student;
  final GoodDeedCategory category;
  const _SummaryCard({required this.student, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          _Row('Student', student.name),
          _Row('Class', student.className),
          _Row('Good Deed', category.name),
          _Row('Points', '+${category.points}'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
