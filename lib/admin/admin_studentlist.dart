import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sriwaap/admin/admin_provider.dart';
import 'package:sriwaap/app_theme.dart';
import 'package:sriwaap/constant.dart';
import 'package:sriwaap/user_model.dart';

class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final students = ref.watch(filteredStudentsProvider);
    final search = ref.watch(studentSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(
            title: 'Students',
            searchHint: 'Search by name or class...',
            searchValue: search,
            onSearch: (v) => ref.read(studentSearchProvider.notifier).state = v,
            onAdd: () => _showStudentDialog(context, ref),
            buttonColor: AppColors.studentColor,
          ),
          Expanded(
            child: students.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) => list.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No students found.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) =>
                          _StudentTile(student: list[i], ref: ref),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentDialog(
    BuildContext context,
    WidgetRef ref, {
    Student? existing,
  }) {
    showDialog(
      context: context,
      builder: (_) => _StudentDialog(existing: existing, ref: ref),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String searchHint;
  final String searchValue;
  final ValueChanged<String> onSearch;
  final VoidCallback onAdd;
  final Color buttonColor;

  const _Header({
    required this.title,
    required this.searchHint,
    required this.searchValue,
    required this.onSearch,
    required this.onAdd,
    required this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text('Add $title'),
                style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: searchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final Student student;
  final WidgetRef ref;
  const _StudentTile({required this.student, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: AppColors.studentColor.withOpacity(0.1),
        child: Text(
          student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.studentColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(student.name, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(
        student.className,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${student.totalPoints} pts',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 18),
            tooltip: 'Create / view login account',
            onPressed: () => _showAccountDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _StudentDialog(existing: student, ref: ref),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _showAccountDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: '123456');
    bool obscure = true;
    final studentId = student.id;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Account — ${student.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Student ID',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 16,
                        color: AppColors.studentColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          studentId,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Copy ID',
                        icon: const Icon(
                          Icons.copy,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: studentId));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Student ID copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                    helperText: 'Default: 123456',
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    final shareText =
                        'SRIWAAP Login Credentials\n'
                        '------------------------\n'
                        'Name: ${student.name}\n'
                        'Class: ${student.className}\n'
                        'Student ID: $studentId\n'
                        'Email: ${emailController.text.trim()}\n'
                        'Password: ${passwordController.text}\n'
                        '------------------------\n'
                        'Please change your password after first login.';
                    Clipboard.setData(ClipboardData(text: shareText));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Credentials copied — paste to share via WhatsApp or email',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('Copy credentials to share'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.studentColor,
              ),
              onPressed: () async {
                if (emailController.text.isEmpty) return;
                try {
                  await ref
                      .read(adminServiceProvider)
                      .addStudentAccount(
                        student.id,
                        emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Account created for ${student.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text('Delete ${student.name}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.read(adminServiceProvider).deleteStudent(student.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _StudentDialog extends ConsumerStatefulWidget {
  final Student? existing;
  final WidgetRef ref;
  const _StudentDialog({this.existing, required this.ref});

  @override
  ConsumerState<_StudentDialog> createState() => _StudentDialogState();
}

class _StudentDialogState extends ConsumerState<_StudentDialog> {
  late final TextEditingController _name;
  String? _selectedClass;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _selectedClass = widget.existing?.className;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.isEmpty || _selectedClass == null) return;
    setState(() => _loading = true);
    final service = ref.read(adminServiceProvider);
    if (widget.existing != null) {
      await service.updateStudent(
        widget.existing!.id,
        _name.text.trim(),
        _selectedClass!,
      );
    } else {
      await service.addStudent(_name.text.trim(), _selectedClass!);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Student' : 'New Student'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isEdit)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.studentColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: AppColors.studentColor,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A unique Student ID will be auto-generated. Use the account icon to set up login credentials.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (isEdit)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ID: ${widget.existing!.id}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  IconButton(
                    iconSize: 14,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.copy, color: AppColors.textMuted),
                    onPressed: () => Clipboard.setData(
                      ClipboardData(text: widget.existing!.id),
                    ),
                  ),
                ],
              ),
            ),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedClass,
            decoration: const InputDecoration(
              labelText: 'Class',
              prefixIcon: Icon(Icons.class_outlined),
            ),
            hint: const Text('Select class'),
            isExpanded: true,
            items: kClasses
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _selectedClass = v),
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
              : Text(isEdit ? 'Save' : 'Add Student'),
        ),
      ],
    );
  }
}
