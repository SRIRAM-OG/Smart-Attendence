import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../models/course.dart';
import '../../services/admin_service.dart';

class ManageCoursesScreen extends StatefulWidget {
  const ManageCoursesScreen({super.key});

  @override
  State<ManageCoursesScreen> createState() => _ManageCoursesScreenState();
}

class _ManageCoursesScreenState extends State<ManageCoursesScreen> {
  final AdminService _adminService = AdminService();
  List<Course> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    try {
      final list = await _adminService.getCourses();
      setState(() {
        _courses = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddCourseDialog() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Course / Subject'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Course Code (e.g. CS401)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Course Name'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final depts = await _adminService.getDepartments();
                if (depts.isEmpty) throw 'Please create a department first';
                await _adminService.createCourse({
                  'code': codeController.text.trim().toUpperCase(),
                  'name': nameController.text.trim(),
                  'departmentId': depts[0]['id'],
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  _fetchCourses();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Create Course'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Courses'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCourseDialog,
        backgroundColor: AppTheme.primaryLight,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Course', style: TextStyle(color: Colors.white)),
      ).animate().scale(begin: const Offset(0, 0), duration: 500.ms, delay: 300.ms, curve: Curves.elasticOut),
      body: RefreshIndicator(
        onRefresh: _fetchCourses,
        child: _isLoading
            ? buildShimmerList(count: 8, cardHeight: 90)
            : _courses.isEmpty
                ? Center(child: const Text('No courses added yet.').animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _courses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                    itemBuilder: (context, index) {
                      final c = _courses[index];

                      return Tilt3DCard(
                        maxTilt: 0.03,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryLight, size: 24)
                                  .animate().scale(begin: const Offset(0, 0), duration: 400.ms, curve: Curves.elasticOut, delay: Duration(milliseconds: 200 + index * 50)),
                            ),
                            title: Text(
                              c.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            subtitle: Text(
                              '${c.code} • ${c.department ?? "CSE"}\n${c.totalEnrolled ?? 0} Students Enrolled • ${c.totalSessions ?? 0} Sessions',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: index * 60)).slideX(begin: 0.12, curve: Curves.easeOutCubic);
                    },
                  ),
      ),
    );
  }
}
