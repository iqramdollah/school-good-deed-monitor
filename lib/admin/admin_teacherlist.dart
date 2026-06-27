import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sriwaap/admin/admin_provider.dart';
import 'package:sriwaap/app_theme.dart';
import 'package:sriwaap/user_model.dart';

class TeacherListScreen extends ConsumerWidget {
  const TeacherListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachers = ref.watch(filteredTeachersProvider);
    final search = ref.watch(teacherSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _Header(
            title: 'Teachers',
            searchHint: 'Search by name, email or department...',
            searchValue: search,
            onSearch: (v) => ref.read(teacherSearchProvider.notifier).state = v,
            onAdd: () => showDialog(
              context: context,
              builder: (_) => _TeacherDialog(ref: ref),
            ),
            buttonColor: AppColors.teacherColor,
          ),
          Expanded(
            child: teachers.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (list) => list.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No teachers found.',
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
                          _TeacherTile(teacher: list[i], ref: ref),
                    ),
            ),
          ),
        ],
      ),
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

class _TeacherTile extends StatelessWidget {
  final Teacher teacher;
  final WidgetRef ref;
  const _TeacherTile({required this.teacher, required this.ref});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.teacherColor.withOpacity(0.1),
        child: Text(
          teacher.name.isNotEmpty ? teacher.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.teacherColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(teacher.name, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: Text(
        '${teacher.email}${teacher.department.isNotEmpty ? ' • ${teacher.department}' : ''}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: 'Edit',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _TeacherDialog(existing: teacher, ref: ref),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
            tooltip: 'Delete',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Remove Teacher'),
                content: Text(
                  'Delete ${teacher.name}? Their account will be deactivated.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      await ref
                          .read(adminServiceProvider)
                          .deleteTeacher(teacher.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherDialog extends ConsumerStatefulWidget {
  final Teacher? existing;
  final WidgetRef ref;
  const _TeacherDialog({this.existing, required this.ref});

  @override
  ConsumerState<_TeacherDialog> createState() => _TeacherDialogState();
}

class _TeacherDialogState extends ConsumerState<_TeacherDialog> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _dept;
  late final TextEditingController _password;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _email = TextEditingController(text: widget.existing?.email ?? '');
    _dept = TextEditingController(text: widget.existing?.department ?? '');
    _password = TextEditingController(text: '123456');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _dept.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.isEmpty) return;
    if (widget.existing == null &&
        (_email.text.isEmpty || _password.text.isEmpty))
      return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(adminServiceProvider);
      if (widget.existing != null) {
        await service.updateTeacher(
          widget.existing!.id,
          _name.text.trim(),
          _dept.text.trim(),
        );
      } else {
        await service.addTeacher(
          _name.text.trim(),
          _email.text.trim(),
          _dept.text.trim(),
          password: _password.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Teacher' : 'New Teacher'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dept,
              decoration: const InputDecoration(
                labelText: 'Department',
                prefixIcon: Icon(Icons.business_outlined),
              ),
            ),
            if (!isEdit) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Login password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  helperText: 'Teacher will use this to log in',
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teacherColor,
          ),
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
              : Text(isEdit ? 'Save' : 'Add Teacher'),
        ),
      ],
    );
  }
}
