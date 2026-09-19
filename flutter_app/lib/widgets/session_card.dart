import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../config/animations.dart';
import '../models/attendance_session.dart';

class SessionCard extends StatelessWidget {
  final AttendanceSession session;
  final VoidCallback? onTap;
  final int animationIndex;

  const SessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    if (session.isActive && !session.isExpired) {
      statusColor = AppTheme.success;
      statusText = 'ACTIVE';
    } else if (session.isExpired) {
      statusColor = AppTheme.warning;
      statusText = 'EXPIRED';
    } else {
      statusColor = AppTheme.textSecondary;
      statusText = 'CLOSED';
    }

    final dateFormatted = DateFormat('MMM d, yyyy').format(session.sessionDate);
    final timeFormatted = DateFormat('hh:mm a').format(session.startTime);
    final isActive = session.isActive && !session.isExpired;

    return PressableScale(
      onTap: onTap,
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isActive
                  ? Icon(Icons.qr_code_rounded, color: AppTheme.primary, size: 28)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                        duration: 1200.ms,
                        curve: Curves.easeInOut,
                      )
                  : const Icon(Icons.qr_code_rounded, color: AppTheme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.courseName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session.courseCode} • $dateFormatted at $timeFormatted',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.people_alt_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${session.totalPresent} marked present',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fadeIn(duration: 800.ms)
                      .then()
                      .fadeOut(duration: 800.ms),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
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
          delay: Duration(milliseconds: animationIndex * 80),
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 400.ms,
          delay: Duration(milliseconds: animationIndex * 80),
          curve: Curves.easeOutCubic,
        );
  }
}
