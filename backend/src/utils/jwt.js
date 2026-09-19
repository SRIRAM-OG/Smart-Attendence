const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'smart_attendance_secret_access_2026';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'smart_attendance_secret_refresh_2026';
const ACCESS_EXPIRY = process.env.JWT_ACCESS_EXPIRATION || '15m';
const REFRESH_EXPIRY = process.env.JWT_REFRESH_EXPIRATION || '7d';

const generateAccessToken = (payload) => {
  return jwt.sign(
    {
      id: payload.id,
      email: payload.email,
      role: payload.role,
      name: payload.name,
      studentId: payload.student?.id || payload.studentId || null,
      teacherId: payload.teacher?.id || payload.teacherId || null,
    },
    JWT_SECRET,
    { expiresIn: ACCESS_EXPIRY }
  );
};

const generateRefreshToken = (payload) => {
  return jwt.sign(
    {
      id: payload.id,
      email: payload.email,
      role: payload.role,
    },
    JWT_REFRESH_SECRET,
    { expiresIn: REFRESH_EXPIRY }
  );
};

const verifyAccessToken = (token) => {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (err) {
    return null;
  }
};

const verifyRefreshToken = (token) => {
  try {
    return jwt.verify(token, JWT_REFRESH_SECRET);
  } catch (err) {
    return null;
  }
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
};
