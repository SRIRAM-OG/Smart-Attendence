class Course {
  final String id;
  final String code;
  final String name;
  final String? department;
  final String? academicYear;
  final List<String> teachers;
  final int? totalEnrolled;
  final int? totalSessions;

  Course({
    required this.id,
    required this.code,
    required this.name,
    this.department,
    this.academicYear,
    this.teachers = const [],
    this.totalEnrolled,
    this.totalSessions,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    List<String> teachersList = [];
    if (json['teachers'] != null) {
      teachersList = List<String>.from(json['teachers']);
    }

    return Course(
      id: json['id'] ?? json['courseId'] ?? '',
      code: json['code'] ?? json['courseCode'] ?? '',
      name: json['name'] ?? json['courseName'] ?? '',
      department: json['department'] is Map ? json['department']['name'] : json['department']?.toString(),
      academicYear: json['academicYear'],
      teachers: teachersList,
      totalEnrolled: json['totalEnrolled'] ?? json['_count']?['enrollments'],
      totalSessions: json['totalSessions'] ?? json['_count']?['sessions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'department': department,
      'academicYear': academicYear,
      'teachers': teachers,
    };
  }
}
