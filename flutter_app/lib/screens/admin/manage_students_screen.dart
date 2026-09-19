import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../services/admin_service.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents({String? search}) async {
    setState(() => _isLoading = true);
    try {
      final list = await _adminService.getStudents(search: search);
      setState(() {
        _students = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddStudentDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final enrollmentController = TextEditingController();
    final passwordController = TextEditingController(text: 'student123');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
              const SizedBox(height: 12),
              TextField(controller: enrollmentController, decoration: const InputDecoration(labelText: 'Enrollment No')),
              const SizedBox(height: 12),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email Address')),
              const SizedBox(height: 12),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password')),
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
                await _adminService.createStudent({
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'enrollmentNumber': enrollmentController.text.trim(),
                  'password': passwordController.text,
                  'departmentId': depts[0]['id'],
                  'semester': 1,
                  'section': 'A',
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  _fetchStudents();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Students'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Add Student', style: TextStyle(color: Colors.white)),
      ).animate().scale(begin: const Offset(0, 0), duration: 500.ms, delay: 300.ms, curve: Curves.elasticOut),
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or enrollment number...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    _fetchStudents();
                  },
                ),
              ),
              onSubmitted: (val) => _fetchStudents(search: val),
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.15),
          const Divider(height: 1, color: AppTheme.border),

          // Student List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchStudents(search: _searchController.text),
              child: _isLoading
                  ? buildShimmerList(count: 8, cardHeight: 80)
                  : _students.isEmpty
                      ? Center(child: const Text('No students found.').animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _students.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                          itemBuilder: (context, index) {
                            final s = _students[index];
                            final name = s['user']?['name'] ?? '';
                            final email = s['user']?['email'] ?? '';
                            final enroll = s['enrollmentNumber'] ?? '';
                            final status = s['user']?['status'] ?? 'ACTIVE';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primary.withOpacity(0.1),
                                child: Text(
                                  name.isNotEmpty ? name.substring(0, 1) : 'S',
                                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('$enroll • $email\nSem ${s["semester"]} - Sec ${s["section"]}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (status == 'ACTIVE' ? AppTheme.success : AppTheme.danger).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: status == 'ACTIVE' ? AppTheme.success : AppTheme.danger,
                                  ),
                                ),
                              ).animate().scale(begin: const Offset(0, 0), delay: Duration(milliseconds: 200 + index * 60), duration: 400.ms, curve: Curves.elasticOut),
                            ).animate().fadeIn(delay: Duration(milliseconds: index * 60)).slideX(begin: 0.12, curve: Curves.easeOutCubic);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
