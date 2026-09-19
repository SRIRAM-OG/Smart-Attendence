import '../config/api_config.dart';
import '../models/course.dart';
import 'api_service.dart';

class AdminService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _api.dio.get(ApiConfig.adminDashboardStats);
      return response.data['data'];
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  Future<List<Map<String, dynamic>>> getDepartments() async {
    try {
      final response = await _api.dio.get(ApiConfig.adminDepartments);
      final List list = response.data['data'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  Future<List<Map<String, dynamic>>> getStudents({String? search, String? departmentId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (departmentId != null) queryParams['departmentId'] = departmentId;

      final response = await _api.dio.get(
        ApiConfig.adminStudents,
        queryParameters: queryParams,
      );
      final List list = response.data['data'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  Future<void> createStudent(Map<String, dynamic> data) async {
    try {
      await _api.dio.post(ApiConfig.adminStudents, data: data);
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _api.dio.delete('${ApiConfig.adminStudents}/$id');
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  Future<List<Map<String, dynamic>>> getTeachers() async {
    try {
      final response = await _api.dio.get(ApiConfig.adminTeachers);
      final List list = response.data['data'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  Future<void> createTeacher(Map<String, dynamic> data) async {
    try {
      await _api.dio.post(ApiConfig.adminTeachers, data: data);
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  Future<List<Course>> getCourses() async {
    try {
      final response = await _api.dio.get(ApiConfig.adminCourses);
      final List list = response.data['data'] ?? [];
      return list.map((j) => Course.fromJson(j)).toList();
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  Future<void> createCourse(Map<String, dynamic> data) async {
    try {
      await _api.dio.post(ApiConfig.adminCourses, data: data);
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }

  Future<List<Map<String, dynamic>>> getLowAttendance({int threshold = 75}) async {
    try {
      final response = await _api.dio.get(
        ApiConfig.reportLowAttendance,
        queryParameters: {'threshold': threshold},
      );
      final List list = response.data['data'] ?? [];
      return List<Map<String, dynamic>>.from(list);
    } catch (e) {
      throw _api.getErrorMessage(e);
    }
  }
}
