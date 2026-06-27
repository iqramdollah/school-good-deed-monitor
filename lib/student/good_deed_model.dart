class GoodDeedCategory {
  final String id;
  final String name;
  final int points;

  const GoodDeedCategory({
    required this.id,
    required this.name,
    required this.points,
  });
}

// Predefined categories matching the original Turquoise system
const List<GoodDeedCategory> kDeedCategories = [
  GoodDeedCategory(
    id: 'helping_classmates',
    name: 'Membantu Rakan Sekelas',
    points: 5,
  ),
  GoodDeedCategory(id: 'extracurricular', name: 'Ekstrakurikuler', points: 5),
  GoodDeedCategory(id: 'academic', name: 'Kajian / Akademik', points: 10),
  GoodDeedCategory(id: 'salam', name: 'Salam & Adab', points: 5),
  GoodDeedCategory(id: 'cleanliness', name: 'Kebersihan', points: 5),
  GoodDeedCategory(id: 'punctuality', name: 'Ketepatan Masa', points: 5),
  GoodDeedCategory(id: 'leadership', name: 'Kepimpinan', points: 10),
  GoodDeedCategory(id: 'charity', name: 'Amalan Amal', points: 10),
];

class GoodDeed {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String categoryId;
  final String categoryName;
  final int points;
  final String remarks;
  final DateTime date;
  final String reportedBy; // teacher uid

  const GoodDeed({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.categoryId,
    required this.categoryName,
    required this.points,
    required this.remarks,
    required this.date,
    required this.reportedBy,
  });

  factory GoodDeed.fromFirestore(Map<String, dynamic> data, String id) {
    return GoodDeed(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      className: data['className'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      points: data['points'] ?? 0,
      remarks: data['remarks'] ?? '',
      date: (data['date'] as dynamic)?.toDate() ?? DateTime.now(),
      reportedBy: data['reportedBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'studentId': studentId,
    'studentName': studentName,
    'className': className,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'points': points,
    'remarks': remarks,
    'date': date,
    'reportedBy': reportedBy,
  };
}
