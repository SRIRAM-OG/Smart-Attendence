import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../providers/attendance_provider.dart';

class QrDisplayScreen extends StatefulWidget {
  const QrDisplayScreen({super.key});

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    final attProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final expiresAt = attProvider.qrExpiresAt;

    if (expiresAt != null) {
      final diff = expiresAt.difference(DateTime.now()).inSeconds;
      setState(() => _secondsRemaining = diff > 0 ? diff : 0);

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final remaining = expiresAt.difference(DateTime.now()).inSeconds;
        if (remaining <= 0) {
          timer.cancel();
          setState(() => _secondsRemaining = 0);
        } else {
          setState(() => _secondsRemaining = remaining);
        }
      });
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final attProvider = Provider.of<AttendanceProvider>(context);
    final session = attProvider.activeSession;
    final payload = attProvider.qrPayload;
    final isExpired = _secondsRemaining <= 0;

    if (session == null || payload == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Attendance QR')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No active session found.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/teacher'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${session.courseCode} Attendance QR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline_rounded),
            tooltip: 'Live Attendance List',
            onPressed: () => context.push('/teacher/monitor?sessionId=${session.id}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Course & Status Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          session.courseName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${session.courseCode} • Active Session',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  // Live Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        AnimatedCounter(
                          value: attProvider.totalPresent,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success,
                          ),
                        ),
                        const Text(
                          'Present',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
            const SizedBox(height: 20),

            // QR Code Box
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isExpired ? AppTheme.danger : AppTheme.primaryLight,
                  width: 2,
                ),
                boxShadow: AppTheme.depthShadowColored(isExpired ? AppTheme.danger : AppTheme.primary),
              ),
              child: Column(
                children: [
                  if (isExpired)
                    Container(
                      width: 260,
                      height: 260,
                      color: Colors.grey.shade100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_off_outlined, color: AppTheme.danger, size: 54)
                              .animate().scale(begin: const Offset(0,0), duration: 600.ms, curve: Curves.elasticOut),
                          const SizedBox(height: 12),
                          const Text(
                            'QR Code Expired',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.danger),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap Regenerate below to create a new code',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 260.0,
                      backgroundColor: Colors.white,
                    ),
                  const SizedBox(height: 16),

                  // Timer Badge
                  Builder(
                    builder: (context) {
                      Widget badge = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isExpired ? AppTheme.danger.withOpacity(0.12) : AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: isExpired ? AppTheme.danger : AppTheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isExpired ? 'EXPIRED' : 'Expires in ${_formatDuration(_secondsRemaining)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isExpired ? AppTheme.danger : AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                      
                      if (!isExpired) {
                        return badge.animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1000.ms);
                      }
                      return badge;
                    }
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutCubic),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final success = await attProvider.regenerateQr();
                      if (success) _startCountdown();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Regenerate QR'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/teacher/monitor?sessionId=${session.id}'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                    icon: const Icon(Icons.list_alt_rounded),
                    label: const Text('View List'),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
            const SizedBox(height: 12),

            // Close Session Button
            OutlinedButton(
              onPressed: () async {
                await attProvider.closeActiveSession();
                if (mounted) context.go('/teacher');
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.danger),
                foregroundColor: AppTheme.danger,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Close Attendance Session'),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }
}
