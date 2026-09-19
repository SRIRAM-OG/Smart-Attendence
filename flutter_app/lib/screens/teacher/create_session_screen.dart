import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/course_provider.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {
  String? _selectedCourseId;
  int _expiryMinutes = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cp = Provider.of<CourseProvider>(context, listen: false);
      if (cp.courses.isNotEmpty) {
        setState(() => _selectedCourseId = cp.courses[0].id);
      }
    });
  }

  Future<void> _handleStartSession() async {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course')),
      );
      return;
    }

    final attProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final success = await attProvider.createSession(
      _selectedCourseId!,
      expiryMinutes: _expiryMinutes,
    );

    if (success && mounted) {
      context.pushReplacement('/teacher/qr-display');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attProvider.errorMessage ?? 'Failed to start session'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final attProvider = Provider.of<AttendanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Attendance Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This will generate a time-limited dynamic QR code. Students will scan this code in real time.',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15),
            const SizedBox(height: 24),

            // Select Course
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Subject / Course',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                if (courseProvider.courses.isEmpty)
                  const Text('Loading assigned subjects...')
                else
                  DropdownButtonFormField<String>(
                    value: _selectedCourseId,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.menu_book_rounded),
                    ),
                    items: courseProvider.courses.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.code} - ${c.name}'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCourseId = val),
                  ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
            const SizedBox(height: 24),

            // QR Code Expiry Duration
            const Text(
              'QR Code Validity Duration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [1, 2, 3, 5, 10, 15].asMap().entries.map((entry) {
                int chipIndex = entry.key;
                int mins = entry.value;
                final isSelected = _expiryMinutes == mins;
                return ChoiceChip(
                  label: Text('$mins min${mins > 1 ? "s" : ""}'),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _expiryMinutes = mins);
                  },
                ).animate().fadeIn(delay: Duration(milliseconds: 400 + chipIndex * 60)).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutCubic);
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Generate Button
            PulsingGlow(
              glowColor: AppTheme.primary,
              child: ElevatedButton.icon(
                onPressed: attProvider.isLoading ? null : _handleStartSession,
                icon: attProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.qr_code_2_rounded, size: 24),
                label: const Text('Generate Dynamic QR Code'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
          ],
        ),
      ),
    );
  }
}
