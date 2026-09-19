import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/student/qr_scanner_screen.dart';
import '../screens/student/attendance_history_screen.dart';
import '../screens/student/student_profile_screen.dart';
import '../screens/teacher/teacher_dashboard.dart';
import '../screens/teacher/create_session_screen.dart';
import '../screens/teacher/qr_display_screen.dart';
import '../screens/teacher/monitor_attendance_screen.dart';
import '../screens/teacher/report_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/manage_students_screen.dart';
import '../screens/admin/manage_teachers_screen.dart';
import '../screens/admin/manage_courses_screen.dart';
import '../screens/admin/admin_reports_screen.dart';
import 'animations.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authProvider,
    redirect: (BuildContext context, GoRouterState state) {
      final isAuth = authProvider.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isAuth && !isLoggingIn) {
        return '/login';
      }

      if (isAuth && isLoggingIn) {
        final user = authProvider.user!;
        if (user.isStudent) return '/student';
        if (user.isTeacher) return '/teacher';
        if (user.isAdmin) return '/admin';
      }

      return null;
    },
    routes: [
      // Auth routes — Fade + Scale transitions
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: fadeScaleTransition,
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: slideUpTransition,
        ),
      ),

      // Student routes — Slide from right transitions
      GoRoute(
        path: '/student',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StudentDashboard(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: fadeScaleTransition,
        ),
      ),
      GoRoute(
        path: '/student/scan',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const QrScannerScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: slideUpTransition,
        ),
      ),
      GoRoute(
        path: '/student/history',
        pageBuilder: (context, state) {
          final courseId = state.uri.queryParameters['courseId'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: AttendanceHistoryScreen(initialCourseId: courseId),
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: slideRightTransition,
          );
        },
      ),
      GoRoute(
        path: '/student/profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StudentProfileScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: slideRightTransition,
        ),
      ),

      // Teacher routes — Slide up transitions
      GoRoute(
        path: '/teacher',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const TeacherDashboard(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: fadeScaleTransition,
        ),
      ),
      GoRoute(
        path: '/teacher/create-session',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreateSessionScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: slideUpTransition,
        ),
      ),
      GoRoute(
        path: '/teacher/qr-display',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const QrDisplayScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: fadeScaleTransition,
        ),
      ),
      GoRoute(
        path: '/teacher/monitor',
        pageBuilder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: MonitorAttendanceScreen(sessionId: sessionId),
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: slideRightTransition,
          );
        },
      ),
      GoRoute(
        path: '/teacher/reports',
        pageBuilder: (context, state) {
          final courseId = state.uri.queryParameters['courseId'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: TeacherReportScreen(initialCourseId: courseId),
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder: slideRightTransition,
          );
        },
      ),

      // Admin routes — Fade through transitions
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminDashboard(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: fadeScaleTransition,
        ),
      ),
      GoRoute(
        path: '/admin/students',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ManageStudentsScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: slideRightTransition,
        ),
      ),
      GoRoute(
        path: '/admin/teachers',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ManageTeachersScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: slideRightTransition,
        ),
      ),
      GoRoute(
        path: '/admin/courses',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ManageCoursesScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: slideRightTransition,
        ),
      ),
      GoRoute(
        path: '/admin/reports',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminReportsScreen(),
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: fadeThroughTransition,
        ),
      ),
    ],
  );
}
