import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../providers/attendance_provider.dart';

class MonitorAttendanceScreen extends StatefulWidget {
  final String sessionId;

  const MonitorAttendanceScreen({super.key, required this.sessionId});

  @override
  State<MonitorAttendanceScreen> createState() => _MonitorAttendanceScreenState();
}

class _MonitorAttendanceScreenState extends State<MonitorAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AttendanceProvider>(context, listen: false).fetchSessionRecords(widget.sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final attProvider = Provider.of<AttendanceProvider>(context);
    final session = attProvider.activeSession;
    final records = attProvider.sessionRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Attendance Monitor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => attProvider.fetchSessionRecords(widget.sessionId),
          ),
        ],
      ),
      body: Column(
        children: [
          // Session Header Card
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session?.courseName ?? 'Attendance Session',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 4),
                Text(
                  '${session?.courseCode ?? ""} • ${DateFormat("MMM d, yyyy").format(session?.sessionDate ?? DateTime.now())}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            AnimatedCounter(
                              value: attProvider.totalPresent,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.success,
                              ),
                            ),
                            const Text(
                              'Present',
                              style: TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            AnimatedCounter(
                              value: attProvider.totalEnrolled,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                            const Text(
                              'Total Enrolled',
                              style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // Students Attendance List
          Expanded(
            child: records.isEmpty
                ? const Center(
                    child: Text(
                      'No students have scanned in yet.\nWaiting for students...',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final timeStr = DateFormat('hh:mm:ss a').format(record.timestamp);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: Text(
                            record.studentName?.substring(0, 1) ?? 'S',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                        ),
                        title: Text(
                          record.studentName ?? 'Student',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${record.enrollmentNumber ?? ""} • Verified at $timeStr',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PRESENT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.success,
                            ),
                          ),
                        ).animate().scale(begin: const Offset(0,0), delay: Duration(milliseconds: 300 + index * 60), duration: 400.ms, curve: Curves.elasticOut),
                      ).animate().fadeIn(delay: Duration(milliseconds: 200 + index * 60)).slideX(begin: 0.15, curve: Curves.easeOutCubic);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
