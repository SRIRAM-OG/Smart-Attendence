const prisma = require('../config/db');
const qrService = require('./qr.service');
const ApiError = require('../utils/apiError');

class AttendanceService {
  /**
   * Teacher creates a new attendance session for a course
   */
  async createSession(teacherId, data) {
    const { courseId, sessionDate, startTime, expiryMinutes = 5 } = data;

    // Verify course is assigned to this teacher
    const assignment = await prisma.teacherCourse.findUnique({
      where: {
        teacherId_courseId: {
          teacherId,
          courseId,
        },
      },
    });

    if (!assignment) {
      throw ApiError.forbidden('You are not assigned to teach this course');
    }

    // Create session in database
    const session = await prisma.attendanceSession.create({
      data: {
        courseId,
        teacherId,
        sessionDate: sessionDate ? new Date(sessionDate) : new Date(),
        startTime: startTime ? new Date(startTime) : new Date(),
        status: 'ACTIVE',
      },
      include: {
        course: true,
        teacher: {
          include: { user: { select: { name: true, email: true } } },
        },
      },
    });

    // Auto-generate QR code for this session
    const qrData = qrService.generateQrToken(session.id, expiryMinutes);

    const updatedSession = await prisma.attendanceSession.update({
      where: { id: session.id },
      data: {
        qrToken: qrData.token,
        qrExpiresAt: qrData.expiresAt,
      },
      include: {
        course: true,
        teacher: {
          include: { user: { select: { name: true, email: true } } },
        },
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: session.teacher.userId,
        action: 'ATTENDANCE_SESSION_CREATED',
        details: `Session created for course ${session.course.code} (${session.course.name})`,
      },
    });

    return {
      session: updatedSession,
      qrPayload: qrData.payload,
      expiresAt: qrData.expiresAt,
    };
  }

  /**
   * Teacher generates/regenerates QR token for an active session
   */
  async generateSessionQr(teacherId, sessionId, expiryMinutes = 5) {
    const session = await prisma.attendanceSession.findUnique({
      where: { id: sessionId },
      include: { course: true, teacher: true },
    });

    if (!session) {
      throw ApiError.notFound('Attendance session not found');
    }

    if (session.teacherId !== teacherId) {
      throw ApiError.forbidden('You do not own this attendance session');
    }

    if (session.status === 'CLOSED') {
      throw ApiError.badRequest('Cannot generate QR code for a closed session');
    }

    const qrData = qrService.generateQrToken(session.id, expiryMinutes);

    const updatedSession = await prisma.attendanceSession.update({
      where: { id: session.id },
      data: {
        qrToken: qrData.token,
        qrExpiresAt: qrData.expiresAt,
        status: 'ACTIVE',
      },
      include: {
        course: true,
      },
    });

    return {
      session: updatedSession,
      qrPayload: qrData.payload,
      expiresAt: qrData.expiresAt,
    };
  }

  /**
   * Student scans QR and records attendance (Strict validations)
   */
  async scanAttendance(studentId, userId, { sessionId, token, authMethod = 'QR_SCAN' }) {
    // 1. Check student exists and is active
    const student = await prisma.student.findUnique({
      where: { id: studentId },
      include: { user: true },
    });

    if (!student || student.user.status !== 'ACTIVE') {
      throw ApiError.forbidden('Student account is not active');
    }

    // 2. Fetch session
    const session = await prisma.attendanceSession.findUnique({
      where: { id: sessionId },
      include: {
        course: true,
      },
    });

    if (!session) {
      throw ApiError.notFound('Attendance session does not exist or has been removed');
    }

    // 3. Verify session is currently ACTIVE
    if (session.status !== 'ACTIVE') {
      throw ApiError.badRequest(`Attendance session is ${session.status.toLowerCase()}`);
    }

    // 4. Verify QR token matches session stored token
    if (session.qrToken !== token) {
      throw ApiError.badRequest('Invalid QR code token');
    }

    // 5. Verify QR code has not expired
    const now = new Date();
    if (!session.qrExpiresAt || now > new Date(session.qrExpiresAt)) {
      // Mark session as EXPIRED if past expiry
      await prisma.attendanceSession.update({
        where: { id: session.id },
        data: { status: 'EXPIRED' },
      });
      throw ApiError.badRequest('This attendance QR code has expired. Please ask your teacher to regenerate it.');
    }

    // Cryptographic signature check
    const isSignatureValid = qrService.validateQrToken(session.id, token, session.qrExpiresAt);
    if (!isSignatureValid) {
      throw ApiError.badRequest('QR code signature verification failed');
    }

    // 6. Verify student is enrolled in the course
    const enrollment = await prisma.enrollment.findFirst({
      where: {
        studentId,
        courseId: session.courseId,
      },
    });

    if (!enrollment) {
      throw ApiError.forbidden(
        `You are not enrolled in ${session.course.code} - ${session.course.name}. Attendance cannot be marked.`
      );
    }

    // 7. Prevent duplicate attendance (Unique constraint + explicit check)
    const existingRecord = await prisma.attendanceRecord.findUnique({
      where: {
        sessionId_studentId: {
          sessionId,
          studentId,
        },
      },
    });

    if (existingRecord) {
      throw ApiError.conflict(
        `Attendance already recorded for this session at ${existingRecord.timestamp.toLocaleTimeString()}`
      );
    }

    // 8. Record attendance
    const record = await prisma.attendanceRecord.create({
      data: {
        sessionId,
        studentId,
        status: 'PRESENT',
        authMethod,
        timestamp: new Date(),
      },
      include: {
        student: {
          include: {
            user: { select: { name: true, email: true } },
          },
        },
        session: {
          include: { course: true },
        },
      },
    });

    // 9. Audit log
    await prisma.auditLog.create({
      data: {
        userId,
        action: 'ATTENDANCE_MARKED',
        details: `Student ${student.enrollmentNumber} marked PRESENT in ${session.course.code}`,
      },
    });

    return {
      message: 'Attendance marked successfully!',
      record: {
        id: record.id,
        courseCode: session.course.code,
        courseName: session.course.name,
        timestamp: record.timestamp,
        status: record.status,
      },
    };
  }

  /**
   * Get all attendance records for a specific session
   */
  async getSessionRecords(sessionId, teacherId) {
    const session = await prisma.attendanceSession.findUnique({
      where: { id: sessionId },
      include: {
        course: true,
        teacher: { include: { user: true } },
      },
    });

    if (!session) {
      throw ApiError.notFound('Session not found');
    }

    // Count enrolled students
    const totalEnrolled = await prisma.enrollment.count({
      where: { courseId: session.courseId },
    });

    // Records marked present
    const records = await prisma.attendanceRecord.findMany({
      where: { sessionId },
      include: {
        student: {
          include: {
            user: { select: { name: true, email: true } },
            department: true,
          },
        },
      },
      orderBy: { timestamp: 'asc' },
    });

    return {
      session,
      totalEnrolled,
      totalPresent: records.length,
      attendancePercentage: totalEnrolled > 0 ? ((records.length / totalEnrolled) * 100).toFixed(2) : 0,
      records,
    };
  }

  /**
   * Teacher closes an active attendance session
   */
  async closeSession(sessionId, teacherId) {
    const session = await prisma.attendanceSession.findUnique({
      where: { id: sessionId },
      include: { course: true, teacher: true },
    });

    if (!session) {
      throw ApiError.notFound('Session not found');
    }

    if (session.teacherId !== teacherId) {
      throw ApiError.forbidden('You do not own this session');
    }

    const updated = await prisma.attendanceSession.update({
      where: { id: sessionId },
      data: {
        status: 'CLOSED',
        endTime: new Date(),
      },
    });

    await prisma.auditLog.create({
      data: {
        userId: session.teacher.userId,
        action: 'ATTENDANCE_SESSION_CLOSED',
        details: `Closed session for course ${session.course.code}`,
      },
    });

    return updated;
  }

  /**
   * Student views their attendance history
   */
  async getStudentHistory(studentId, courseId = null) {
    const where = { studentId };
    if (courseId) {
      where.session = { courseId };
    }

    const records = await prisma.attendanceRecord.findMany({
      where,
      include: {
        session: {
          include: {
            course: true,
            teacher: { include: { user: { select: { name: true } } } },
          },
        },
      },
      orderBy: { timestamp: 'desc' },
    });

    return records;
  }

  /**
   * Student views calculated attendance percentage across all enrolled courses
   */
  async getStudentPercentage(studentId) {
    // 1. Get all enrollments for student
    const enrollments = await prisma.enrollment.findMany({
      where: { studentId },
      include: { course: true },
    });

    let totalConductedAll = 0;
    let totalAttendedAll = 0;

    const courseBreakdown = await Promise.all(
      enrollments.map(async (enrollment) => {
        // Total sessions conducted for this course
        const totalSessions = await prisma.attendanceSession.count({
          where: {
            courseId: enrollment.courseId,
            status: { in: ['ACTIVE', 'EXPIRED', 'CLOSED'] },
          },
        });

        // Sessions attended by this student
        const attendedSessions = await prisma.attendanceRecord.count({
          where: {
            studentId,
            status: 'PRESENT',
            session: { courseId: enrollment.courseId },
          },
        });

        totalConductedAll += totalSessions;
        totalAttendedAll += attendedSessions;

        const percentage = totalSessions > 0 ? Number(((attendedSessions / totalSessions) * 100).toFixed(2)) : 100;

        return {
          courseId: enrollment.course.id,
          courseCode: enrollment.course.code,
          courseName: enrollment.course.name,
          attendedSessions,
          totalSessions,
          percentage,
          isLowAttendance: percentage < 75,
        };
      })
    );

    const overallPercentage =
      totalConductedAll > 0 ? Number(((totalAttendedAll / totalConductedAll) * 100).toFixed(2)) : 100;

    return {
      overallPercentage,
      totalAttended: totalAttendedAll,
      totalEligible: totalConductedAll,
      isLowAttendance: overallPercentage < 75,
      courses: courseBreakdown,
    };
  }

  /**
   * Admin / Teacher updates an attendance record manually (TC / Exception handling)
   */
  async updateRecord(recordId, status, userId) {
    const record = await prisma.attendanceRecord.update({
      where: { id: recordId },
      data: { status },
      include: {
        student: { include: { user: true } },
        session: { include: { course: true } },
      },
    });

    await prisma.auditLog.create({
      data: {
        userId,
        action: 'ATTENDANCE_CORRECTION',
        details: `Updated record ${recordId} to status ${status} for student ${record.student.enrollmentNumber}`,
      },
    });

    return record;
  }
}

module.exports = new AttendanceService();
