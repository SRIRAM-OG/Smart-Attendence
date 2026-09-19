class AttendanceSession {
  final String id;
  final String courseId;
  final String courseCode;
  final String courseName;
  final String? teacherName;
  final DateTime sessionDate;
  final DateTime startTime;
  final DateTime? endTime;
  final String? qrToken;
  final DateTime? qrExpiresAt;
  final String status; // ACTIVE, EXPIRED, CLOSED
  final int totalPresent;

  AttendanceSession({
    required this.id,
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    this.teacherName,
    required this.sessionDate,
    required this.startTime,
    this.endTime,
    this.qrToken,
    this.qrExpiresAt,
    required this.status,
    this.totalPresent = 0,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isClosed => status == 'CLOSED';
  bool get isExpired => status == 'EXPIRED' || (qrExpiresAt != null && DateTime.now().isAfter(qrExpiresAt!));

  factory AttendanceSession.fromJson(Map<String, dynamic> json) {
    return AttendanceSession(
      id: json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      courseCode: json['courseCode'] ?? json['course']?['code'] ?? '',
      courseName: json['courseName'] ?? json['course']?['name'] ?? '',
      teacherName: json['teacherName'] ?? json['teacher']?['user']?['name'],
      sessionDate: json['sessionDate'] != null ? DateTime.parse(json['sessionDate']) : DateTime.now(),
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      qrToken: json['qrToken'],
      qrExpiresAt: json['qrExpiresAt'] != null ? DateTime.parse(json['qrExpiresAt']) : null,
      status: json['status'] ?? 'ACTIVE',
      totalPresent: json['totalPresent'] ?? json['_count']?['records'] ?? 0,
    );
  }
}
