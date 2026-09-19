import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../providers/course_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class TeacherReportScreen extends StatefulWidget {
  final String? initialCourseId;

  const TeacherReportScreen({super.key, this.initialCourseId});

  @override
  State<TeacherReportScreen> createState() => _TeacherReportScreenState();
}

class _TeacherReportScreenState extends State<TeacherReportScreen> {
  String? _selectedCourseId;
  Map<String, dynamic>? _reportData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.initialCourseId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cp = Provider.of<CourseProvider>(context, listen: false);
      if (_selectedCourseId == null && cp.courses.isNotEmpty) {
        _selectedCourseId = cp.courses[0].id;
      }
      if (_selectedCourseId != null) {
        _fetchReport();
      }
    });
  }

  Future<void> _fetchReport() async {
    if (_selectedCourseId == null) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService().dio.get('${ApiConfig.reportCourse}/$_selectedCourseId');
      setState(() {
        _reportData = response.data['data'];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = Provider.of<CourseProvider>(context);
    final summary = _reportData?['summary'];
    final List students = _reportData?['students'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Attendance Report'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Course Selector Dropdown
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: const InputDecoration(labelText: 'Select Course'),
              items: cp.courses.map((c) {
                return DropdownMenuItem(value: c.id, child: Text('${c.code} - ${c.name}'));
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedCourseId = val);
                _fetchReport();
              },
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // Report Content
          Expanded(
            child: _isLoading
                ? Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: buildShimmerList(),
                  )
                : _reportData == null
                    ? const Center(child: Text('Select a course to view attendance statistics.'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Summary Cards Row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryBox(
                                    'Total Classes',
                                    (summary?["totalSessions"] ?? 0) as num,
                                    AppTheme.primary,
                                    0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildSummaryBox(
                                    'Enrolled',
                                    (summary?["totalEnrolled"] ?? 0) as num,
                                    AppTheme.info,
                                    1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildSummaryBox(
                                    'Class Avg',
                                    (summary?["averageAttendancePercentage"] ?? 0) as num,
                                    AppTheme.success,
                                    2,
                                    suffix: '%',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            const Text(
                              'Student Breakdown',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
                            const SizedBox(height: 12),

                            // Student Table
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: students.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.border),
                                itemBuilder: (context, index) {
                                  final s = students[index];
                                  final double pct = (s['percentage'] as num?)?.toDouble() ?? 0.0;
                                  final isLow = pct < 75.0;

                                  return ListTile(
                                    title: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text('${s["enrollmentNumber"]} • Sec ${s["section"] ?? "A"}'),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${pct.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isLow ? AppTheme.danger : AppTheme.success,
                                          ),
                                        ).animate(onPlay: (c) => isLow ? c.repeat(reverse: true) : null)
                                         .fade(end: 0.5, duration: 600.ms),
                                        Text(
                                          '${s["attended"]}/${s["total"]} classes',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ).animate().fadeIn(delay: Duration(milliseconds: 500 + index * 60)).slideX(begin: 0.1);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String label, num value, Color color, int index, {String suffix = ''}) {
    return Tilt3DCard(
      maxTilt: 0.03,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedCounter(
                  value: value.toInt(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
                if (suffix.isNotEmpty)
                  Text(suffix, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 200 + index * 100)).slideY(begin: 0.2);
  }
}
