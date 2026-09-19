import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/attendance_card.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final String? initialCourseId;

  const AttendanceHistoryScreen({super.key, this.initialCourseId});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  String? _selectedCourseId;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.initialCourseId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  void _loadHistory() {
    Provider.of<AttendanceProvider>(context, listen: false)
        .fetchStudentData(courseId: _selectedCourseId);
  }

  @override
  Widget build(BuildContext context) {
    final attProvider = Provider.of<AttendanceProvider>(context);
    final courses = attProvider.percentageSummary?['courses'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Filter by Course
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.filter_list_rounded, color: AppTheme.textSecondary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String?>(
                    value: _selectedCourseId,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text('All Enrolled Subjects'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Enrolled Subjects'),
                      ),
                      ...courses.map((c) {
                        return DropdownMenuItem<String?>(
                          value: c['courseId'] as String,
                          child: Text('${c['courseCode']} - ${c['courseName']}'),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedCourseId = val);
                      _loadHistory();
                    },
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
          const Divider(height: 1, color: AppTheme.border),

          // List of Records
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _loadHistory(),
              child: attProvider.isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: buildShimmerList(),
                      ),
                    )
                  : attProvider.history.isEmpty
                      ? Center(
                          child: const Text(
                            'No attendance records found for this selection.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: attProvider.history.length,
                          itemBuilder: (context, index) {
                            return AttendanceCard(
                              record: attProvider.history[index],
                              animationIndex: index,
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
