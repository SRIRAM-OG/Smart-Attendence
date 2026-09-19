const ApiError = require('../utils/apiError');

/**
 * Joi Schema Validation Middleware
 * @param {import('joi').ObjectSchema} schema
 * @param {'body' | 'query' | 'params'} source
 */
const validate = (schema, source = 'body') => {
  return (req, res, next) => {
    const { error, value } = schema.validate(req[source], {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      const errorMessage = error.details
        .map((detail) => detail.message.replace(/['"]/g, ''))
        .join(', ');
      return next(ApiError.badRequest(errorMessage));
    }

    req[source] = value;
    next();
  };
};

module.exports = validate;
