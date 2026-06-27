// ─── Evaluation Category ──────────────────────────────────────────────────────
// Matches the DB schema: T&L, SchoolProgramme, Tarbiyyah, Self-improvement,
// ExternalEngagement, WelfareActivity
enum EvalCategory {
  tandl,
  schoolProgramme,
  tarbiyyah,
  selfImprovement,
  externalEngagement,
  welfareActivity;

  String get label {
    switch (this) {
      case EvalCategory.tandl:
        return 'Teaching & Learning (T&L)';
      case EvalCategory.schoolProgramme:
        return 'School Programme';
      case EvalCategory.tarbiyyah:
        return 'Tarbiyyah';
      case EvalCategory.selfImprovement:
        return 'Self-Improvement';
      case EvalCategory.externalEngagement:
        return 'External Engagement';
      case EvalCategory.welfareActivity:
        return 'Welfare Activity';
    }
  }

  String get firestoreKey {
    switch (this) {
      case EvalCategory.tandl:
        return 'tandl';
      case EvalCategory.schoolProgramme:
        return 'schoolProgramme';
      case EvalCategory.tarbiyyah:
        return 'tarbiyyah';
      case EvalCategory.selfImprovement:
        return 'selfImprovement';
      case EvalCategory.externalEngagement:
        return 'externalEngagement';
      case EvalCategory.welfareActivity:
        return 'welfareActivity';
    }
  }

  // Weight % shown next to each category (for display purposes)
  int get weightPercent {
    switch (this) {
      case EvalCategory.tandl:
        return 40;
      case EvalCategory.schoolProgramme:
        return 15;
      case EvalCategory.tarbiyyah:
        return 20;
      case EvalCategory.selfImprovement:
        return 10;
      case EvalCategory.externalEngagement:
        return 10;
      case EvalCategory.welfareActivity:
        return 5;
    }
  }
}

// ─── Annual Goal ──────────────────────────────────────────────────────────────
class AnnualGoal {
  final String id;
  final String teacherId;
  final int year;
  final EvalCategory category;
  final String goalText;
  final DateTime createdAt;

  const AnnualGoal({
    required this.id,
    required this.teacherId,
    required this.year,
    required this.category,
    required this.goalText,
    required this.createdAt,
  });

  factory AnnualGoal.fromFirestore(Map<String, dynamic> data, String id) {
    return AnnualGoal(
      id: id,
      teacherId: data['teacherId'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      category: EvalCategory.values.firstWhere(
        (e) => e.firestoreKey == data['category'],
        orElse: () => EvalCategory.tandl,
      ),
      goalText: data['goalText'] ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'teacherId': teacherId,
    'year': year,
    'category': category.firestoreKey,
    'goalText': goalText,
    'createdAt': createdAt,
  };
}

// ─── Self Evaluation (Monthly) ────────────────────────────────────────────────
class SelfEvaluation {
  final String id;
  final String teacherId;
  final int year;
  final int month;
  final String remarks;
  final Map<EvalCategory, int> scores; // 1-5 per category
  final DateTime submittedAt;

  const SelfEvaluation({
    required this.id,
    required this.teacherId,
    required this.year,
    required this.month,
    required this.remarks,
    required this.scores,
    required this.submittedAt,
  });

  double get averageScore {
    if (scores.isEmpty) return 0;
    return scores.values.fold(0, (a, b) => a + b) / scores.length;
  }

  factory SelfEvaluation.fromFirestore(Map<String, dynamic> data, String id) {
    final rawScores = data['scores'] as Map<String, dynamic>? ?? {};
    final scores = <EvalCategory, int>{};
    for (final cat in EvalCategory.values) {
      scores[cat] = (rawScores[cat.firestoreKey] as num?)?.toInt() ?? 0;
    }
    return SelfEvaluation(
      id: id,
      teacherId: data['teacherId'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      month: data['month'] ?? 1,
      remarks: data['remarks'] ?? '',
      scores: scores,
      submittedAt: (data['submittedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'teacherId': teacherId,
    'year': year,
    'month': month,
    'remarks': remarks,
    'scores': {for (final e in scores.entries) e.key.firestoreKey: e.value},
    'submittedAt': submittedAt,
  };
}

// ─── Teacher Evaluation (Annual — done by management) ────────────────────────
class TeacherEvaluation {
  final String id;
  final String teacherId;
  final String evaluatorId; // management uid
  final String evaluatorName;
  final int year;
  final String remarks;
  final Map<EvalCategory, int> scores;
  final int pointGap; // gap vs teacher's own self-eval average
  final DateTime submittedAt;

  const TeacherEvaluation({
    required this.id,
    required this.teacherId,
    required this.evaluatorId,
    required this.evaluatorName,
    required this.year,
    required this.remarks,
    required this.scores,
    required this.pointGap,
    required this.submittedAt,
  });

  double get averageScore {
    if (scores.isEmpty) return 0;
    return scores.values.fold(0, (a, b) => a + b) / scores.length;
  }

  factory TeacherEvaluation.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    final rawScores = data['scores'] as Map<String, dynamic>? ?? {};
    final scores = <EvalCategory, int>{};
    for (final cat in EvalCategory.values) {
      scores[cat] = (rawScores[cat.firestoreKey] as num?)?.toInt() ?? 0;
    }
    return TeacherEvaluation(
      id: id,
      teacherId: data['teacherId'] ?? '',
      evaluatorId: data['evaluatorId'] ?? '',
      evaluatorName: data['evaluatorName'] ?? '',
      year: data['year'] ?? DateTime.now().year,
      remarks: data['remarks'] ?? '',
      scores: scores,
      pointGap: (data['pointGap'] as num?)?.toInt() ?? 0,
      submittedAt: (data['submittedAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'teacherId': teacherId,
    'evaluatorId': evaluatorId,
    'evaluatorName': evaluatorName,
    'year': year,
    'remarks': remarks,
    'scores': {for (final e in scores.entries) e.key.firestoreKey: e.value},
    'pointGap': pointGap,
    'submittedAt': submittedAt,
  };
}

// ─── Month names helper ───────────────────────────────────────────────────────
const kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
