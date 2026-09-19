import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/percentage_indicator.dart';
import '../../widgets/course_tile.dart';
import '../../widgets/attendance_card.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceProvider>(context, listen: false).fetchStudentData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final attProvider = Provider.of<AttendanceProvider>(context);
    final user = auth.user;

    final overall = attProvider.percentageSummary;
    final overallPct = (overall?['overallPercentage'] as num?)?.toDouble() ?? 100.0;
    final attended = (overall?['totalAttended'] as num?)?.toInt() ?? 0;
    final totalEligible = (overall?['totalEligible'] as num?)?.toInt() ?? 0;
    final List courses = overall?['courses'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.name ?? 'Student Portal',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (user?.student?.enrollmentNumber != null)
              Text(
                user!.student!.enrollmentNumber,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            tooltip: 'Profile',
            onPressed: () => context.push('/student/profile'),
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
        onRefresh: () => attProvider.fetchStudentData(),
        child: attProvider.isLoading
            ? Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: buildShimmerList(),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Percentage Card
                    AttendancePercentageCard(
                      percentage: overallPct,
                      attended: attended,
                      total: totalEligible,
                      title: 'My Overall Attendance',
                    ),
                    const SizedBox(height: 20),

                    // Big Action Button: Scan Attendance QR
                    PulsingGlow(
                      glowColor: AppTheme.secondary,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.secondary, Color(0xFF0F766E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await context.push('/student/scan');
                              attProvider.fetchStudentData();
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Scan Attendance QR',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Point camera at teacher screen',
                                          style: TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                    const SizedBox(height: 28),

                    // Section: Course-wise Attendance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subject-Wise Attendance',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
                    const SizedBox(height: 12),
                    if (courses.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('No enrolled courses found.'),
                        ),
                      ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8))
                    else
                      ...courses.asMap().entries.map((entry) {
                        final index = entry.key;
                        final c = entry.value;
                        return CourseAttendanceTile(
                          courseCode: c['courseCode'] ?? '',
                          courseName: c['courseName'] ?? '',
                          attended: (c['attendedSessions'] as num?)?.toInt() ?? 0,
                          total: (c['totalSessions'] as num?)?.toInt() ?? 0,
                          percentage: (c['percentage'] as num?)?.toDouble() ?? 100.0,
                          animationIndex: index,
                          onTap: () => context.push('/student/history?courseId=${c['courseId']}'),
                        );
                      }),
                    const SizedBox(height: 24),

                    // Section: Recent Attendance Log
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Attendance',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/student/history'),
                          child: const Text('View All'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
                    const SizedBox(height: 8),
                    if (attProvider.history.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'No attendance records yet. Scan a class QR code!',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8))
                    else
                      ...attProvider.history.take(4).toList().asMap().entries.map((entry) {
                        return AttendanceCard(
                          record: entry.value,
                          animationIndex: entry.key,
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}
