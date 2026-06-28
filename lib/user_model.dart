enum UserRole { student, teacher, admin, management }

// ─── Student data model ───────────────────────────────────────────────────────

class Student {
  final String id;
  final String name;
  final String ic; // ← add
  final String className;
  final int totalPoints;

  const Student({
    required this.id,
    required this.name,
    required this.ic, // ← add
    required this.className,
    required this.totalPoints,
  });

  factory Student.fromFirestore(Map<String, dynamic> data, String id) {
    return Student(
      id: id,
      name: data['name'] ?? '',
      ic: data['ic'] ?? '', // ← add
      className: data['className'] ?? '',
      totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'ic': ic, // ← add
    'className': className,
    'totalPoints': totalPoints,
  };
}

// ─── Teacher data model ───────────────────────────────────────────────────────

class Teacher {
  final String id;
  final String name;
  final String email;
  final String department;

  const Teacher({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
  });

  factory Teacher.fromFirestore(Map<String, dynamic> data, String id) {
    return Teacher(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      department: data['department'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'department': department,
  };
}

// ─── AppUser ──────────────────────────────────────────────────────────────────

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? studentId; // ← add this

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.studentId,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => UserRole.teacher,
      ),
      studentId: data['studentId'], // ← add this
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'role': role.name,
    if (studentId != null) 'studentId': studentId,
  };
}
