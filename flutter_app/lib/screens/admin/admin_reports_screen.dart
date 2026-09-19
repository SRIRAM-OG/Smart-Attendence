import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../services/admin_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _lowAttendanceList = [];
  bool _isLoading = true;
  int _threshold = 75;

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final list = await _adminService.getLowAttendance(threshold: _threshold);
      setState(() {
        _lowAttendanceList = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Defaulters Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Threshold Filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Attendance Threshold:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  value: _threshold,
                  items: [60, 65, 70, 75, 80, 85].map((t) {
                    return DropdownMenuItem(value: t, child: Text('Below $t%'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _threshold = val);
                      _fetchReport();
                    }
                  },
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.15),
          const Divider(height: 1, color: AppTheme.border),

          // Defaulters List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchReport,
              child: _isLoading
                  ? buildShimmerList(count: 8, cardHeight: 80)
                  : _lowAttendanceList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 64)
                                  .animate().scale(begin: const Offset(0, 0), duration: 800.ms, curve: Curves.elasticOut),
                              const SizedBox(height: 12),
                              const Text(
                                'All students meet the attendance criteria!',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _lowAttendanceList.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                          itemBuilder: (context, index) {
                            final item = _lowAttendanceList[index];
                            final pct = (item['percentage'] as num?)?.toDouble() ?? 0.0;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFEBEE),
                                child: Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 22),
                              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 1500.ms),
                              title: Text(
                                item['studentName'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${item["enrollmentNumber"]} • ${item["courseCode"]} (${item["courseName"]})\nAttended ${item["attended"]} of ${item["totalSessions"]} sessions',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: AnimatedCounter(
                                  value: pct.toInt(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.danger,
                                  ),
                                  suffix: '%',
                                ),
                              ),
                            ).animate().fadeIn(delay: Duration(milliseconds: index * 70)).slideX(begin: 0.12);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
