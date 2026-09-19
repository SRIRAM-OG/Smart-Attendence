const prisma = require('../config/db');
const { hashPassword } = require('../utils/hash');
const reportService = require('../services/report.service');
const ApiError = require('../utils/apiError');

class AdminController {
  /**
   * System Dashboard Stats
   */
  async getDashboardStats(req, res, next) {
    try {
      const stats = await reportService.getSystemStats();
      const lowAttendance = await reportService.getLowAttendance(75);

      res.status(200).json({
        success: true,
        data: {
          ...stats,
          lowAttendanceCount: lowAttendance.length,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  // ==================== DEPARTMENTS ====================

  async getDepartments(req, res, next) {
    try {
      const departments = await prisma.department.findMany({
        include: {
          _count: { select: { students: true, teachers: true, courses: true } },
        },
        orderBy: { name: 'asc' },
      });
      res.status(200).json({ success: true, data: departments });
    } catch (error) {
      next(error);
    }
  }

  async createDepartment(req, res, next) {
    try {
      const { name, code } = req.body;
      const dept = await prisma.department.create({
        data: { name, code },
      });
      res.status(201).json({ success: true, message: 'Department created', data: dept });
    } catch (error) {
      next(error);
    }
  }

  // ==================== STUDENTS ====================

  async getStudents(req, res, next) {
    try {
      const { search, departmentId, semester } = req.query;
      const where = {};

      if (departmentId) where.departmentId = departmentId;
      if (semester) where.semester = Number(semester);
      if (search) {
        where.OR = [
          { enrollmentNumber: { contains: search } },
          { user: { name: { contains: search } } },
          { user: { email: { contains: search } } },
        ];
      }

      const students = await prisma.student.findMany({
        where,
        include: {
          user: { select: { id: true, name: true, email: true, status: true, createdAt: true } },
          department: true,
          _count: { select: { enrollments: true, attendanceRecords: true } },
        },
        orderBy: { createdAt: 'desc' },
      });

      res.status(200).json({ success: true, data: students });
    } catch (error) {
      next(error);
    }
  }

  async createStudent(req, res, next) {
    try {
      const { name, email, password, enrollmentNumber, departmentId, semester, section } = req.body;

      const existingUser = await prisma.user.findUnique({ where: { email } });
      if (existingUser) throw ApiError.conflict('Email is already registered');

      const existingEnrollment = await prisma.student.findUnique({ where: { enrollmentNumber } });
      if (existingEnrollment) throw ApiError.conflict('Enrollment number is already in use');

      const passwordHash = await hashPassword(password);

      const result = await prisma.$transaction(async (tx) => {
        const user = await tx.user.create({
          data: { name, email, passwordHash, role: 'STUDENT', status: 'ACTIVE' },
        });

        const student = await tx.student.create({
          data: {
            userId: user.id,
            enrollmentNumber,
            departmentId,
            semester: semester || 1,
            section: section || 'A',
          },
          include: { department: true },
        });

        await tx.auditLog.create({
          data: {
            userId: req.user.id,
            action: 'ADMIN_CREATE_STUDENT',
            details: `Created student ${name} (${enrollmentNumber})`,
          },
        });

        return { user, student };
      });

      res.status(201).json({ success: true, message: 'Student created successfully', data: result });
    } catch (error) {
      next(error);
    }
  }

  async updateStudent(req, res, next) {
    try {
      const { id } = req.params;
      const { name, departmentId, semester, section, status } = req.body;

      const student = await prisma.student.findUnique({ where: { id }, include: { user: true } });
      if (!student) throw ApiError.notFound('Student not found');

      await prisma.$transaction(async (tx) => {
        if (name || status) {
          await tx.user.update({
            where: { id: student.userId },
            data: {
              ...(name && { name }),
              ...(status && { status }),
            },
          });
        }

        if (departmentId || semester || section) {
          await tx.student.update({
            where: { id },
            data: {
              ...(departmentId && { departmentId }),
              ...(semester && { semester }),
              ...(section && { section }),
            },
          });
        }
      });

      const updated = await prisma.student.findUnique({
        where: { id },
        include: { user: true, department: true },
      });

      res.status(200).json({ success: true, message: 'Student updated', data: updated });
    } catch (error) {
      next(error);
    }
  }

  async deleteStudent(req, res, next) {
    try {
      const { id } = req.params;
      const student = await prisma.student.findUnique({ where: { id } });
      if (!student) throw ApiError.notFound('Student not found');

      // Soft delete: set user status to INACTIVE
      await prisma.user.update({
        where: { id: student.userId },
        data: { status: 'INACTIVE' },
      });

      res.status(200).json({ success: true, message: 'Student deactivated' });
    } catch (error) {
      next(error);
    }
  }

  // ==================== TEACHERS ====================

  async getTeachers(req, res, next) {
    try {
      const teachers = await prisma.teacher.findMany({
        include: {
          user: { select: { id: true, name: true, email: true, status: true, createdAt: true } },
          department: true,
          teacherCourses: { include: { course: true } },
        },
        orderBy: { createdAt: 'desc' },
      });
      res.status(200).json({ success: true, data: teachers });
    } catch (error) {
      next(error);
    }
  }

  async createTeacher(req, res, next) {
    try {
      const { name, email, password, departmentId } = req.body;

      const existingUser = await prisma.user.findUnique({ where: { email } });
      if (existingUser) throw ApiError.conflict('Email is already registered');

      const passwordHash = await hashPassword(password);

      const result = await prisma.$transaction(async (tx) => {
        const user = await tx.user.create({
          data: { name, email, passwordHash, role: 'TEACHER', status: 'ACTIVE' },
        });

        const teacher = await tx.teacher.create({
          data: { userId: user.id, departmentId },
          include: { department: true },
        });

        await tx.auditLog.create({
          data: {
            userId: req.user.id,
            action: 'ADMIN_CREATE_TEACHER',
            details: `Created teacher ${name} (${email})`,
          },
        });

        return { user, teacher };
      });

      res.status(201).json({ success: true, message: 'Teacher created successfully', data: result });
    } catch (error) {
      next(error);
    }
  }

  async updateTeacher(req, res, next) {
    try {
      const { id } = req.params;
      const { name, departmentId, status } = req.body;

      const teacher = await prisma.teacher.findUnique({ where: { id }, include: { user: true } });
      if (!teacher) throw ApiError.notFound('Teacher not found');

      await prisma.$transaction(async (tx) => {
        if (name || status) {
          await tx.user.update({
            where: { id: teacher.userId },
            data: { ...(name && { name }), ...(status && { status }) },
          });
        }
        if (departmentId) {
          await tx.teacher.update({ where: { id }, data: { departmentId } });
        }
      });

      const updated = await prisma.teacher.findUnique({
        where: { id },
        include: { user: true, department: true },
      });

      res.status(200).json({ success: true, message: 'Teacher updated', data: updated });
    } catch (error) {
      next(error);
    }
  }

  // ==================== COURSES ====================

  async getCourses(req, res, next) {
    try {
      const courses = await prisma.course.findMany({
        include: {
          department: true,
          teacherCourses: {
            include: { teacher: { include: { user: { select: { name: true, email: true } } } } },
          },
          _count: { select: { enrollments: true, sessions: true } },
        },
        orderBy: { code: 'asc' },
      });
      res.status(200).json({ success: true, data: courses });
    } catch (error) {
      next(error);
    }
  }

  async createCourse(req, res, next) {
    try {
      const { name, code, departmentId } = req.body;
      const course = await prisma.course.create({
        data: { name, code, departmentId },
        include: { department: true },
      });
      res.status(201).json({ success: true, message: 'Course created successfully', data: course });
    } catch (error) {
      next(error);
    }
  }

  // ==================== ENROLLMENTS & ASSIGNMENTS ====================

  async enrollStudent(req, res, next) {
    try {
      const { studentId, courseId, academicYear } = req.body;
      const enrollment = await prisma.enrollment.create({
        data: { studentId, courseId, academicYear: academicYear || '2025-2026' },
        include: { student: { include: { user: true } }, course: true },
      });
      res.status(201).json({ success: true, message: 'Student enrolled successfully', data: enrollment });
    } catch (error) {
      next(error);
    }
  }

  async removeEnrollment(req, res, next) {
    try {
      const { id } = req.params;
      await prisma.enrollment.delete({ where: { id } });
      res.status(200).json({ success: true, message: 'Enrollment removed' });
    } catch (error) {
      next(error);
    }
  }

  async assignTeacher(req, res, next) {
    try {
      const { teacherId, courseId } = req.body;
      const assignment = await prisma.teacherCourse.create({
        data: { teacherId, courseId },
        include: { teacher: { include: { user: true } }, course: true },
      });
      res.status(201).json({ success: true, message: 'Teacher assigned to course', data: assignment });
    } catch (error) {
      next(error);
    }
  }

  async removeTeacherAssignment(req, res, next) {
    try {
      const { teacherId, courseId } = req.params;
      await prisma.teacherCourse.delete({
        where: { teacherId_courseId: { teacherId, courseId } },
      });
      res.status(200).json({ success: true, message: 'Teacher removed from course' });
    } catch (error) {
      next(error);
    }
  }

  // ==================== AUDIT LOGS ====================

  async getAuditLogs(req, res, next) {
    try {
      const logs = await prisma.auditLog.findMany({
        take: 100,
        orderBy: { timestamp: 'desc' },
        include: { user: { select: { name: true, email: true, role: true } } },
      });
      res.status(200).json({ success: true, data: logs });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AdminController();
