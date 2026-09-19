const prisma = require('../config/db');
const { hashPassword, comparePassword } = require('../utils/hash');
const { generateAccessToken, generateRefreshToken, verifyRefreshToken } = require('../utils/jwt');
const ApiError = require('../utils/apiError');

class AuthService {
  async register(data) {
    const { name, email, password, enrollmentNumber, departmentId, semester, section } = data;

    // Check if email already registered
    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      throw ApiError.conflict('Email address is already registered');
    }

    // Check if enrollment number already exists
    const existingEnrollment = await prisma.student.findUnique({
      where: { enrollmentNumber },
    });
    if (existingEnrollment) {
      throw ApiError.conflict('Enrollment number is already in use');
    }

    // Check if department exists
    const department = await prisma.department.findUnique({
      where: { id: departmentId },
    });
    if (!department) {
      throw ApiError.notFound('Department not found');
    }

    const passwordHash = await hashPassword(password);

    // Create user and student profile in a transaction
    const result = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          name,
          email,
          passwordHash,
          role: 'STUDENT',
          status: 'ACTIVE',
        },
      });

      const student = await tx.student.create({
        data: {
          userId: user.id,
          enrollmentNumber,
          departmentId,
          semester: semester || 1,
          section: section || 'A',
        },
        include: {
          department: true,
        },
      });

      await tx.auditLog.create({
        data: {
          userId: user.id,
          action: 'USER_REGISTER',
          details: `Student registered: ${name} (${enrollmentNumber})`,
        },
      });

      return { user, student };
    });

    const tokens = {
      accessToken: generateAccessToken({
        id: result.user.id,
        name: result.user.name,
        email: result.user.email,
        role: result.user.role,
        studentId: result.student.id,
      }),
      refreshToken: generateRefreshToken({
        id: result.user.id,
        email: result.user.email,
        role: result.user.role,
      }),
    };

    return {
      user: {
        id: result.user.id,
        name: result.user.name,
        email: result.user.email,
        role: result.user.role,
        student: result.student,
      },
      tokens,
    };
  }

  async login(email, password) {
    const user = await prisma.user.findUnique({
      where: { email },
      include: {
        student: {
          include: { department: true },
        },
        teacher: {
          include: { department: true },
        },
      },
    });

    if (!user) {
      throw ApiError.unauthorized('Invalid email or password');
    }

    if (user.status !== 'ACTIVE') {
      throw ApiError.forbidden('Your account is currently inactive. Please contact admin.');
    }

    const isMatch = await comparePassword(password, user.passwordHash);
    if (!isMatch) {
      throw ApiError.unauthorized('Invalid email or password');
    }

    const payload = {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      studentId: user.student?.id || null,
      teacherId: user.teacher?.id || null,
    };

    const tokens = {
      accessToken: generateAccessToken(payload),
      refreshToken: generateRefreshToken(payload),
    };

    // Log login action
    await prisma.auditLog.create({
      data: {
        userId: user.id,
        action: 'USER_LOGIN',
        details: `Successful login by ${user.role}: ${user.email}`,
      },
    });

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        student: user.student,
        teacher: user.teacher,
      },
      tokens,
    };
  }

  async refreshToken(token) {
    const decoded = verifyRefreshToken(token);
    if (!decoded) {
      throw ApiError.unauthorized('Invalid or expired refresh token');
    }

    const user = await prisma.user.findUnique({
      where: { id: decoded.id },
      include: {
        student: true,
        teacher: true,
      },
    });

    if (!user || user.status !== 'ACTIVE') {
      throw ApiError.unauthorized('User not found or inactive');
    }

    const payload = {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      studentId: user.student?.id || null,
      teacherId: user.teacher?.id || null,
    };

    return {
      accessToken: generateAccessToken(payload),
      refreshToken: generateRefreshToken(payload),
    };
  }

  async getMe(userId) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        status: true,
        createdAt: true,
        student: {
          include: {
            department: true,
            enrollments: {
              include: { course: true },
            },
          },
        },
        teacher: {
          include: {
            department: true,
            teacherCourses: {
              include: { course: true },
            },
          },
        },
      },
    });

    if (!user) {
      throw ApiError.notFound('User not found');
    }

    return user;
  }
}

module.exports = new AuthService();
