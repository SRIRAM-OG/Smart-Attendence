const ApiError = require('../utils/apiError');

/**
 * Role-Based Access Control Middleware
 * @param  {...string} allowedRoles - e.g. 'ADMIN', 'TEACHER', 'STUDENT'
 */
const authorize = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return next(ApiError.unauthorized('Authentication required'));
    }

    if (!allowedRoles.includes(req.user.role)) {
      return next(
        ApiError.forbidden(
          `Access denied. Allowed roles: ${allowedRoles.join(', ')}. Your role: ${req.user.role}`
        )
      );
    }

    next();
  };
};

module.exports = authorize;
