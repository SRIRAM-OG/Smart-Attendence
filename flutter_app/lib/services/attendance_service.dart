import '../config/api_config.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import 'api_service.dart';

class AttendanceService {
  final ApiService _api = ApiService();

  /// Student scans QR code and marks attendance
  Future<Map<String, dynamic>> scanQr({
    required String sessionId,
    required String token,
    String authMethod = 'QR_SCAN',
  }) async {
    try {
      final response = await _api.dio.post(
        ApiConfig.scanQr,
        data: {
          'sessionId': sessionId,
          'token': token,
          'authMethod': authMethod,
        },
      );

      return {
        'message': response.data['message'] ?? 'Attendance marked successfully!',
        'record': AttendanceRecord.fromJson(response.data['data']),
      };
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  /// Student fetches their attendance history
  Future<List<AttendanceRecord>> getMyHistory({String? courseId}) async {
    try {
      final queryParams = courseId != null ? {'courseId': courseId} : null;
      final response = await _api.dio.get(
        ApiConfig.myHistory,
        queryParameters: queryParams,
      );

      final List recordsJson = response.data['data'] ?? [];
      return recordsJson.map((j) => AttendanceRecord.fromJson(j)).toList();
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  /// Student fetches their calculated percentage summary
  Future<Map<String, dynamic>> getMyPercentage() async {
    try {
      final response = await _api.dio.get(ApiConfig.myPercentage);
      return response.data['data'];
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  /// Teacher creates a new attendance session
  Future<Map<String, dynamic>> createSession({
    required String courseId,
    DateTime? sessionDate,
    int expiryMinutes = 5,
  }) async {
    try {
      final response = await _api.dio.post(
        ApiConfig.createSession,
        data: {
          'courseId': courseId,
          'sessionDate': (sessionDate ?? DateTime.now()).toIso8601String(),
          'expiryMinutes': expiryMinutes,
        },
      );

      final data = response.data['data'];
      return {
        'session': AttendanceSession.fromJson(data['session']),
        'qrPayload': data['qrPayload'],
        'expiresAt': DateTime.parse(data['expiresAt']),
      };
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  /// Teacher regenerates QR code for session
  Future<Map<String, dynamic>> generateQr({
    required String sessionId,
    int expiryMinutes = 5,
  }) async {
    try {
      final response = await _api.dio.post(
        '${ApiConfig.generateQr}/$sessionId/generate-qr',
        data: {'expiryMinutes': expiryMinutes},
      );

      final data = response.data['data'];
      return {
        'session': AttendanceSession.fromJson(data['session']),
        'qrPayload': data['qrPayload'],
        'expiresAt': DateTime.parse(data['expiresAt']),
      };
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  /// Teacher fetches live attendance list for a session
  Future<Map<String, dynamic>> getSessionRecords(String sessionId) async {
    try {
      final response = await _api.dio.get('${ApiConfig.sessionRecords}/$sessionId/records');
      final data = response.data['data'];

      final List recordsJson = data['records'] ?? [];
      final records = recordsJson.map((j) => AttendanceRecord.fromJson(j)).toList();

      return {
        'session': AttendanceSession.fromJson(data['session']),
        'totalEnrolled': data['totalEnrolled'] ?? 0,
        'totalPresent': data['totalPresent'] ?? 0,
        'attendancePercentage': data['attendancePercentage'] ?? 0,
        'records': records,
      };
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  /// Teacher closes an active session
  Future<void> closeSession(String sessionId) async {
    try {
      await _api.dio.patch('${ApiConfig.closeSession}/$sessionId/close');
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }
}
