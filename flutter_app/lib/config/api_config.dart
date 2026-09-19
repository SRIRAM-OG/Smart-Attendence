import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Dynamically computes the base URL:
  /// - Web / Windows Desktop / macOS / Linux: http://localhost:3000/api
  /// - Android Emulator: http://10.0.2.2:3000/api
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:3000/api';
    }
  }

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String logout = '/auth/logout';

  // Student endpoints
  static const String studentProfile = '/students/profile';
  static const String studentCourses = '/students/courses';
  static const String studentAttendance = '/students/attendance';
  static const String studentPercentage = '/students/percentage';

  // Teacher endpoints
  static const String teacherProfile = '/teachers/profile';
  static const String teacherCourses = '/teachers/courses';
  static const String teacherSessions = '/teachers/sessions';

  // Attendance & QR endpoints
  static const String scanQr = '/attendance/scan';
  static const String createSession = '/attendance/sessions';
  static const String generateQr = '/attendance/sessions'; // + /:id/generate-qr
  static const String sessionRecords = '/attendance/sessions'; // + /:id/records
  static const String closeSession = '/attendance/sessions'; // + /:id/close
  static const String myHistory = '/attendance/my-history';
  static const String myPercentage = '/attendance/my-percentage';

  // Admin endpoints
  static const String adminDashboardStats = '/admin/dashboard-stats';
  static const String adminDepartments = '/admin/departments';
  static const String adminStudents = '/admin/students';
  static const String adminTeachers = '/admin/teachers';
  static const String adminCourses = '/admin/courses';
  static const String adminEnrollments = '/admin/enrollments';
  static const String adminAssignTeacher = '/admin/assign-teacher';
  static const String adminAuditLogs = '/admin/audit-logs';

  // Reports
  static const String reportStudent = '/reports/student';
  static const String reportCourse = '/reports/course';
  static const String reportLowAttendance = '/reports/low-attendance';
  static const String reportDaily = '/reports/daily';
}
