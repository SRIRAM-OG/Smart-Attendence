const prisma = require('../config/db');
const ApiError = require('../utils/apiError');

class ReportService {
  /**
   * Comprehensive Student Attendance Report
   */
  async getStudentReport(studentId) {
    const student = await prisma.student.findUnique({
      where: { id: studentId },
      include: {
        user: { select: { name: true, email: true, status: true } },
        department: true,
      },
    });

    if (!student) {
      throw ApiError.notFound('Student not found');
    }

    const enrollments = await prisma.enrollment.findMany({
      where: { studentId },
      include: { course: true },
    });

    const subjectReports = await Promise.all(
      enrollments.map(async (enrollment) => {
        const totalSessions = await prisma.attendanceSession.count({
          where: { courseId: enrollment.courseId },
        });

        const presentCount = await prisma.attendanceRecord.count({
          where: {
            studentId,
            status: 'PRESENT',
            session: { courseId: enrollment.courseId },
          },
        });

        const lateCount = await prisma.attendanceRecord.count({
          where: {
            studentId,
            status: 'LATE',
            session: { courseId: enrollment.courseId },
          },
        });

        const percentage = totalSessions > 0 ? Number(((presentCount / totalSessions) * 100).toFixed(2)) : 100;

        return {
          courseId: enrollment.course.id,
          courseCode: enrollment.course.code,
          courseName: enrollment.course.name,
          totalSessions,
          presentCount,
          lateCount,
          absentCount: Math.max(0, totalSessions - presentCount - lateCount),
          percentage,
          status: percentage >= 75 ? 'ELIGIBLE' : 'SHORT_ATTENDANCE',
        };
      })
    );

    const totalConducted = subjectReports.reduce((sum, s) => sum + s.totalSessions, 0);
    const totalPresent = subjectReports.reduce((sum, s) => sum + s.presentCount, 0);
    const overallPercentage = totalConducted > 0 ? Number(((totalPresent / totalConducted) * 100).toFixed(2)) : 100;

    return {
      student: {
        id: student.id,
        name: student.user.name,
        email: student.user.email,
        enrollmentNumber: student.enrollmentNumber,
        department: student.department.name,
        semester: student.semester,
        section: student.section,
      },
      overall: {
        totalConducted,
        totalPresent,
        overallPercentage,
        isEligibleForExam: overallPercentage >= 75,
      },
      subjects: subjectReports,
    };
  }

  /**
   * Course-Level Attendance Report
   */
  async getCourseReport(courseId) {
    const course = await prisma.course.findUnique({
      where: { id: courseId },
      include: {
        department: true,
        teacherCourses: {
          include: {
            teacher: { include: { user: { select: { name: true, email: true } } } },
          },
        },
      },
    });

    if (!course) {
      throw ApiError.notFound('Course not found');
    }

    const totalSessions = await prisma.attendanceSession.count({
      where: { courseId },
    });

    const enrollments = await prisma.enrollment.findMany({
      where: { courseId },
      include: {
        student: {
          include: {
            user: { select: { name: true, email: true } },
            department: true,
          },
        },
      },
    });

    const studentStats = await Promise.all(
      enrollments.map(async (enr) => {
        const attended = await prisma.attendanceRecord.count({
          where: {
            studentId: enr.studentId,
            status: 'PRESENT',
            session: { courseId },
          },
        });

        const percentage = totalSessions > 0 ? Number(((attended / totalSessions) * 100).toFixed(2)) : 100;

        return {
          studentId: enr.student.id,
          name: enr.student.user.name,
          email: enr.student.user.email,
          enrollmentNumber: enr.student.enrollmentNumber,
          section: enr.student.section,
          attended,
          total: totalSessions,
          percentage,
          isLow: percentage < 75,
        };
      })
    );

    const lowAttendanceStudents = studentStats.filter((s) => s.isLow);
    const avgAttendance =
      studentStats.length > 0
        ? Number((studentStats.reduce((sum, s) => sum + s.percentage, 0) / studentStats.length).toFixed(2))
        : 0;

    return {
      course: {
        id: course.id,
        code: course.code,
        name: course.name,
        department: course.department.name,
        teachers: course.teacherCourses.map((tc) => tc.teacher.user.name),
      },
      summary: {
        totalSessions,
        totalEnrolled: enrollments.length,
        averageAttendancePercentage: avgAttendance,
        lowAttendanceCount: lowAttendanceStudents.length,
      },
      students: studentStats,
      lowAttendanceStudents,
    };
  }

  /**
   * System-wide Low Attendance Detection (<75% threshold)
   */
  async getLowAttendance(threshold = 75) {
    const students = await prisma.student.findMany({
      include: {
        user: { select: { name: true, email: true } },
        department: true,
        enrollments: {
          include: { course: true },
        },
      },
    });

    const lowAttendanceList = [];

    for (const student of students) {
      for (const enr of student.enrollments) {
        const totalSessions = await prisma.attendanceSession.count({
          where: { courseId: enr.courseId },
        });

        if (totalSessions > 0) {
          const attended = await prisma.attendanceRecord.count({
            where: {
              studentId: student.id,
              status: 'PRESENT',
              session: { courseId: enr.courseId },
            },
          });

          const percentage = Number(((attended / totalSessions) * 100).toFixed(2));

          if (percentage < threshold) {
            lowAttendanceList.push({
              studentId: student.id,
              studentName: student.user.name,
              enrollmentNumber: student.enrollmentNumber,
              email: student.user.email,
              department: student.department.name,
              semester: student.semester,
              section: student.section,
              courseCode: enr.course.code,
              courseName: enr.course.name,
              attended,
              totalSessions,
              percentage,
            });
          }
        }
      }
    }

    return lowAttendanceList;
  }

  /**
   * Daily System Attendance Summary
   */
  async getDailyReport(date = new Date()) {
    const targetDate = new Date(date);
    targetDate.setHours(0, 0, 0, 0);
    const nextDate = new Date(targetDate);
    nextDate.setDate(nextDate.getDate() + 1);

    const sessions = await prisma.attendanceSession.findMany({
      where: {
        sessionDate: {
          gte: targetDate,
          lt: nextDate,
        },
      },
      include: {
        course: true,
        teacher: { include: { user: { select: { name: true } } } },
        records: true,
      },
    });

    const totalSessions = sessions.length;
    const totalAttendancesMarked = sessions.reduce((sum, s) => sum + s.records.length, 0);

    return {
      date: targetDate.toISOString().split('T')[0],
      totalSessions,
      totalAttendancesMarked,
      sessions: sessions.map((s) => ({
        sessionId: s.id,
        courseCode: s.course.code,
        courseName: s.course.name,
        teacherName: s.teacher.user.name,
        status: s.status,
        startTime: s.startTime,
        presentCount: s.records.length,
      })),
    };
  }

  /**
   * Admin System Overview Stats
   */
  async getSystemStats() {
    const [totalStudents, totalTeachers, totalCourses, totalSessions, totalRecords] = await Promise.all([
      prisma.student.count(),
      prisma.teacher.count(),
      prisma.course.count(),
      prisma.attendanceSession.count(),
      prisma.attendanceRecord.count({ where: { status: 'PRESENT' } }),
    ]);

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const todaySessions = await prisma.attendanceSession.count({
      where: { sessionDate: { gte: today, lt: tomorrow } },
    });

    const todayRecords = await prisma.attendanceRecord.count({
      where: { timestamp: { gte: today, lt: tomorrow } },
    });

    return {
      totalStudents,
      totalTeachers,
      totalCourses,
      totalSessions,
      totalRecords,
      todaySessions,
      todayRecords,
    };
  }
}

module.exports = new ReportService();
