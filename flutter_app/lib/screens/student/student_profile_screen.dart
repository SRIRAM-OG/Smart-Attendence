import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../providers/auth_provider.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final student = user?.student;

    final infoRows = [
      _buildInfoRow('Enrollment No.', student?.enrollmentNumber ?? 'N/A'),
      const Divider(color: AppTheme.border),
      _buildInfoRow('Department', student?.departmentName ?? 'Computer Science'),
      const Divider(color: AppTheme.border),
      _buildInfoRow('Current Semester', 'Semester ${student?.semester ?? 1}'),
      const Divider(color: AppTheme.border),
      _buildInfoRow('Section', 'Section ${student?.section ?? "A"}'),
      const Divider(color: AppTheme.border),
      _buildInfoRow('Account Status', user?.status ?? 'ACTIVE'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profile Card
            Tilt3DCard(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(
                        user?.name.isNotEmpty == true ? user!.name.substring(0, 1).toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ).animate().scale(begin: const Offset(0,0), end: const Offset(1,1), duration: 600.ms, curve: Curves.elasticOut).fadeIn(),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'STUDENT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ).animate().scale(begin: const Offset(0,0), duration: 400.ms, delay: 400.ms, curve: Curves.elasticOut),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Academic Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Academic Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...infoRows.asMap().entries.map((e) => e.value.animate().fadeIn(delay: (400 + (e.key * 80)).ms).slideX(begin: 0.1)),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15),
            const SizedBox(height: 30),

            // Logout Button
            OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
              label: const Text('Sign Out', style: TextStyle(color: AppTheme.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.danger),
                minimumSize: const Size(double.infinity, 50),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
