const ApiError = require('../utils/apiError');

// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  let { statusCode, message } = err;

  if (!(err instanceof ApiError)) {
    statusCode = err.statusCode || 500;
    message = err.message || 'Internal Server Error';
  }

  // Handle Prisma unique constraint error
  if (err.code === 'P2002') {
    statusCode = 409;
    const target = err.meta?.target ? ` (${err.meta.target})` : '';
    message = `A record with this unique field already exists${target}.`;
  }

  // Handle Prisma record not found
  if (err.code === 'P2025') {
    statusCode = 404;
    message = 'Requested record not found.';
  }

  const response = {
    success: false,
    statusCode,
    message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  };

  res.status(statusCode).json(response);
};

module.exports = errorHandler;
