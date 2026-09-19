import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../config/theme.dart';
import '../config/animations.dart';

class AttendancePercentageCard extends StatelessWidget {
  final double percentage;
  final int attended;
  final int total;
  final String title;

  const AttendancePercentageCard({
    super.key,
    required this.percentage,
    required this.attended,
    required this.total,
    this.title = 'Overall Attendance',
  });

  @override
  Widget build(BuildContext context) {
    final isGood = percentage >= 75.0;
    final progressColor = isGood ? AppTheme.success : AppTheme.danger;

    return Tilt3DCard(
      maxTilt: 0.04,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary,
              AppTheme.primary.withBlue(160),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.depthShadowColored(AppTheme.primary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 8),
                  AnimatedCounter(
                    value: percentage,
                    duration: const Duration(milliseconds: 1500),
                    decimalPlaces: 1,
                    suffix: '%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isGood ? AppTheme.success : AppTheme.danger).withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isGood ? AppTheme.success : AppTheme.danger,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isGood ? '✓ Eligible for Exams' : '⚠ Below 75% Requirement',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 600.ms)
                      .slideX(begin: -0.2, end: 0, duration: 400.ms, delay: 600.ms),
                  const SizedBox(height: 6),
                  Text(
                    '$attended attended / $total sessions',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 800.ms),
                ],
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (percentage / 100).clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CircularPercentIndicator(
                  radius: 46.0,
                  lineWidth: 9.0,
                  percent: value,
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: Colors.white24,
                  progressColor: progressColor,
                  center: Icon(
                    isGood ? Icons.school_rounded : Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 28,
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        delay: 400.ms,
                        curve: Curves.elasticOut,
                      ),
                );
              },
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutCubic)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
