const prisma = require('../config/db');
const ApiError = require('../utils/apiError');

class TeacherController {
  /**
   * Get teacher profile
   */
  async getProfile(req, res, next) {
    try {
      const teacher = await prisma.teacher.findUnique({
        where: { userId: req.user.id },
        include: {
          user: { select: { id: true, name: true, email: true, role: true, status: true } },
          department: true,
          teacherCourses: {
            include: {
              course: {
                include: {
                  department: true,
                  _count: { select: { enrollments: true, sessions: true } },
                },
              },
            },
          },
        },
      });

      if (!teacher) {
        throw ApiError.notFound('Teacher record not found');
      }

      res.status(200).json({
        success: true,
        data: teacher,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get courses assigned to teacher
   */
  async getCourses(req, res, next) {
    try {
      const teacher = await prisma.teacher.findUnique({
        where: { userId: req.user.id },
      });

      if (!teacher) {
        throw ApiError.notFound('Teacher record not found');
      }

      const assignments = await prisma.teacherCourse.findMany({
        where: { teacherId: teacher.id },
        include: {
          course: {
            include: {
              department: true,
              _count: { select: { enrollments: true, sessions: true } },
            },
          },
        },
      });

      const courses = assignments.map((a) => ({
        id: a.course.id,
        code: a.course.code,
        name: a.course.name,
        department: a.course.department.name,
        totalEnrolled: a.course._count.enrollments,
        totalSessions: a.course._count.sessions,
      }));

      res.status(200).json({
        success: true,
        data: courses,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get sessions created by teacher
   */
  async getSessions(req, res, next) {
    try {
      const teacher = await prisma.teacher.findUnique({
        where: { userId: req.user.id },
      });

      if (!teacher) {
        throw ApiError.notFound('Teacher record not found');
      }

      const { courseId, status } = req.query;
      const where = { teacherId: teacher.id };
      if (courseId) where.courseId = courseId;
      if (status) where.status = status;

      const sessions = await prisma.attendanceSession.findMany({
        where,
        include: {
          course: true,
          _count: { select: { records: true } },
        },
        orderBy: { sessionDate: 'desc' },
      });

      const mapped = sessions.map((s) => ({
        id: s.id,
        courseId: s.courseId,
        courseCode: s.course.code,
        courseName: s.course.name,
        sessionDate: s.sessionDate,
        startTime: s.startTime,
        endTime: s.endTime,
        status: s.status,
        qrToken: s.qrToken,
        qrExpiresAt: s.qrExpiresAt,
        totalPresent: s._count.records,
      }));

      res.status(200).json({
        success: true,
        data: mapped,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new TeacherController();
