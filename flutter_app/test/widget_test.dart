import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance_app/app.dart';
import 'package:smart_attendance_app/providers/auth_provider.dart';
import 'package:smart_attendance_app/providers/attendance_provider.dart';
import 'package:smart_attendance_app/providers/course_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App initializes successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => AttendanceProvider()),
          ChangeNotifierProvider(create: (_) => CourseProvider()),
        ],
        child: const SmartAttendanceApp(),
      ),
    );

    expect(find.byType(SmartAttendanceApp), findsOneWidget);
  });
}
