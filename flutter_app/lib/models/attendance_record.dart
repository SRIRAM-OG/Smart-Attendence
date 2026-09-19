class AttendanceRecord {
  final String id;
  final String? sessionId;
  final String? studentId;
  final String? studentName;
  final String? enrollmentNumber;
  final String? courseCode;
  final String? courseName;
  final DateTime timestamp;
  final String status; // PRESENT, ABSENT, LATE
  final String authMethod;

  AttendanceRecord({
    required this.id,
    this.sessionId,
    this.studentId,
    this.studentName,
    this.enrollmentNumber,
    this.courseCode,
    this.courseName,
    required this.timestamp,
    required this.status,
    this.authMethod = 'QR_SCAN',
  });

  bool get isPresent => status == 'PRESENT';
  bool get isAbsent => status == 'ABSENT';
  bool get isLate => status == 'LATE';

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? '',
      sessionId: json['sessionId'],
      studentId: json['studentId'],
      studentName: json['student']?['user']?['name'] ?? json['studentName'],
      enrollmentNumber: json['student']?['enrollmentNumber'] ?? json['enrollmentNumber'],
      courseCode: json['session']?['course']?['code'] ?? json['courseCode'],
      courseName: json['session']?['course']?['name'] ?? json['courseName'],
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      status: json['status'] ?? 'PRESENT',
      authMethod: json['authMethod'] ?? 'QR_SCAN',
    );
  }
}
