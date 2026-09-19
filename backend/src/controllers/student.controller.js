const prisma = require('../config/db');
const attendanceService = require('../services/attendance.service');
const ApiError = require('../utils/apiError');

class StudentController {
  /**
   * Get student profile
   */
  async getProfile(req, res, next) {
    try {
      const student = await prisma.student.findUnique({
        where: { userId: req.user.id },
        include: {
          user: { select: { id: true, name: true, email: true, role: true, status: true } },
          department: true,
          enrollments: {
            include: {
              course: {
                include: {
                  teacherCourses: {
                    include: { teacher: { include: { user: { select: { name: true } } } } },
                  },
                },
              },
            },
          },
        },
      });

      if (!student) {
        throw ApiError.notFound('Student record not found');
      }

      res.status(200).json({
        success: true,
        data: student,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get enrolled courses for student
   */
  async getCourses(req, res, next) {
    try {
      const student = await prisma.student.findUnique({
        where: { userId: req.user.id },
      });

      if (!student) {
        throw ApiError.notFound('Student record not found');
      }

      const enrollments = await prisma.enrollment.findMany({
        where: { studentId: student.id },
        include: {
          course: {
            include: {
              department: true,
              teacherCourses: {
                include: { teacher: { include: { user: { select: { name: true } } } } },
              },
            },
          },
        },
      });

      const courses = enrollments.map((enr) => ({
        enrollmentId: enr.id,
        academicYear: enr.academicYear,
        courseId: enr.course.id,
        name: enr.course.name,
        code: enr.course.code,
        department: enr.course.department.name,
        teachers: enr.course.teacherCourses.map((tc) => tc.teacher.user.name),
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
   * Get student's personal attendance history
   */
  async getAttendanceHistory(req, res, next) {
    try {
      const student = await prisma.student.findUnique({
        where: { userId: req.user.id },
      });

      if (!student) {
        throw ApiError.notFound('Student record not found');
      }

      const { courseId } = req.query;
      const records = await attendanceService.getStudentHistory(student.id, courseId);

      res.status(200).json({
        success: true,
        data: records,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get student's attendance percentage summary
   */
  async getAttendancePercentage(req, res, next) {
    try {
      const student = await prisma.student.findUnique({
        where: { userId: req.user.id },
      });

      if (!student) {
        throw ApiError.notFound('Student record not found');
      }

      const summary = await attendanceService.getStudentPercentage(student.id);

      res.status(200).json({
        success: true,
        data: summary,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new StudentController();
