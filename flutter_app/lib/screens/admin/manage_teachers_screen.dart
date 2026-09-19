import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../services/admin_service.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({super.key});

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _teachers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    setState(() => _isLoading = true);
    try {
      final list = await _adminService.getTeachers();
      setState(() {
        _teachers = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddTeacherDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(text: 'teacher123');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Faculty Member'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Faculty Name')),
              const SizedBox(height: 12),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Institutional Email')),
              const SizedBox(height: 12),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Default Password')),
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
                await _adminService.createTeacher({
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'password': passwordController.text,
                  'departmentId': depts[0]['id'],
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  _fetchTeachers();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Add Faculty'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Faculty'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTeacherDialog,
        backgroundColor: AppTheme.secondary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Add Faculty', style: TextStyle(color: Colors.white)),
      ).animate().scale(begin: const Offset(0, 0), duration: 500.ms, delay: 300.ms, curve: Curves.elasticOut),
      body: RefreshIndicator(
        onRefresh: _fetchTeachers,
        child: _isLoading
            ? buildShimmerList(count: 8, cardHeight: 80)
            : _teachers.isEmpty
                ? Center(child: const Text('No faculty members added yet.').animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _teachers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                    itemBuilder: (context, index) {
                      final t = _teachers[index];
                      final name = t['user']?['name'] ?? '';
                      final email = t['user']?['email'] ?? '';
                      final dept = t['department']?['name'] ?? 'CSE';
                      final courses = t['teacherCourses'] as List? ?? [];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.secondary.withOpacity(0.1),
                          child: Text(
                            name.isNotEmpty ? name.substring(0, 1) : 'T',
                            style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('$email\n$dept • ${courses.length} courses assigned'),
                      ).animate().fadeIn(delay: Duration(milliseconds: index * 60)).slideX(begin: 0.12, curve: Curves.easeOutCubic);
                    },
                  ),
      ),
    );
  }
}
