const { verifyAccessToken } = require('../utils/jwt');
const ApiError = require('../utils/apiError');
const prisma = require('../config/db');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(ApiError.unauthorized('No authentication token provided'));
    }

    const token = authHeader.split(' ')[1];
    const decoded = verifyAccessToken(token);

    if (!decoded) {
      return next(ApiError.unauthorized('Invalid or expired authentication token'));
    }

    // Verify user exists and is active
    const user = await prisma.user.findUnique({
      where: { id: decoded.id },
      include: {
        student: true,
        teacher: true,
      },
    });

    if (!user) {
      return next(ApiError.unauthorized('User not found'));
    }

    if (user.status !== 'ACTIVE') {
      return next(ApiError.forbidden('User account is inactive'));
    }

    req.user = {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      status: user.status,
      studentId: user.student?.id || null,
      teacherId: user.teacher?.id || null,
      student: user.student,
      teacher: user.teacher,
    };

    next();
  } catch (error) {
    next(error);
  }
};

module.exports = authenticate;
