import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../config/theme.dart';
import '../config/animations.dart';

class CourseAttendanceTile extends StatelessWidget {
  final String courseCode;
  final String courseName;
  final int attended;
  final int total;
  final double percentage;
  final VoidCallback? onTap;
  final int animationIndex;

  const CourseAttendanceTile({
    super.key,
    required this.courseCode,
    required this.courseName,
    required this.attended,
    required this.total,
    required this.percentage,
    this.onTap,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isGood = percentage >= 75.0;
    final statusColor = isGood ? AppTheme.success : AppTheme.danger;

    return PressableScale(
      onTap: onTap,
      child: Tilt3DCard(
        maxTilt: 0.03,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courseCode,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          courseName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedCounter(
                    value: percentage,
                    duration: const Duration(milliseconds: 1000),
                    decimalPlaces: 1,
                    suffix: '%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (percentage / 100).clamp(0.0, 1.0)),
                duration: Duration(milliseconds: 800 + animationIndex * 100),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearPercentIndicator(
                    lineHeight: 6.0,
                    percent: value,
                    backgroundColor: AppTheme.border,
                    progressColor: statusColor,
                    barRadius: const Radius.circular(8),
                    padding: EdgeInsets.zero,
                    animation: false,
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$attended attended / $total conducted',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  Text(
                    isGood ? 'Good Standing' : 'Short Attendance',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 400.ms,
          delay: Duration(milliseconds: animationIndex * 80),
          curve: Curves.easeOut,
        )
        .slideX(
          begin: -0.1,
          end: 0,
          duration: 400.ms,
          delay: Duration(milliseconds: animationIndex * 80),
          curve: Curves.easeOutCubic,
        );
  }
}
