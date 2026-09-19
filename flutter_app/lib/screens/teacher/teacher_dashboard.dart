import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../models/attendance_session.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/session_card.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  List<AttendanceSession> _recentSessions = [];
  bool _isLoadingSessions = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    await courseProvider.fetchTeacherCourses();

    try {
      final response = await ApiService().dio.get(ApiConfig.teacherSessions);
      final List list = response.data['data'] ?? [];
      setState(() {
        _recentSessions = list.map((j) => AttendanceSession.fromJson(j)).toList();
        _isLoadingSessions = false;
      });
    } catch (_) {
      setState(() => _isLoadingSessions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final courseProvider = Provider.of<CourseProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? 'Teacher Portal',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Faculty Dashboard',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Course Reports',
            onPressed: () => context.push('/teacher/reports'),
          ),
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
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stat Cards
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'My Courses',
                      value: '${courseProvider.courses.length}',
                      icon: Icons.menu_book_rounded,
                      color: AppTheme.primary,
                      animationIndex: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Sessions Taken',
                      value: '${_recentSessions.length}',
                      icon: Icons.history_edu_rounded,
                      color: AppTheme.secondary,
                      animationIndex: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Banner: Start Attendance Session
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF1E40AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.qr_code_rounded, color: Colors.white, size: 28),
                        SizedBox(width: 10),
                        Text(
                          'Start Class Attendance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select your subject and generate a time-limited dynamic QR code for students to scan in class.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    PulsingGlow(
                      glowColor: Colors.white.withOpacity(0.3),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await context.push('/teacher/create-session');
                          _loadDashboardData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                          minimumSize: const Size(double.infinity, 46),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text('Create Attendance Session'),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.15, curve: Curves.easeOutCubic),
              const SizedBox(height: 28),

              // Section: My Assigned Courses
              Text(
                'My Assigned Courses',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.15),
              const SizedBox(height: 12),
              if (courseProvider.isLoading)
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: buildShimmerList(),
                )
              else if (courseProvider.courses.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No courses assigned yet. Contact system admin.'),
                  ),
                )
              else
                ...courseProvider.courses.asMap().entries.map((entry) {
                  int index = entry.key;
                  var course = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.code,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                course.name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${course.totalEnrolled ?? 0} students enrolled • ${course.totalSessions ?? 0} sessions',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onPressed: () => context.push('/teacher/reports?courseId=${course.id}'),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: Duration(milliseconds: 500 + index * 80)).slideX(begin: 0.1);
                }),
              const SizedBox(height: 24),

              // Section: Recent Attendance Sessions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Sessions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.15),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoadingSessions)
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: buildShimmerList(),
                )
              else if (_recentSessions.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No past sessions recorded.'),
                  ),
                )
              else
                ..._recentSessions.asMap().entries.map((entry) {
                  int index = entry.key;
                  var session = entry.value;
                  return SessionCard(
                    session: session,
                    animationIndex: index,
                    onTap: () => context.push('/teacher/monitor?sessionId=${session.id}'),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
