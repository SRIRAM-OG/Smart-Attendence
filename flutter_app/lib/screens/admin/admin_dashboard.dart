import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../widgets/stat_card.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _lowAttendanceList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _adminService.getDashboardStats();
      final lowAtt = await _adminService.getLowAttendance(threshold: 75);
      setState(() {
        _stats = stats;
        _lowAttendanceList = lowAtt;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user?.name ?? 'Admin Console', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('System Administration', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: _isLoading 
            ? buildShimmerList(count: 6, cardHeight: 100)
            : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // System Stat Cards Grid
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Students',
                      value: '${_stats?["totalStudents"] ?? 0}',
                      icon: Icons.school_rounded,
                      color: AppTheme.primary,
                      onTap: () => context.push('/admin/students'),
                      animationIndex: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Faculty Members',
                      value: '${_stats?["totalTeachers"] ?? 0}',
                      icon: Icons.person_search_rounded,
                      color: AppTheme.secondary,
                      onTap: () => context.push('/admin/teachers'),
                      animationIndex: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Courses Offered',
                      value: '${_stats?["totalCourses"] ?? 0}',
                      icon: Icons.menu_book_rounded,
                      color: AppTheme.primaryLight,
                      onTap: () => context.push('/admin/courses'),
                      animationIndex: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Short Attendance',
                      value: '${_lowAttendanceList.length}',
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.danger,
                      subtitle: '<75% threshold',
                      onTap: () => context.push('/admin/reports'),
                      animationIndex: 3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Administration Navigation Tiles
              Text(
                'Management Console',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.15),
              const SizedBox(height: 12),
              _buildAdminTile(
                title: 'Manage Students',
                subtitle: 'Add, view, edit academic details and enrollments',
                icon: Icons.people_outline_rounded,
                color: AppTheme.primary,
                onTap: () => context.push('/admin/students'),
                index: 0,
              ),
              _buildAdminTile(
                title: 'Manage Teachers',
                subtitle: 'Faculty profiles and course allocations',
                icon: Icons.supervisor_account_outlined,
                color: AppTheme.secondary,
                onTap: () => context.push('/admin/teachers'),
                index: 1,
              ),
              _buildAdminTile(
                title: 'Manage Courses & Subjects',
                subtitle: 'Course catalog, departmental codes and syllabus',
                icon: Icons.book_outlined,
                color: AppTheme.info,
                onTap: () => context.push('/admin/courses'),
                index: 2,
              ),
              _buildAdminTile(
                title: 'Institutional Reports & Analytics',
                subtitle: 'System-wide attendance matrices, exportable reports',
                icon: Icons.insert_chart_outlined_rounded,
                color: AppTheme.accent,
                onTap: () => context.push('/admin/reports'),
                index: 3,
              ),
              const SizedBox(height: 24),

              // Low Attendance Alert Section
              if (_lowAttendanceList.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Attendance Warnings (<75%)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.danger),
                    ),
                    Text(
                      '${_lowAttendanceList.length} alert${_lowAttendanceList.length > 1 ? "s" : ""}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.15),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _lowAttendanceList.take(5).length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                    itemBuilder: (context, index) {
                      final item = _lowAttendanceList[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFEBEE),
                          child: Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -2, end: 2, duration: 2000.ms),
                        title: Text(item['studentName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${item["enrollmentNumber"]} • ${item["courseCode"]}'),
                        trailing: Text(
                          '${item["percentage"]}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.danger, fontSize: 16),
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 700 + index * 60)).slideX(begin: 0.1);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required int index,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -2, end: 2, duration: 2000.ms),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 500 + index * 80)).slideX(begin: 0.1, curve: Curves.easeOutCubic);
  }
}
