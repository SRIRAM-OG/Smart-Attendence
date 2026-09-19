import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../config/animations.dart';
import '../models/attendance_record.dart';

class AttendanceCard extends StatelessWidget {
  final AttendanceRecord record;
  final int animationIndex;

  const AttendanceCard({super.key, required this.record, this.animationIndex = 0});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (record.status) {
      case 'PRESENT':
        statusColor = AppTheme.success;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'ABSENT':
        statusColor = AppTheme.danger;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'LATE':
      default:
        statusColor = AppTheme.warning;
        statusIcon = Icons.schedule_rounded;
    }

    final dateFormatted = DateFormat('EEE, MMM d, yyyy').format(record.timestamp);
    final timeFormatted = DateFormat('hh:mm a').format(record.timestamp);

    return PressableScale(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  delay: Duration(milliseconds: 100 + animationIndex * 60),
                  curve: Curves.elasticOut,
                ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.courseName ?? record.courseCode ?? 'Attendance Recorded',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (record.courseCode != null) ...[
                        Text(
                          record.courseCode!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const Text(' • ', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                      Text(
                        dateFormatted,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    record.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                )
                    .animate()
                    .shimmer(
                      duration: 1500.ms,
                      delay: Duration(milliseconds: 500 + animationIndex * 60),
                      color: statusColor.withOpacity(0.3),
                    ),
                const SizedBox(height: 4),
                Text(
                  timeFormatted,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 400.ms,
          delay: Duration(milliseconds: animationIndex * 60),
          curve: Curves.easeOut,
        )
        .slideX(
          begin: 0.15,
          end: 0,
          duration: 400.ms,
          delay: Duration(milliseconds: animationIndex * 60),
          curve: Curves.easeOutCubic,
        );
  }
}
