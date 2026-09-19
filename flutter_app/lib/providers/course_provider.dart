import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/course.dart';
import '../services/api_service.dart';

class CourseProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Course> _courses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchStudentCourses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.dio.get(ApiConfig.studentCourses);
      final List list = response.data['data'] ?? [];
      _courses = list.map((j) => Course.fromJson(j)).toList();
    } catch (e) {
      _errorMessage = _api.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeacherCourses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.dio.get(ApiConfig.teacherCourses);
      final List list = response.data['data'] ?? [];
      _courses = list.map((j) => Course.fromJson(j)).toList();
    } catch (e) {
      _errorMessage = _api.getErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
