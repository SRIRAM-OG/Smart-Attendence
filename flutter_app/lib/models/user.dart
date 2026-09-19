class User {
  final String id;
  final String name;
  final String email;
  final String role; // STUDENT, TEACHER, ADMIN
  final String status;
  final StudentProfile? student;
  final TeacherProfile? teacher;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.student,
    this.teacher,
  });

  bool get isStudent => role == 'STUDENT';
  bool get isTeacher => role == 'TEACHER';
  bool get isAdmin => role == 'ADMIN';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'STUDENT',
      status: json['status'] ?? 'ACTIVE',
      student: json['student'] != null ? StudentProfile.fromJson(json['student']) : null,
      teacher: json['teacher'] != null ? TeacherProfile.fromJson(json['teacher']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
      'student': student?.toJson(),
      'teacher': teacher?.toJson(),
    };
  }
}

class StudentProfile {
  final String id;
  final String enrollmentNumber;
  final String departmentId;
  final String? departmentName;
  final int semester;
  final String section;

  StudentProfile({
    required this.id,
    required this.enrollmentNumber,
    required this.departmentId,
    this.departmentName,
    required this.semester,
    required this.section,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] ?? '',
      enrollmentNumber: json['enrollmentNumber'] ?? '',
      departmentId: json['departmentId'] ?? '',
      departmentName: json['department'] != null ? json['department']['name'] : null,
      semester: json['semester'] ?? 1,
      section: json['section'] ?? 'A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'enrollmentNumber': enrollmentNumber,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'semester': semester,
      'section': section,
    };
  }
}

class TeacherProfile {
  final String id;
  final String departmentId;
  final String? departmentName;

  TeacherProfile({
    required this.id,
    required this.departmentId,
    this.departmentName,
  });

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      id: json['id'] ?? '',
      departmentId: json['departmentId'] ?? '',
      departmentName: json['department'] != null ? json['department']['name'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'departmentId': departmentId,
      'departmentName': departmentName,
    };
  }
}
