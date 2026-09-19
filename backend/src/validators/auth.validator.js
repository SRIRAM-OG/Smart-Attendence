const Joi = require('joi');

const registerSchema = Joi.object({
  name: Joi.string().trim().min(2).max(100).required(),
  email: Joi.string().email().trim().lowercase().required(),
  password: Joi.string().min(6).max(128).required(),
  enrollmentNumber: Joi.string().trim().required(),
  departmentId: Joi.string().uuid().required(),
  semester: Joi.number().integer().min(1).max(12).default(1),
  section: Joi.string().trim().max(10).default('A'),
});

const loginSchema = Joi.object({
  email: Joi.string().email().trim().lowercase().required(),
  password: Joi.string().required(),
});

const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required(),
});

module.exports = {
  registerSchema,
  loginSchema,
  refreshTokenSchema,
};
