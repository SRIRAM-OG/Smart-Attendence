import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../config/animations.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _enrollmentController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _sectionController = TextEditingController(text: 'A');

  int _selectedSemester = 1;
  String? _selectedDepartmentId;
  List<Map<String, dynamic>> _departments = [];
  bool _isLoadingDepts = true;

  @override
  void initState() {
    super.initState();
    _fetchDepartments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _enrollmentController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  Future<void> _fetchDepartments() async {
    try {
      final depts = await AdminService().getDepartments();
      setState(() {
        _departments = depts;
        if (_departments.isNotEmpty) {
          _selectedDepartmentId = _departments[0]['id'];
        }
        _isLoadingDepts = false;
      });
    } catch (_) {
      setState(() => _isLoadingDepts = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      enrollmentNumber: _enrollmentController.text.trim(),
      departmentId: _selectedDepartmentId!,
      semester: _selectedSemester,
      section: _sectionController.text.trim().toUpperCase(),
    );

    if (success && mounted) {
      context.go('/student');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Registration failed'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Student Account',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2),
                const SizedBox(height: 6),
                const Text(
                  'Enter your academic details to register',
                  style: TextStyle(color: AppTheme.textSecondary),
                ).animate().fadeIn(delay: 280.ms).slideY(begin: -0.2),
                const SizedBox(height: 24),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),

                // Enrollment Number
                TextFormField(
                  controller: _enrollmentController,
                  decoration: const InputDecoration(
                    labelText: 'Enrollment Number (Roll No.)',
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: 'e.g. CS2026011',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enrollment number is required' : null,
                ).animate().fadeIn(delay: 280.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? 'Valid email is required' : null,
                ).animate().fadeIn(delay: 360.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),

                // Department Dropdown
                if (_isLoadingDepts)
                  const Center(child: CircularProgressIndicator()).animate().fadeIn(delay: 440.ms).slideX(begin: -0.1)
                else if (_departments.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedDepartmentId,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                    items: _departments.map((d) {
                      return DropdownMenuItem<String>(
                        value: d['id'] as String,
                        child: Text('${d['name']} (${d['code']})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedDepartmentId = val),
                  ).animate().fadeIn(delay: 440.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),

                // Semester & Section Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedSemester,
                        decoration: const InputDecoration(
                          labelText: 'Semester',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        items: List.generate(8, (i) => i + 1).map((sem) {
                          return DropdownMenuItem(
                            value: sem, 
                            child: Text('Sem $sem').animate().scale(duration: 200.ms),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedSemester = val ?? 1),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _sectionController,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          prefixIcon: Icon(Icons.group_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 520.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password (min 6 characters)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'Minimum 6 characters' : null,
                ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 680.ms).slideX(begin: -0.1),
                const SizedBox(height: 28),

                // Register Button
                PressableScale(
                  onPressed: authProvider.isLoading ? () {} : _handleRegister,
                  child: PulsingGlow(
                    glowColor: AppTheme.primary,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Create Account',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 760.ms).slideX(begin: -0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
