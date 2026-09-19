import 'dart:async';
import 'package:flutter/material.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _service = AttendanceService();

  // Student state
  List<AttendanceRecord> _history = [];
  Map<String, dynamic>? _percentageSummary;
  bool _isLoading = false;
  String? _errorMessage;

  // Teacher active session state
  AttendanceSession? _activeSession;
  String? _qrPayload;
  DateTime? _qrExpiresAt;
  List<AttendanceRecord> _sessionRecords = [];
  int _totalEnrolled = 0;
  int _totalPresent = 0;
  Timer? _pollingTimer;

  List<AttendanceRecord> get history => _history;
  Map<String, dynamic>? get percentageSummary => _percentageSummary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AttendanceSession? get activeSession => _activeSession;
  String? get qrPayload => _qrPayload;
  DateTime? get qrExpiresAt => _qrExpiresAt;
  List<AttendanceRecord> get sessionRecords => _sessionRecords;
  int get totalEnrolled => _totalEnrolled;
  int get totalPresent => _totalPresent;

  // ==================== STUDENT ACTIONS ====================

  Future<bool> scanQr(String sessionId, String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.scanQr(sessionId: sessionId, token: token);
      await fetchStudentData();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchStudentData({String? courseId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getMyHistory(courseId: courseId),
        _service.getMyPercentage(),
      ]);

      _history = results[0] as List<AttendanceRecord>;
      _percentageSummary = results[1] as Map<String, dynamic>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== TEACHER ACTIONS ====================

  Future<bool> createSession(String courseId, {int expiryMinutes = 5}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.createSession(
        courseId: courseId,
        expiryMinutes: expiryMinutes,
      );

      _activeSession = result['session'] as AttendanceSession;
      _qrPayload = result['qrPayload'] as String;
      _qrExpiresAt = result['expiresAt'] as DateTime;

      startLivePolling(_activeSession!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> regenerateQr({int expiryMinutes = 5}) async {
    if (_activeSession == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.generateQr(
        sessionId: _activeSession!.id,
        expiryMinutes: expiryMinutes,
      );

      _activeSession = result['session'] as AttendanceSession;
      _qrPayload = result['qrPayload'] as String;
      _qrExpiresAt = result['expiresAt'] as DateTime;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void startLivePolling(String sessionId) {
    stopLivePolling();
    fetchSessionRecords(sessionId);

    // Poll server every 4 seconds for live student check-ins
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      fetchSessionRecords(sessionId);
    });
  }

  void stopLivePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchSessionRecords(String sessionId) async {
    try {
      final result = await _service.getSessionRecords(sessionId);
      _activeSession = result['session'] as AttendanceSession;
      _sessionRecords = result['records'] as List<AttendanceRecord>;
      _totalEnrolled = result['totalEnrolled'] as int;
      _totalPresent = result['totalPresent'] as int;
      notifyListeners();
    } catch (_) {
      // Background poll failure handled silently
    }
  }

  Future<void> closeActiveSession() async {
    if (_activeSession == null) return;

    try {
      await _service.closeSession(_activeSession!.id);
      stopLivePolling();
      _activeSession = null;
      _qrPayload = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopLivePolling();
    super.dispose();
  }
}
